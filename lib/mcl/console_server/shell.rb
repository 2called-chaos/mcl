module Mcl
  class ConsoleServer
    class Shell
      attr_reader :session, :server, :app
      attr_accessor :colorize
      include Colorize
      include Commands
      PROTOCOL_VERSION = "1"

      def initialize(session)
        @session = session
        @server = @session.server
        @app = @server.app
        @colorize = true
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

      def protocol msg
        puts "\0@PROTOCOL@#{PROTOCOL_VERSION}##{msg}"
      end

      def critical &block
        session.critical(&block)
      end

      def sync &block
        session.lock.synchronize(&block)
      end

      def commands
        methods.grep(/^_cmd/).map(&:to_s).map{|s| s.gsub(/^_cmd_/, '') }
      end

      # handle user input message
      def input str
        str = str.chomp
        app.devlog "[ConsoleServer] #{session.client_id} invoked `#{str}'", scope: "console_server"

        if str.start_with?("\0") # Protocol
          _handle_protocol(str)
        elsif str.strip.empty?
          # no input => discard
        elsif str.start_with?("!") # MCL command
          _invoke_mcl(str)
        elsif str.start_with?("/") # MC command
          _invoke_mc(str)
        elsif str.start_with?(".") # say shortcut
          _cmd_say(str)
        else # lookup command
          chunks = str.split(" ")
          if respond_to?("_cmd_#{chunks[0]}")
            var = catch(:terminate_session) do
              critical{ send("_cmd_#{chunks[0]}", str, chunks[1..-1]) }
              nil
            end
            session.terminate(var) if var
          else
            puts c("! Unknown command `#{chunks[0]}', type `commands' to get a list.", :red)
          end
        end
      rescue
        puts c("#{$!.class}: #{$!.message}", :red)
        puts c("#{$@.first}", :red)
        app.log.warn "[ConsoleServer] #{session.client_id} - failed to handle `#{str}' (#{$!.class}: #{$!.message})"
      end

      def banner
        puts c("##############################################################", :cyan)
        puts c("#                                                            #", :cyan)
        puts c("#  ", :cyan) << c(%q%,--.   ,--. ,-----.,--.     %, :yellow) << c(session.client_id.rjust(28, " "), :magenta)     << c("  #", :cyan)
        puts c("#  ", :cyan) << c(%q%|   `.'   |'  .--./|  |     %, :yellow) << c(%q%                      .     %, :red) << c("  #", :cyan)
        puts c("#  ", :cyan) << c(%q%|  |'.'|  ||  |    |  |     %, :yellow) << c(%q%  ,-. ,-. ,-. ,-. ,-. |  ,-.%, :red) << c("  #", :cyan)
        puts c("#  ", :cyan) << c(%q%|  |   |  |'  '--'\|  '--.  %, :yellow) << c(%q%  |   | | | | `-. | | |  |-'%, :red) << c("  #", :cyan)
        puts c("#  ", :cyan) << c(%q%`--'   `--' `-----'`-----'  %, :yellow) << c(%q%  `-' `-' ' ' `-' `-' `' `-'%, :red) << c("  #", :cyan)
        puts c("#                                                            #", :cyan)
        puts c("#  ", :cyan) << c("type ") << c("commands", :magenta) << c(" or ") << c("help", :magenta) << c(" to get started, type ") << c("exit", :magenta) << c(" to quit.") << c("  #", :cyan)
        puts c("#                                                            #", :cyan)
        puts c("##############################################################", :cyan)
      end

      # =======
      # = API =
      # =======
      def hello
        banner
        protocol "srv_req_env_from_client=#{@app.instance}"
      end

      def goodbye reason = "no apparent reason"
        puts c("!!!!!!!!!!!!!!....", :red)
        puts c("!!! ConsoleServer says bye, bye...", :red)
        puts c("!!! Reason: #{reason}", :red)
        puts c("!!!!!!!!!!!!!!....", :red)
      end
    end
  end
end
