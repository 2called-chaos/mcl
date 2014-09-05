module Mcl
  class Handler
    module API
      def setup
        # called on creation
      end

      def init
        # called when all handlers have went through their setup
      end

      def tick!
        # called on every tick (should be fast)
      end
    end
  end
end
