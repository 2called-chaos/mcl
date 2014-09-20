module Mcl
  Mcl.reloadable(:HMclWarps)
  ## Warps / saved teleports
  # !warps <name>
  # !warps set    [-s] <name> [<x> <y> <z>]
  # !warps delete [-s] <name>
  # !warps share  [-s] <name> [target]
  # !warps list   [-a] [-s] [page|filter] [page]
  class HMclWarps < Handler
    def setup
      register_warp(:member)
    end

    def register_warp acl_level
      register_command :warp, :warps, desc: "Beam me up, Scotty (more info with !warp)", acl: acl_level do |player, args, handler|
        case args[0]
        when "set", "delete", "list", "share"
          handler.send("com_#{args[0]}", player, args[1..-1])
        else
          srv = args.delete("-s")
          if args.any?
            if warp = find_warp(srv ? :__server : player, args[0]).last
              warp(player, warp)
              sleep 0.1
              sound = %w[mob.endermen.portal mob.enderdragon.growl mob.ghast.scream mob.horse.donkey.angry mob.villager.hit].sample(1)[0]
              $mcl.server.invoke %{/execute #{player} ~ ~ ~ playsound #{sound} @a[r=25] #{warp.join(" ")} 3 1}
              $mcl.server.invoke %{/particle portal #{warp.join(" ")} 0 1 0 0.25 1000 force}
              tellm(player, {text: "Off you go...", color: "aqua"})
            else
              tellm(player, {text: "Unknown warp!", color: "red"})
            end
          else
            tellm(player, {text: "Warp names may start with $ to be avail. in all worlds.", color: "aqua"})
            tellm(player, {text: "<name>", color: "gold"}, {text: " beam to given warp", color: "reset"})
            tellm(player, {text: "set <name> [<x> <y> <z>]", color: "gold"}, {text: " add/update warp to current or given position", color: "reset"})
            tellm(player, {text: "delete <name>", color: "gold"}, {text: " delete warp", color: "reset"})
            tellm(player, {text: "share <name> [target]", color: "gold"}, {text: " reveal warp to target (@a by default)", color: "reset"})
            tellm(player, {text: "list [-a] [-s] [page|filter] [page]", color: "gold"}, {text: " list/search warps", color: "reset"})
          end
        end
      end
    end

    def com_set player, args
      srv = args.delete("-s")
      name = args.shift.presence
      acl_verify(player, acl_srv) if srv
      if name && (args.count == 0 || args.count == 3)
        if args.count == 0
          detect_player_position(player) do |pos|
            if pos
              set_warp(srv ? :__server : player, name, pos)
              tellm(player, {text: "Warp ", color: "green"}, {text: name, color: "aqua"}, {text: " set to ", color: "green"}, {text: pos.join(" "), color: "aqua"}, {text: "!", color: "green"})
            else
              tellm(player, {text: "Couldn't determine your position :/ Is your head in water?", color: "red"})
            end
          end
        else
          set_warp(srv ? :__server : player, name, args)
          tellm(player, {text: "Warp ", color: "green"}, {text: name, color: "aqua"}, {text: " set to ", color: "green"}, {text: args.join(" "), color: "aqua"}, {text: "!", color: "green"})
        end
      else
        tellm(player, {text: "!warp set <name> [<x> <y> <z>]", color: "red"})
      end
    end

    def com_delete player, args
      srv = args.delete("-s")
      name = args.shift.presence
      acl_verify(player, acl_srv) if srv
      if name
        if find_warp(srv ? :__server : player, name, false).last
          delete_warp(srv ? :__server : player, name)
          tellm(player, {text: "Warp is gone!", color: "green"})
        else
          tellm(player, {text: "Unknown warp!", color: "red"})
        end
      else
        tellm(player, {text: "!warp delete <name>", color: "red"})
      end
    end

    def com_share player, args
      srv = args.delete("-s")
      name = args.shift.presence
      target = args.shift.presence || "@a"
      if name
        warp = find_warp(srv ? :__server : player, name)
        if warp.last
          tellm(player, {text: "You shared a #{"server " if srv}warp with ", color: "yellow"}, {text: "#{target}", color: "aqua"}, {text: ":", color: "yellow"})
          tellm(target, {text: "#{player}", color: "aqua"}, {text: " shared a #{"server " if srv}warp with ", color: "yellow"}, {text: "#{target}", color: "aqua"}, {text: ":", color: "yellow"})
          tellm(target, warp[0] == :__global ? {text: "GLOBAL", color: "red"} : {text: warp[0], color: "gold"}, {text: " #{name} ", color: "green", hoverEvent: {action: "show_text", value: {text: "warp now"}}, clickEvent: {action: "run_command", value: "!warp #{name}"}},{text: warp.last.join(" "), color: "yellow"})
          tellm(target,
            {text: "save warp", color: "aqua", underlined: true, hoverEvent: {action: "show_text", value: {text: "click to save"}}, clickEvent: {action: "run_command", value: "!warp set #{name} #{warp.last.join(" ")}"}},
            {text: " "},
            {text: "customize", color: "dark_aqua", underlined: true, hoverEvent: {action: "show_text", value: {text: "click to customize"}}, clickEvent: {action: "suggest_command", value: "!warp set #{name} #{warp.last.join(" ")}"}}
          )
        else
          tellm(player, {text: "Unknown warp!", color: "red"})
        end
      else
        tellm(player, {text: "!warp share <name> [target]", color: "red"})
      end
    end

    def com_list player, args
      all = args.delete("-a")
      srv = args.delete("-s")
      pram = memory(srv ? :__server : player)
      page, filter = 1, nil

      # filter
      if args[0] && args[0].to_i == 0
        filter = /#{args[0]}/
        page = (args[1] || 1).to_i
      else
        page = (args[0] || 1).to_i
      end

      # warps
      swarps = [].tap do |r|
        pram.each do |world, warps|
          if all || (world == $mcl.server.world || world == :__global)
            warps.sort_by(&:first).each do |name, pos|
              if !filter || name.to_s.match(filter)
                r << [
                  world == :__global ? {text: "GLOBAL", color: "red"} : {text: world, color: "gold"},
                  {text: " #{name} ", color: "green", hoverEvent: {action: "show_text", value: {text: "warp to #{name} now"}}, clickEvent: {action: "run_command", value: "!warp #{name}"}},{text: pos.join(" "), color: "yellow"}
                ]
              end
            end
          end
        end
      end

      # paginate
      page_contents = swarps.in_groups_of(7, false)
      pages = (swarps.count/7.0).ceil

      if swarps.any?
        tellm(player, {text: "--- Showing #{"server " if srv}warps page #{page}/#{pages} (#{swarps.count} warps) ---", color: "aqua"})
        page_contents[page-1].each {|warp| tellm(player, *warp) }
        if srv
          tellm(player, {text: "Use ", color: "aqua"}, {text: "-a", color: "light_purple"}, {text: " to show warps in other worlds.", color: "aqua"}) unless all
        else
          tellm(player, {text: "Use ", color: "aqua"}, {text: "-s", color: "light_purple"}, {text: " to show server warps.", color: "aqua"})
        end
      else
        tellm(player, {text: "No warps found for that filter/page!", color: "red"})
      end
    end

    module Helper
      # ACL for modifying server warps
      def acl_srv
        :admin
      end

      def memory p, &block
        if block
          prec(p).tap do |r|
            r.data[:mcl_warps] ||= { __global: {} }
            block.call(r.data[:mcl_warps])
            r.save!
          end
        else
          prec(p).data[:mcl_warps] ||= { __global: {} }
        end
      end

      def tellm p, *msg
        trawt(p, "Warp", *msg)
      end

      def warp player, warp
        $mcl.server.invoke %{/tp #{player} #{warp.join(" ")}}
      end

      def find_warp player, name, fallback = true
        pram, sram = memory(player), memory(:__server)
        if name.start_with?("$")
          [:__global, pram[:__global][name.to_s] || (fallback && sram[:__global][name.to_s])]
        else
          [$mcl.server.world, pram[$mcl.server.world].try(:[], name.to_s) || (fallback && sram[$mcl.server.world].try(:[], name.to_s))]
        end
      end

      def set_warp player, name, pos
        memory(player) do |pram|
          if name.start_with?("$")
            pram[:__global][name.to_s] = pos.map(&:to_i)
          else
            pram[$mcl.server.world] ||= {}
            pram[$mcl.server.world][name.to_s] = pos.map(&:to_i)
          end
        end
      end

      def delete_warp player, name
        memory(player) do |pram|
          if name.start_with?("$")
            pram[:__global].delete(name.to_s)
          else
            pram[$mcl.server.world].try(:delete, name.to_s)
          end
        end
      end
    end
    include Helper
  end
end
