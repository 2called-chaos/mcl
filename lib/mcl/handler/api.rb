module Mcl
  class Handler
    module API
      def setup
        # called on creation
      end

      def init
        # called when all handlers have went through their setup
      end

      def srvrdy
        # called when server signals readyness (might not fire if you use a custom server)
      end

      def tick!
        # called on every tick (should be fast)
      end
    end
  end
end
