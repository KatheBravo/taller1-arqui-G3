module Core
  module Entities
    class Vote
      attr_reader :id, :poll_id, :option_id, :voter_fingerprint, :cast_at

      def initialize(id:, poll_id:, option_id:, voter_fingerprint:, cast_at: nil)
        @id = id.to_s
        @poll_id = poll_id.to_s
        @option_id = option_id.to_s
        @voter_fingerprint = voter_fingerprint.to_s
        @cast_at = cast_at || Time.now.utc.iso8601
      end

      def to_h
        {
          id: @id,
          poll_id: @poll_id,
          option_id: @option_id,
          voter_fingerprint: @voter_fingerprint,
          cast_at: @cast_at
        }
      end
    end
  end
end
