module Core
  module UseCases
    class RegisterVote
      def initialize(repository: Infrastructure::Repositories::RedisVoteRepository.new, broadcaster: ActionCable.server)
        @repository = repository
        @broadcaster = broadcaster
      end

      def execute(poll_id:, option_id:, voter_fingerprint:)
        # 1. Regla de Negocio: Validar que la votacion exista
        poll = @repository.find_poll(poll_id)
        unless poll
          raise Core::Errors::PollNotFoundError, "La votacion con ID #{poll_id} no existe."
        end

        # 2. Regla de Negocio: Validar que la sesion siga abierta
        unless poll.open?
          raise Core::Errors::PollClosedError, "La votacion '#{poll.title}' se encuentra cerrada."
        end

        # 3. Regla de Negocio: Validar que la opcion exista
        options = @repository.find_options(poll_id)
        valid_option = options.any? { |opt| opt.id == option_id.to_s }
        unless valid_option
          raise Core::Errors::InvalidOptionError, "La opcion '#{option_id}' no pertenece a esta votacion."
        end

        # 4. Persistir el voto en el repositorio (verificando unicidad atomica en Redis)
        results = @repository.record_vote(
          poll_id: poll_id,
          option_id: option_id,
          voter_fingerprint: voter_fingerprint
        )

        # 5. Broadcast de evento en tiempo real hacia todos los clientes WebSocket
        broadcast_payload = {
          event: "results_updated",
          poll_id: poll_id.to_s,
          totals: results[:totals],
          percentages: results[:percentages],
          total_votes: results[:total_votes],
          timestamp: Time.now.utc.iso8601
        }

        # Transmitir a ActionCable
        @broadcaster.broadcast("voting_session", broadcast_payload)
        @broadcaster.broadcast("voting_session_#{poll_id}", broadcast_payload)

        {
          success: true,
          message: "Voto registrado correctamente.",
          data: broadcast_payload
        }
      end
    end
  end
end
