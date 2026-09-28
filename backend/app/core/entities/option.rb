module Core
  module Entities
    class Option
      attr_reader :id, :poll_id, :text, :current_votes

      def initialize(id:, poll_id:, text:, current_votes: 0)
        @id = id.to_s
        @poll_id = poll_id.to_s
        @text = text.to_s
        @current_votes = current_votes.to_i
      end

      def to_h
        {
          id: @id,
          poll_id: @poll_id,
          text: @text,
          current_votes: @current_votes
        }
      end
    end
  end
end
