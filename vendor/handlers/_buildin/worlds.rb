module Mcl
  Mcl.reloadable(:HMclWorlds)
  ## Simple world manager
  # !world(s) <name> [info|backup|delete]
  # !worldbook
  class HMclWorlds < Handler
    def setup
      register_worlds(:admin)
      register_worldbook(:member)
    end

    def register_worlds acl_level
      register_command :world, :worlds, desc: "swaps a world and restarts the server", acl: acl_level do |player, args|
        tworld, action = args[0], args[1]
        if tworld
          if tworld =~ /\A[0-9a-z_\-\/]+\z/i
            case action
            when "info"
              if valid_world?(tworld)
                backups = $mcl.server.backups(tworld, true)
                trawt(player, "MCLiverse", {text: "#{tworld}", color: "aqua"})
                trawt(player, "MCLiverse", {text: " size: ", color: "gold"}, { text: "#{world_size(tworld)}", color: "yellow"})
                trawt(player, "MCLiverse", {text: " last modified: ", color: "gold"}, { text: "#{world_mtime(tworld)}", color: "yellow"})
                trawt(player, "MCLiverse", {text: " backups: ", color: "gold"}, { text: "#{backups.count} (#{backups_size(backups)})", color: "yellow"})
                trawt(player, "MCLiverse", {text: " last backup: ", color: "gold"}, { text: "#{last_backup(backups)}", color: "yellow"})
              else
                trawt(player, "MCLiverse", {text: "Unknown world!", color: "red"})
              end
            when "backup"
              if valid_world?(tworld)
                trawt(player, "MCLiverse", {text: "Starting backup!", color: "gold"})
                $mcl.server.backup_world(tworld) do
                  trawt(player, "MCLiverse", {text: "Backup done!", color: "gold"})
                end
              else
                trawt(player, "MCLiverse", {text: "Unknown world!", color: "red"})
              end
            when "delete"
              if valid_world?(tworld)
                if tworld == $mcl.server.world
                  trawt(player, "MCLiverse", {text: "You cannot delete the current world!", color: "red"})
                else
                  hsh = $mcl.server.world_hash(tworld)
                  if args[2] == hsh[0..5]
                    $mcl.server.world_destroy(tworld, strbool(args[3]))
                    trawt(player, "MCLiverse", {text: "World removed!", color: "red"})
                  else
                    trawt(player, "MCLiverse", {text: "a", obfuscated: true, color: "green"}, {text: "WARNING: This command cannot be undone!", color: "red"}, {text: "a", obfuscated: true, color: "green"})
                    trawt(player, "MCLiverse", {text: "To remove the world type:", color: "gold"})
                    trawt(player, "MCLiverse", {text: "  !world #{tworld} delete #{hsh[0..5]}", color: "aqua"}, {text: " [true]", italic: true, color: "gray"})
                    trawt(player, "MCLiverse", {text: "You can pass a fourth argument (true) to also destroy backups of this world.", color: "gold"})
                  end
                end
              else
                trawt(player, "MCLiverse", {text: "Unknown world!", color: "red"})
              end
            else
              if action
                trawt(player, "MCLiverse", {text: "Unknown action #{action}!", color: "red"})
              else
                if tworld == $mcl.server.world
                  trawt(player, "MCLiverse", {text: "Already on that world!", color: "red"})
                else
                  trawt(player, "MCLiverse", {text: "Swapping to #{"new " unless valid_world?(tworld)}world ", color: "aqua"}, {text: "#{tworld}", color: "light_purple"}, {text: "...", color: "aqua"})

                  # update property file after server is stopped
                  async do
                    sleep 3 while $mcl.server.alive?
                    $mcl.sync do
                      $mcl.log.info "[MCLiverse] Swapping world..."
                      sleep 1
                      $mcl.server.update_property "level-name", tworld
                    end
                  end

                  trawt("@a", "MCLiverse", {text: "SERVER IS ABOUT TO RESTART!", color: "red"})
                  async do
                    sleep 5
                    $mcl.sync { $mcl_reboot = true }
                  end
                end
              end
            end
          else
            trawt(player, "[MCLiverse]", {text: "only a-z 0-9 - / and _ are allowed", color: "red"})
          end
        else
          trawt(player, "[MCLiverse]", {text: "!world <name> [info|backup|delete]", color: "yellow"})
          trawt(player, "[MCLiverse]", {text: "!worldbook", color: "yellow"})
          trawt(player, "[MCLiverse]", {text: "current world is: ", color: "gold"}, {text: "#{$mcl.server.world}", color: "aqua"})
          $mcl.server.known_worlds.in_groups_of(5, false).each do |worlds|
            trawt(player, "[MCLiverse]", {text: "known worlds: ", color: "gold"}, {text: worlds.join(", "), color: "aqua"})
          end
        end
      end
    end

    def register_worldbook acl_level
      register_command :worldbook, "gives you a worldbook to manage worlds", acl: acl_level do |player, args|
        # @todo implement worldbook
        trawt(player, "MCLiverse", {text: "Not yet implemented!", color: "red"})
      end
    end

    module Helper
      def valid_world? world
        $mcl.server.known_worlds.include?(world.to_s)
      end

      def world_size world = nil
        $mcl.server.human_bytes $mcl.server.world_size(world)
      end

      def world_mtime world = nil
        mtime = File.mtime("#{$mcl.server.world_root(world)}/level.dat")
        "#{mtime.strftime("%F %T")} (#{Player.fseconds((Time.current - mtime).to_i)})"
      end

      def backups_size backups
        $mcl.server.human_bytes backups.map{|b| b[3] }.inject(:+)
      end

      def last_backup backups
        "#{backups.first[2].strftime("%F %T")} (#{Player.fseconds((Time.current - backups.first[2]).to_i)})"
      end
    end
    include Helper
  end
end
