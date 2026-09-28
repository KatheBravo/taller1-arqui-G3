module Core
  module Errors
    class DomainError < StandardError; end
    class PollNotFoundError < DomainError; end
    class PollClosedError < DomainError; end
    class InvalidOptionError < DomainError; end
    class DuplicateVoteError < DomainError; end
  end
end
