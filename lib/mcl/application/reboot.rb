module Mcl
  class Application
    class Reboot < Halt
      attr_reader :message

      def initialize message
        @message = message
      end
    end
  end
end
