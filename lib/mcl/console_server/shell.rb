module Mcl
  class ConsoleServer
    class Shell
      attr_reader :session, :server, :app

      def initialize(session)
        @session = session
        @server = @session.server
        @app = @server.app
      end

      alias_method :oputs, :puts
      def puts *a
        session.cputs(*a)
      end
      alias_method :echo, :puts

      alias_method :oprint, :print
      def print *a
        session.cprint(*a)
      end

      def input str
        if str.strip == "exit"
          session.terminate("client quit")
        else
          oputs ": #{str}"
          session.cputs ": #{str}"
        end
      end

      # =======
      # = API =
      # =======
      def hello
        puts "Welcome!"
      end

      def goodbye reason = "no apparent reason"
        puts "!!!!!!!!!!!!!!...."
        puts "!!! ConsoleServer says bye, bye..."
        puts "!!! Reason: #{reason}"
        puts "!!!!!!!!!!!!!!...."
      end
    end
  end
end
