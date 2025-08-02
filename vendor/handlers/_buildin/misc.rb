module Mcl
  Mcl.reloadable(:HMclMisc)
  ## Miscellaneous commands
  # !clear
  # !id [block_id]
  # !colors
  # !rec [rec] [pitch]
  # !compass [target] [--purge]
  # !summon <entity> [-c count] [-t target] [x] [y] [z] [dataTag]
  # !setspawn
  # !idea [target]
  # !strike [target]
  # !longwaydown [target]
  # !muuhhh [target]
  class HMclMisc < Handler
    def setup
      register_clear(:guest, :mod)
      register_id(:guest)
      register_colors(:guest)
      register_rec(:guest)
      register_compass(:guest, acl_level_purge = :mod)
      register_summon(:admin)
      register_setspawn(:mod)
      register_idea(:member)
      register_strike(:mod)
      register_longwaydown(:builder)
      register_muuhhh(:mod)
    end

    def register_clear acl_level, acl_level_others
      register_command :clear, desc: "clears your inventory", acl: acl_level do |player, args|
        acl_verify(player, acl_level_others) if args.first && args.first != player
        $mcl.server.invoke %{/clear #{args.first || player}}
      end
    end

    def register_id acl_level
      register_command :id, desc: "shows you the new block name for an old block ID", acl: acl_level do |player, args|
        bid = (args[0] || "0").to_i
        if h = Id2mcn.conv(bid)
          trawm(player, {text: "TileID: ", color: "gold"}, {text: "#{bid}", color: "green"}, {text: "  TileName: ", color: "gold"}, {text: "#{h}", color: "green"})
        else
          trawm(player, {text: "No name could be resolved for block ID #{bid}", color: "red"})
        end
      end
    end

    def register_colors acl_level
      register_command :colors, desc: "shows all available colors", acl: acl_level do |player, args|
        chunks = %w[black dark_blue dark_green dark_aqua dark_red dark_purple gold gray dark_gray blue green aqua red light_purple yellow white].in_groups_of(4, false)

        chunks.each do |cl|
          trawm(player, *cl.map{|c| {text: c, color: c} }.zip([{text: " / "}] * (cl.count-1)).flatten.compact)
        end
      end
    end

    def register_summon acl_level
      register_command :summon, desc: "improved /summon command", acl: acl_level do |player, args, handler, opt|
        if args.count > 0
          # options
          amount = 1
          target = player
          opt.on("-c AMOUNT", Integer) {|v| amount = v }
          opt.on("-t TARGET", String) {|v| target = v }
          opt.parse!(args) #rescue nil

          # etype
          entity = args.shift.to_s.underscore.presence
          types = nil
          version_switch do |v|
            v.default do
              types = %w[area_effect_cloud armor_stand arrow bat blaze boat cave_spider chest_minecart chicken commandblock_minecart cow creeper donkey dragon_fireball egg elder_guardian ender_crystal ender_dragon ender_pearl enderman endermite evocation_fangs evocation_illager eye_of_ender_signal falling_block fireball fireworks_rocket furnace_minecart ghast giant guardian hopper_minecart horse husk illusion_illager item item_frame leash_knot lightning_bolt llama llama_spit magma_cube minecart mooshroom mule ocelot painting parrot pig polar_bear potion rabbit sheep shulker shulker_bullet silverfish skeleton skeleton_horse slime small_fireball snowball snowman spawner_minecart spectral_arrow spider squid stray tnt tnt_minecart vex villager villager_golem vindication_illager witch wither wither_skeleton wither_skull wolf xp_bottle xp_orb zombie zombie_horse zombie_pigman zombie_villager]
            end
            v.since "1.13", "17w45a" do
              types = %w[area_effect_cloud armor_stand arrow bat blaze boat cave_spider chest_minecart chicken cod command_block_minecart cow creeper dolphin donkey dragon_fireball drowned egg elder_guardian end_crystal ender_dragon ender_pearl enderman endermite evoker evoker_fangs experience_bottle experience_orb eye_of_ender falling_block fireball fireworks_rocket furnace_minecart ghast giant guardian hopper_minecart horse husk illusioner iron_golem item item_frame leash_knot lightning_bolt llama llama_spit magma_cube minecart mooshroom mule ocelot painting parrot phantom pig polar_bear potion pufferfish rabbit salmon sheep shulker shulker_bullet silverfish skeleton skeleton_horse slime small_fireball snow_golem snowball spawner_minecart spectral_arrow spider squid stray tnt tnt_minecart trident tropical_fish turtle vex villager vindicator witch wither wither_skeleton wither_skull wolf zombie zombie_horse zombie_pigman zombie_villager]
            end
          end
          etype = types.include?(entity) ? entity : types.grep(/#{entity}/i).first || entity

          if !(!pmemo(player)[:danger_mode] && amount > 500 && require_danger_mode(player, "Summoning >500 entities require danger mode to be enabled!"))
            trawt(player, "summon", {text: "Summoned #{amount} entities of type #{etype}."})

            version_switch do |v|
              v.default do
                amount.times { $mcl.server.invoke %{/execute #{target} ~ ~ ~ /summon #{etype} #{args.join(" ")}} }
              end
              v.since "1.13", "17w45a" do
                amount.times { $mcl.server.invoke %{/execute as #{target} at #{target} run summon #{etype} #{args.join(" ")}}.strip }
              end
            end
          end
        else
          trawt(player, "summon", {text: "Usage: ", color: "gold"}, {text: "!summon <entity> [-c amount] [-t target] [x] [y] [z] [dataTag]", color: "aqua"})
        end
      end
    end

    def register_setspawn acl_level
      register_command :setspawn, desc: "sets your spawnpoint to current position", acl: acl_level do |player, args|
        $mcl.server.invoke do |cmd|
          cmd.default "/execute #{args.first || player} ~ ~ ~ spawnpoint #{args.first || player} ~ ~ ~"
          cmd.since "1.13", "17w45a", "/execute as #{args.first || player} at #{args.first || player} run spawnpoint #{args.first || player} ~ ~ ~"
        end
        traw(player, "Your spawnpoint has been set!", color: "gold")
      end
    end

    def register_rec acl_level
      register_command :rec, desc: "plays music discs", acl: acl_level do |player, args|
        voice = args.delete("-v")
        if args.delete("-s")
          $mcl.server.invoke "/stopsound #{player} #{voice ? "voice" : "record"}"
        elsif args[0].present?
          $mcl.server.invoke do |cmd|
            cmd.before "1.9", "16w02a", %{/execute as #{player} at #{player} ~ ~ ~ playsound records.#{args[0]} nil #{player} ~ ~ ~ 10000 #{args[1] || 1} 1}
            cmd.default %{/execute #{player} ~ ~ ~ playsound record.#{args[0]} #{voice ? "voice" : "record"} #{player} ~ ~ ~ 10000 #{args[1] || 1} 1}
            cmd.since "1.13", "17w45a", %{/execute as #{player} at #{player} run playsound music_disc.#{args[0]} #{voice ? "voice" : "record"} #{player} ~ ~ ~ 10000 #{args[1] || 1} 1}
          end
        else
          trawm(player, {text: "Usage: ", color: "gold"}, {text: "!rec <track/-s top> [pitch] [-v oice]", color: "yellow"})
          trawm(player, {text: "Tracks: ", color: "gold"}, {text: "11 13 blocks cat chirp far mall mellohi stal strad wait ward", color: "yellow"})
        end
      end
    end

    def register_compass acl_level, acl_level_purge
      register_command :compass, desc: "projects a compass around you or a target for a few seconds", acl: acl_level do |player, args|
        if args.delete("--purge")
          acl_verify(player, acl_level_purge)
          server.invoke %{/kill @e[tag=mcl_misc_compass_i]}
          trawm(player, {text: "Cleared all loaded compass indicators!", color: "green"})
          throw :handler_exit, :exit
        end

        target = args.first || player
        detect_player_position(target) do |pos|
          if pos
            id = server.uniqid
            x, y, z = pos
            summon_indicator = ->(id, x, y, z, name, block = "white_concrete"){
              data = []
              data << %{Fire:32767}
              data << %{Marker:1b}
              data << %{Invulnerable:1b}
              data << %{Invisible:1b}
              data << %{NoGravity:1b}
              data << %{CustomName:'{"text":"#{name}"}',CustomNameVisible:1}
              data << %{Tags:["mcl_misc_compass_i", "mcl_misc_compass_i_#{id}"]}
              data << %{ArmorItems:[{},{},{},{id:"#{block}",Count:1b}]}
              server.invoke %{/summon armor_stand #{x} #{y} #{z} {#{data.join(",")}}}
            }
            summon_indicator[id, x, y, z - 2, "North", "red_concrete"]
            summon_indicator[id, x + 2, y, z, "East"]
            summon_indicator[id, x, y, z + 2, "South"]
            summon_indicator[id, x - 2, y, z, "West"]
            async_safe do
              sleep 5
              sync { server.invoke %{/kill @e[tag=mcl_misc_compass_i_#{id}]} }
            end
          else
            if args.first == player
              trawm(player, {text: "Couldn't determine your position :/ Is your head underwater?", color: "red"})
            else
              trawm(player, {text: "Couldn't determine position of #{target} :/ Maybe the target is underwater.", color: "red"})
            end
          end
        end
      end
    end

    def register_idea acl_level
      register_command :idea, desc: "you had an idea!", acl: acl_level do |player, args|
        $mcl.server.invoke do |cmd|
          cmd.default %{/execute #{args.first || player} ~ ~ ~ particle lava ~ ~2 ~ 0 0 0 1 1000 force}
          cmd.since "1.13", "17w45a", %{/execute as #{args.first || player} at #{args.first || player} run particle lava ~ ~2 ~ 0 0 0 1 1000 force}
        end
      end
    end

    def register_strike acl_level
      register_command :strike, desc: "strikes you or a target with lightning", acl: acl_level do |player, args|
        $mcl.server.invoke do |cmd|
          cmd.default %{/execute #{args.first || player} ~ ~ ~ summon lightning_bolt}
          cmd.since "1.13", "17w45a", %{/execute as #{args.first || player} at #{args.first || player} run summon lightning_bolt}
        end
      end
    end

    def register_longwaydown acl_level
      register_command :longwaydown, :alongwaydown, desc: "sends you or target to leet height!", acl: acl_level do |player, args|
        $mcl.server.invoke do |cmd|
          cmd.default %{/execute #{args.first || player} ~ ~ ~ tp #{args.first || player} ~ 1337 ~}
          cmd.since "1.13", "17w45a", %{/execute as #{args.first || player} at #{args.first || player} run tp #{args.first || player} ~ 1337 ~}
        end
      end
    end

    def register_muuhhh acl_level
      register_command :muuhhh, desc: "muuuuhhhhhh.....", acl: acl_level do |player, args|
        async do
          target = args.first || player
          drop = strbool(args.second || true)
          cow(target, "~ ~50 ~", drop)
          sleep 3

          cow(target, "~ ~50 ~", drop)
          sleep 0.2
          cow(target, "~ ~50 ~", drop)
          sleep 3


          cow(target, "~ ~50 ~", drop)
          sleep 0.2
          cow(target, "~ ~50 ~", drop)
          sleep 0.2
          cow(target, "~ ~50 ~", drop)
          sleep 3

          $mcl.sync do # aquire lock once to actually reduce lag
            100.times do
              cow(target, "~ ~50 ~", drop, true)
              sleep 0.05
            end
          end
        end
      end
    end

    module Helper
      def cow target, pos = "~ ~ ~", drop = false, fire = false
        $mcl.sync {
          $mcl.server.invoke do |cmd|
            drop = drop ? "#{" {Fire:1000}" if fire}" : " {DeathLootTable:empty}"
            cmd.default %{/execute #{target} ~ ~ ~ summon cow #{pos}}
            cmd.since "1.13", "17w45a", %{/execute as #{target} at #{target} run summon cow #{pos}#{drop}}
          end
        }
      end
    end
    include Helper
  end
end
