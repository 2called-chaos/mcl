module Mcl
  class ConsoleServer
    class Log
      def initialize server
        @server = server
      end

      [:write, :puts, :warn, :info, :error, :fatal, :add, :debug].each do |meth|
        define_method(meth) do |*args|
          args.each {|a| @server.push_mlog(a) }
        end
      end

      def level= lvl

      end

      def close
        # sure
      end
    end
  end
end

