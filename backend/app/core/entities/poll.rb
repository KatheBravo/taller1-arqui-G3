module Core
  module Entities
    class Poll
      attr_reader :id, :title, :description, :status, :created_at

      def initialize(id:, title:, description:, status: "open", created_at: nil)
        @id = id.to_s
        @title = title.to_s
        @description = description.to_s
        @status = status.to_s
        @created_at = created_at || Time.now.utc.iso8601
      end

      def open?
        @status == "open"
      end

      def closed?
        @status == "closed"
      end

      def to_h
        {
          id: @id,
          title: @title,
          description: @description,
          status: @status,
          created_at: @created_at
        }
      end
    end
  end
end
