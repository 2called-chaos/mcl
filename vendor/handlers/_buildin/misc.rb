module Mcl
  Mcl.reloadable(:HMclMisc)
  ## Miscellaneous commands
  # !id [block_id]
  # !colors
  # !rec [rec] [pitch]
  # !idea [target]
  # !strike [target]
  # !longwaysdown [target]
  # !muuhhh [target]
  class HMclMisc < Handler
    def setup
      register_id(:guest)
      register_colors(:guest)
      register_rec(:guest)
      register_idea(:member)
      register_strike(:mod)
      register_longwaydown(:builder)
      register_muuhhh(:mod)
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
          trawm(player, *cl.map{|c| {text: c, color: c} }.zip([{text: " / ", color: "reset"}] * (cl.count-1)).flatten.compact)
        end
      end
    end

    def register_rec acl_level
      register_command :rec, desc: "plays music discs", acl: acl_level do |player, args|
        if args[0].present?
          $mcl.server.invoke %{/execute #{player} ~ ~ ~ playsound records.#{args[0]} #{player} ~ ~ ~ 10000 #{args[1] || 1} 1}
        else
          trawm(player, {text: "Usage: ", color: "gold"}, {text: "!rec <track> [pitch]", color: "yellow"})
          trawm(player, {text: "Tracks: ", color: "gold"}, {text: "11 13 blocks cat chirp far mall mellohi stal strad wait ward", color: "yellow"})
        end
      end
    end

    def register_idea acl_level
      register_command :idea, desc: "you had an idea!", acl: acl_level do |player, args|
        $mcl.server.invoke "/execute #{args.first || player} ~ ~ ~ particle lava ~ ~2 ~ 0 0 0 1 1000 force"
      end
    end

    def register_strike acl_level
      register_command :strike, desc: "strikes you or a target with lightning", acl: acl_level do |player, args|
        $mcl.server.invoke "/execute #{args.first || player} ~ ~ ~ summon LightningBolt"
      end
    end

    def register_longwaydown acl_level
      register_command :longwaydown, :alongwaydown, desc: "sends you or target to leet height!", acl: acl_level do |player, args|
        $mcl.server.invoke "/execute #{args.first || player} ~ ~ ~ tp @p ~ 1337 ~"
      end
    end

    def register_muuhhh acl_level
      register_command :muuhhh, desc: "muuuuhhhhhh.....", acl: acl_level do |player, args|
        async do
          target = args.first || player
          cow(target, "~ ~50 ~")
          sleep 3

          cow(target, "~ ~50 ~")
          sleep 0.2
          cow(target, "~ ~50 ~")
          sleep 3


          cow(target, "~ ~50 ~")
          sleep 0.2
          cow(target, "~ ~50 ~")
          sleep 0.2
          cow(target, "~ ~50 ~")
          sleep 3

          $mcl.sync do # aquire lock once to actually reduce lag
            100.times do
              cow(target, "~ ~50 ~")
              sleep 0.05
            end
          end
        end
      end
    end

    module Helper
      def cow target, pos = "~ ~ ~"
        $mcl.sync { $mcl.server.invoke "/execute #{target} ~ ~ ~ summon Cow #{pos}" } # {DropChances:[0F,0F,0F,0F,0F]}
      end
    end
    include Helper
  end
end
