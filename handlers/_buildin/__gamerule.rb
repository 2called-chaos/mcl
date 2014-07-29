module Mcl
  module Commands
    class Gamerule < Handler
      def setup
        register_command :gamerule do |cmd|
          cmd.description = "Shortcuts for /gamerule commands."
          cmd.usage = "Use '!gamerule list' to get a list of mapped aliases"

          cmd.sub :list do |sub|
            sub.description = "List all of the registered shortcuts."
            sub.callback do |event, app, server, handler|
              event.origin # Player,Server,Entity,Nobody
              event.type # boot,chat,uauth,clientstate,log,unknown
              event.subtype # warn,info
              event.command? # true/false (true if event appears to be a proper command)
            end
          end
        end

        # Usage: !cbspam [0/1]
        register_command :cbspam do |cmd|
          cmd.description = "Gamerule shortcut for CommandBlockOutput"
          cmd.param :value, type: :bool, optional: true

          cmd.callback do |event, app, server, handler|
            if event.params.first.given?
              srv.gamemode "CommandBlockOutput", event.params.first.value
              srv.pm event.player, "Gamerule set!"
            else
              srv.gamemode "CommandBlockOutput"
              # we need to wait for the result of the command. With 'reconsider' we delay
              # further actions until our reconsider pattern was matched a.k.a we've got the response.
              event.reconsider :log, /commandBlockOutput = (.+)/ do |promise|
                promise.success do |pev|
                  srv.pm event.player, pev.body
                end
                promise.fail do
                  srv.pm event.player, "sorry, something went wrong"
                end
              end
              srv.gamemode "CommandBlockOutput", event.params.first.value
            end
          end
        end

        # listener for client related stuff
        register_listener :client_listener do |list|
          list.subscribe :clientstate, :uath do |ev, app, srv, hnd|
            srv.say "#{ev.player.name} state event" if ev.type?(:clientstate)
          end
        end
      end

      def short_tick

      end
    end
  end
end


# quickrule
!cbspam !cbnospam
!gried !nogrief
!firetick !nofiretick
!nomobs !mobs
!loot !noloot
!drops !nodrops
!keepinv !loseinv
!foodregen !nofoodregen
!tickspeed <num>
!deathmsg !nodeathmsg
