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
            puts c("[#{sess.client_id}] ", :magenta) << c("#{args.join(" ")}")
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
    end
  end
end


# help               show a list of commands
# !<mcl command>     invoke a MCL command
#
# # all of these work for `mlog` as well which is for MCL output
# log                same as `log 20`
# log <N>            shows last N lines of output (shortcut for -n)
# log <on/off>       turn live logging on or off (when turning on you can combine -f -t -g)
# ------
# log -h             shows this help
# log -n N           shows last N lines of output (if available)
# log -g regex       grep/search backlog with regular expression (can be combined with -n which is 1000 by default)
# log -a regex       add a regular expression filter for events, matches will NOT be shown
# log -f             apply filters (to use like `log 100 -f`)
# log -l             list all filters
# log -d <filter>    delete filter (you can use filter or the index from -l or * to remove all)
#
# # these only work for log (not for mlog)
# log -t <type>      only show of type (e.g.: log 100 -t join,chat)
#                       chat     chat messages
#                       join     player connects
#                       leave    player disconnects
#                       state    join + leave
#
