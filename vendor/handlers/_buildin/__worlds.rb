module Mcl
  Mcl.reloadable(:HMclEval)
  class HMclEval < Handler
    def setup
      register_worlds
    end

    def register_worlds
      register_command :world, desc: "swaps a world and restarts the server" do |handler, player, command, target, args, optparse|
        handler.acl_verify(player)

        if args[0]
          if args[0] =~ /\A[0-9a-z_\-]+\z/i
            if args[0] == $mcl.server.world
              handler.trawm(player, {text: "[MCLiverse] ", color: "gold"}, {text: "Already on that world!", color: "red"})
            else
              handler.trawm(player, {text: "[MCLiverse] ", color: "gold"}, {text: "Swapping to different world...", color: "aqua"})

              # update property file after server is stopped
              async do
                sleep 3 while $mcl.server.alive?
                $mcl.sync do
                  $mcl.log.info "[MCLiverse] Swapping world..."
                  sleep 1
                  $mcl.server.update_property "level-name", args[0]
                end
              end

              handler.trawm("@a", {text: "[MCLiverse] ", color: "gold"}, {text: "SERVER IS ABOUT TO RESTART!", color: "red"})
              async do
                sleep 5
                $mcl.sync { $mcl_reboot = true }
              end
            end
          else
            handler.trawm(player, {text: "[MCLiverse] ", color: "gold"}, {text: "only a-z 0-9 - and _ are allowed", color: "red"})
          end
        else
          handler.trawm(player, {text: "[MCLiverse] ", color: "gold"}, {text: "current world is: ", color: "aqua"}, {text: "#{$mcl.server.world}", color: "light_purple"})
          handler.trawm(player, {text: "[MCLiverse] ", color: "gold"}, {text: "known worlds: ", color: "aqua"}, {text: $mcl.server.known_worlds.join(", "), color: "light_purple"})
        end
      end
    end
  end
end
