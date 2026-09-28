module Core
  module UseCases
    class GetPollResults
      def initialize(repository: Infrastructure::Repositories::RedisVoteRepository.new)
        @repository = repository
      end

      def execute(poll_id:)
        poll = @repository.find_poll(poll_id)
        unless poll
          raise Core::Errors::PollNotFoundError, "La votacion con ID #{poll_id} no existe."
        end

        @repository.get_poll_results(poll_id)
      end
    end
  end
end
