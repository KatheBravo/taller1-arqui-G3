class VotingChannel < ApplicationCable::Channel
  def subscribed
    stream_from "voting_session"
    stream_from "voting_session_#{params[:poll_id]}" if params[:poll_id].present?

    # Al conectarse, enviar inmediatamente el estado actual de la sesion al cliente
    poll_id = params[:poll_id] || "1"
    repository = Infrastructure::Repositories::RedisVoteRepository.new
    results = repository.get_poll_results(poll_id)

    if results
      transmit({
        event: "session_state",
        data: results
      })
    end
  rescue StandardError => e
    Rails.logger.error("[VotingChannel] Error en subscribed: #{e.message}")
  end

  def unsubscribed
    # Limpieza al desconectarse el socket si fuese necesaria
  end

  # Accion invocada por el cliente Python cuando el usuario vota
  def cast_vote(data)
    poll_id = data["poll_id"] || "1"
    option_id = data["option_id"]
    fingerprint = data["fingerprint"] || "anon_#{SecureRandom.hex(4)}"

    use_case = Core::UseCases::RegisterVote.new

    begin
      result = use_case.execute(
        poll_id: poll_id,
        option_id: option_id,
        voter_fingerprint: fingerprint
      )

      # Confirmacion directa al votante
      transmit({
        event: "vote_accepted",
        message: result[:message],
        data: result[:data]
      })
    rescue Core::Errors::DomainError => e
      transmit({
        event: "vote_error",
        error_type: e.class.name.demodulize,
        message: e.message
      })
    rescue StandardError => e
      transmit({
        event: "vote_error",
        error_type: "SystemError",
        message: "Ocurrio un error interno al procesar el voto: #{e.message}"
      })
    end
  end

  # Accion para solicitar el estado actual
  def request_status(data)
    poll_id = data["poll_id"] || "1"
    repository = Infrastructure::Repositories::RedisVoteRepository.new
    results = repository.get_poll_results(poll_id)

    transmit({
      event: "current_status",
      data: results
    })
  rescue StandardError => e
    Rails.logger.error("[VotingChannel] Error en request_status: #{e.message}")
  end

  # Accion para reiniciar la sesion de votacion (util para pruebas y demostraciones en vivo)
  def reset_poll(data)
    poll_id = data["poll_id"] || "1"
    repository = Infrastructure::Repositories::RedisVoteRepository.new
    updated = repository.reset_poll(poll_id)

    payload = {
      event: "results_updated",
      poll_id: poll_id.to_s,
      totals: updated[:totals],
      percentages: updated[:percentages],
      total_votes: updated[:total_votes],
      timestamp: Time.now.utc.iso8601
    }

    ActionCable.server.broadcast("voting_session", payload)
  end
end
