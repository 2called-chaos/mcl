module Mcl
  Mcl.reloadable(:HMclTeleport)
  ## Teleport (teleportation shortcuts)
  # !tp book [>|<]
  # !tp <player> [>|<]
  # !tp <src_player> <dst_player>
  # !tp <x> <y> <z>
  # !tp <target> <x> <y> <z>
  class HMclTeleport < Handler
    attr_reader :cron, :watched_versions

    def setup
      register_tp({
        yourself: :member, # teleport yourself
        others: :mod, # teleport others
      })
    end

    def register_tp acl_levels
      register_command :tp, desc: "Teleportation shortcuts (more info with !tp)", acl: acl_levels[:yourself] do |player, args|
        if args[0] == "book"
          $mcl.server.invoke com_book(player, *args[1..-1])
        else
          case args.count
          when 3 then acl_verfiy(player, acl_levels[:others]) ; com_tp(player, args[0..2].join(" "))
          when 4 then com_tp(args[0], args[1..3].join(" "))
          when 1, 2
            dir = args[1] || ">"
            if dir == ">"
              com_tp(player, args[0])
            elsif dir == "<"
              acl_verfiy(player, acl_levels[:others])
              com_tp(args[0], player)
            else
              acl_verfiy(player, acl_levels[:others]) unless args[0] == player
              com_tp(args[0], args[1])
            end
          else
            tellm(player, {text: "!tp book [>|<]", color: "gold"}, {text: " gives you a teleport book for both or given direction", color: "reset"})
            tellm(player, {text: "!tp <target> [>|<]", color: "gold"}, {text: " teleports you to target or target to you", color: "reset"})
            tellm(player, {text: "!tp <p1> <p2>", color: "gold"}, {text: " teleports p1 to p2", color: "reset"})
            tellm(player, {text: "!tp [target] <x> <y> <z>", color: "gold"}, {text: " teleports you or target to position", color: "reset"})
          end
        end
      end
    end

    module Helper
      def tellm p, *msg
        trawm(p, title("TP"), *msg)
      end

      def com_tp source, target
        tellm(source, {text: "You were teleported to ", color: "gold"}, {text: "#{target}", color: "aqua"})
        $mcl.server.invoke %{/tp #{source} #{target}}
      end

      def com_book player, direction = nil, *args
        pages = []
        pman.clear_cache
        players = Player.online.order(:nickname).pluck(:nickname) - [player]

        # TP <
        if !direction || direction == "<"
          (["-", "@a"] + players).in_groups_of(14, false).each do |page_players|
            sp = []
            page_players.each_with_index do |p, i|
              if p == "-"
                sp << %Q{{text:"Teleport X => me\\n", color:"red", bold: true}}
              else
                sp << %Q{{text:"#{p}\\n", color:"#{i % 2 == 0 ? "blue" : "dark_blue"}", hoverEvent:{action:"show_text", value: "TP #{p} to me"}, clickEvent:{action:"run_command", value: "!tp #{p} <"}}}
              end
            end
            pages << sp.join("\n")
          end
        end

        # TP >
        if !direction || direction == ">"
          (["-"] + players).in_groups_of(14, false).each do |page_players|
            sp = []
            page_players.each_with_index do |p, i|
              if p == "-"
                sp << %Q{{text:"Teleport me => X\\n", color:"red", bold: true}}
              else
                sp << %Q{{text:"#{p}\\n", color:"#{i % 2 == 0 ? "blue" : "dark_blue"}", hoverEvent:{action:"show_text", value: "TP me to #{p}"}, clickEvent:{action:"run_command", value: "!tp #{p}"}}}
              end
            end
            pages << sp.join("\n")
          end
        end

        book player, "TP book #{direction}".strip, pages
      end
    end
    include Helper
  end
end
