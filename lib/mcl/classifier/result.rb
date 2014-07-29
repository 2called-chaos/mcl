module Mcl
  class Classifier
    class Result
      attr_accessor :line, :type, :subtype, :thread, :channel, :origin_type, :origin, :data, :command, :date, :append, :classified

      def initialize(line = nil)
        @line = line
        @classified = false
        @type = :unknown
      end

      def classified?
        @classified
      end

      def append?
        @append
      end

      def command?
        @command
      end

      def command
        !!@command
      end
    end
  end
end
