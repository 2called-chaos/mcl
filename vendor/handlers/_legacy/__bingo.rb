# ========
# = NOTE =
# ========
# This plugin is designed for MCL 1.0 and currently has no plans
# to get ported, most parts will be included in !world command
# ========
module Mcl
  Mcl.reloadable(:HMclBingo)
  ## Simple bingo manager
  # !bingo reset
  # !bingo book
  class HMclBingo < Handler
    def setup
      register_bingo(:guest, reset: :admin)
      # register_worldbook(:member)
      @votes = {}
    end

    def register_bingo acl_level, acl_levels = {}
      register_command :bingo, desc: "simple bingo handler", acl: acl_level do |player, args|
        case action = args.shift
        when "reset"
          acl_verify(player, acl_levels[:reset])
          reset_world(player)
        when "seed"
          # acl_verify(player, acl_levels[:reset])
          $mcl.server.invoke %{setblock 166 150 143 redstone_block}
          sleep 1
          $mcl.server.invoke %{scoreboard players set seed is #{args[0]}}
        else
          tellm(player, {text: "!bingo [seed|reset]", color: "yellow"})
          tellm(player, {text: "current bingo instance: ", color: "gold"}, {text: "#{$mcl.server.world}", color: "aqua"})
        end
      end
      register_command :reset, desc: "vote for bingo reset", acl: :guest do |player, args|
        $mcl.pman.clear_cache
        oc = Player.online.count
        nc = (oc * 0.6).ceil

        if oc >= nc
          tellm("@a", {text: "VOTE ACCEPTED! Resetting the map...", color: "green"})
          reset_world("@a", "Vote demands reset")
        else
          if @votes[player]
            tellm(player, {text: "You already voted for a reset!", color: "red"}, {text: " #{oc} votes missing...", color: "aqua"})
          else
            @votes[player] = 1
            async do
              sleep 300
              @votes.delete(player)
            end
            tellm("@a", {text: "#{player}", color: "aqua"}, {text: " voted for a map reset!", color: "red"}, {text: " Type ", color: "gold"}, {text: "!reset", color: "aqua"}, {text: " to vote! ", color: "gold"}, {text: " (#{oc} votes missing...)", color: "yellow"})
          end
        end
      end
      register_command :spawn, desc: "Teleport you to spawn", acl: :guest do |player, args|
        $mcl.server.invoke %{/tp #{player} 150 150 150 0 0}
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

      def tellm p, *msg
        trawm(p, title("Bingo"), *msg)
      end

      def uniqid prefix = ''
        t = Time.now.to_f
        sprintf("%s%8x%05x", prefix, t.floor, (t - t.floor) * 1000000)
      end

      def reset_world player, reason = "Admin triggered map reset"
        tellm(player, {text: "Resetting map... Hang on tight!", color: "aqua"})
        tellm("@a", {text: "#{reason}, get ready for server restart...", color: "gold"})
        seed = "bingo_#{uniqid}"
        $mcl.server.world_copy("bingo_src", seed)

        # update property file after server is stopped
        async do
          sleep 3 while $mcl.server.alive?
          $mcl.sync do
            $mcl.log.info "[Bingo] Swapping world..."
            sleep 1
            $mcl.server.properties.update("level-name" => seed)
          end
        end

        announce_server_restart
        tellm("@a", {text: "SERVER IS ABOUT TO RESTART!", color: "red"})
        async do
          sleep 8
          $mcl.sync { $mcl_reboot = true }
        end
      end
    end
    include Helper
  end
end
