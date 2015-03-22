module Mcl
  class ConsoleServer
    module Commands
      def _invoke_mcl str
      end

      def _invoke_mc str
        $mcl.sync { $mcl.server.invoke(str) }
      end

      def _cmd_say line, args = nil
        _invoke_mc %{/say #{line[1..-1]}}
      end

      # ---

      def _cmd_sessions line, args
        puts c("There are ") << c("#{server.sessions.count}", :magenta) << c(" open sessions:")
        table = [[], [], [], []]
        server.sessions.each_with_index do |sess, index|
          table[0] << "#{index}"
          table[1] << "#{sess.client_id}"
          table[2] << "#{sess.client_app}"
          table[3] << "#{sess.connected}"
        end

        puts *render_table(table, ["#", "client_id", "app", "connected"])
      end

      def _cmd_broadcast line, args
        server.sessions.each do |sess|
          sess.cputs c("[BC-#{sess.client_id}] ", :magenta) << c("#{args.join(" ")}")
        end
      end

      def _cmd_nick line, args
        if args[0].present?
          push_env("nick" => args.join(" ").presence)
        else
          if session.nick.present?
            puts c("Your current nickname is ") << c("#{session.nick}", :cyan)
          else
            puts c("You haven't set a nickname yet!")
          end
          puts c("Use ") << c("nick [nickname]", :magenta) << c(" to change your nickname.")
        end
      end

      def _cmd_msg line, args
        if args.any? && args[0] =~ /\A\d+\z/
          sess = server.sessions[args.shift.to_i]
          if sess
            sess.shell.puts c("[#{sess.client_id}] ", :magenta) << c("#{args.join(" ")}")
          else
            puts c("Invalid session id provided", :red)
          end
        else
          puts c("Usage: msg <sid> <message>", :red)
        end
      end

      def _cmd_commands line, args
        puts "Available commands: " << commands.join(", ")
      end

      def _cmd_env line, args
        puts c("Your current environment is:", :cyan)
        puts *JSON.pretty_generate(@env).split("\n").map{|s| c(s) }
      end

      def _cmd_exit line, args
        throw(:terminate_session, "client quit")
      end
      alias_method :_cmd_quit, :_cmd_exit

      def _cmd_moep line, args
        15.times {|n| `say #{n}` ; sleep 0.5 ; break if session.halting }
      end

      def _cmd_log line, args, meth = :log
        # options
        mkey = meth == :log ? "livelog" : "livemlog"
        opts = { lines: nil, grep: [], types: [], filter: false }
        opt = OptionParser.new
        opt.banner = c("Usage: log [opts] [args…]", :cyan)
        opt.separator "    <#{c "on", :cyan}/#{c "off", :cyan}>\t\t\t     turn live logging on or off (when turning on you can combine -f -t -n -g)"
        opt.separator "    <#{c "N", :cyan}>\t\t\t\tshortcut for #{c "-n N", :cyan}"
        opt.on("-h", "--help", "shows this help") { return puts opt.to_s }
        opt.on("-n", "--lines N", Integer, "Amount of lines to show/consider") {|n| opts[:lines] = n }
        opt.on("-g", "--grep REGEX", String, "grep/search backlog with regular expression", "can be used multiple times", "(can be combined with -n which is 1000 by default)"){|r| opts[:grep] << /#{r}/i ; opts[:lines] ||= 1000 }
        opt.on("-f", "--filter", "apply filters (to use like `log 100 -f`)") { opts[:filter] = true }
        opt.on("-l", "--list-filters", "list all filters") do
          puts c("not implemented yet :(", :red)
          return
        end
        opt.on("-a", "--add-filter REGEX", String, "add a regular expression filter for events, matches will NOT be shown") do |reg|
          puts c("not implemented yet :(", :red)
          return
        end
        opt.on("-d", "--delete-filter REGEX", String, "delete filter (you can use filter or the index from -l or * to remove all)") do |reg|
          puts c("not implemented yet :(", :red)
          return
        end
        if meth == :log
          opt.on("-t", "--type TYPE", String, "only show of type (e.g.: log 100 -t join,chat)") {|n| opts[:types] = n.split(",") }
          opt.separator "\t\t\t\t\t#{c "chat", :cyan}\t\t" << c("chat message", :yellow)
          opt.separator "\t\t\t\t\t#{c "join", :cyan}\t\t" << c("player connects", :yellow)
          opt.separator "\t\t\t\t\t#{c "leave", :cyan}\t\t" << c("player disconnects", :yellow)
          opt.separator "\t\t\t\t\t#{c "state", :cyan}\t\t" << c("join + leave", :yellow)
        end
        opt.parse!(args)

        if args.first == "off"
          # turning off live log
          push_env(mkey => false)
          mem.delete(:"#{mkey}_filter")
          mem.delete(:"#{mkey}_types")
          mem.delete(:"#{mkey}_grep")
          return
        end

        if args.first == "on"
          # turning on live log
          push_env(mkey => true)
          opts[:lines] ||= 0
          mem[:"#{mkey}_filter"] = opts[:filter] if opts[:filter]
          mem[:"#{mkey}_types"] = opts[:types] if opts[:types].any?
          mem[:"#{mkey}_grep"] = opts[:grep] if opts[:grep].any?
          args.shift
        end

        if args.first.try(:match, /\A\d+\z/)
          opts[:lines] = args.shift.to_i
        end

        # final options
        opts[:lines] ||= 20
        opts[:filter] = true if mem[:"#{mkey}_filter"]
        opts[:types] = mem[:"#{mkey}_types"] if mem[:"#{mkey}_types"]
        opts[:grep] = mem[:"#{mkey}_grep"] if mem[:"#{mkey}_grep"]

        # get backlog
        if meth == :log
          backlog = $mcl.event_backlog.last(opts[:lines])
        else
          backlog = $mcl.log_backlog(opts[:lines])
        end

        # filter
        # backlog = backlog.select do |entry|
        #   type_valid = opts[:types].any? do |type|
        #     case type
        #     when "chat"
        #       false
        #     when "join", "state"
        #       true
        #     when "leave", "state"
        #       false
        #     else true
        #     end
        #   end

        #   !opts[:grep].detect{|p| entry.match(p) } && type_valid
        # end

        # print log
        puts(*backlog)
      rescue OptionParser::InvalidOption, OptionParser::MissingArgument
        opt.to_s.each_line{|s| puts c(s.chomp, :yellow) }
        puts
        puts c("-----ERROR-----", :red)
        puts c("#{$!.message} (#{$!.class})", :red)
        puts c("  #{$@[0]}", :red)
      rescue StandardError => e
        puts c("-----ERROR-----", :red)
        puts c("#{$!.message} (#{$!.class})", :red)
        puts c("  #{$@[0]}", :red)
        puts c("  #{$@[1]}", :red)
      end

      def _cmd_mlog line, args
        _cmd_log(line, args, :mlog)
      end
    end
  end
end


# help               show a list of commands
# !<mcl command>     invoke a MCL command
#
# # all of these work for `mlog` as well which is for MCL output
# ------

# # these only work for log (not for mlog)
# log -t <type>      only show of type (e.g.: log 100 -t join,chat)
#                       chat     chat messages
#                       join     player connects
#                       leave    player disconnects
#                       state    join + leave
#
