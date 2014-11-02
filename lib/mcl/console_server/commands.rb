module Mcl
  class ConsoleServer
    module Commands
      def _cmd_commands line, args
        puts "Available commands: " << commands.join(", ")
      end

      def _cmd_say line, args

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
# /<mc command>      invoke a command on the server console
# .<msg>             shortcut for /say
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
# # sessions
# sessions           shows a list of open console sessions
# msg <sid> <msg>    send a message to given session
# broadcast <msg>    send a message to all sessions
# nick <name>        name your session
#
# # protocol
# env                shows your current environment
# set_env <data>     apply settings from client (filters, etc.)
# set_client <data>  set session client id






# exit / quit        get out of here
