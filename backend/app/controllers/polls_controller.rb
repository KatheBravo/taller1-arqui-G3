class PollsController < ApplicationController
  # GET /polls o GET /polls/1
  def show
    poll_id = params[:id] || "1"
    use_case = Core::UseCases::GetPollResults.new
    results = use_case.execute(poll_id: poll_id)

    render json: results
  end

  # GET /polls
  def index
    poll_id = "1"
    use_case = Core::UseCases::GetPollResults.new
    results = use_case.execute(poll_id: poll_id)

    render json: results
  end

  # POST /polls/:id/vote (Fallback HTTP REST)
  def vote
    poll_id = params[:id]
    option_id = params[:option_id]
    voter_fingerprint = params[:fingerprint] || request.remote_ip

    use_case = Core::UseCases::RegisterVote.new
    result = use_case.execute(
      poll_id: poll_id,
      option_id: option_id,
      voter_fingerprint: voter_fingerprint
    )

    render json: result
  end

  # POST /polls/:id/reset
  def reset
    poll_id = params[:id]
    repository = Infrastructure::Repositories::RedisVoteRepository.new
    results = repository.reset_poll(poll_id)

    # Notificar via WebSocket
    payload = {
      event: "results_updated",
      poll_id: poll_id.to_s,
      totals: results[:totals],
      percentages: results[:percentages],
      total_votes: results[:total_votes],
      timestamp: Time.now.utc.iso8601
    }
    ActionCable.server.broadcast("voting_session", payload)

    render json: { success: true, message: "Votacion reiniciada.", data: payload }
  end
end
