module Mcl
  Mcl.reloadable(:HWarps)
  class HWarps < Handler
    def setup
      setup_parsers
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

    def title
      {text: "[Warp] ", color: "light_purple"}
    end

    def spacer
      {text: " / ", color: "reset"}
    end

    def tellm p, *msg
      trawm(p, *([title] + msg))
    end

    # ===========
    # = Helpers =
    # ===========
    def warp player, warp
      $mcl.server.invoke %{/tp #{player} #{warp.join(" ")}}
    end

    def find_warp player, name
      pram, sram = memory(player), memory(:__server)
      if name.start_with?("$")
        pram[:__global][name.to_s] || sram[:__global][name.to_s]
      else
        pram[$mcl.server.world].try(:[], name.to_s) || sram[$mcl.server.world].try(:[], name.to_s)
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


    # ============
    # = Commands =
    # ============
    def setup_parsers
      register_command :warp, :warps, desc: "Beam me up, Scotty (more info with !warp)" do |handler, player, command, target, args, optparse|
        handler.acl_verify(player)

        case args[0]
        when "set", "delete", "list"
          handler.send("com_#{args[0]}", player, args[1..-1])
        else
          srv = args.delete("-s")
          if args.any?
            if warp = handler.find_warp(srv ? :__server : player, args[0])
              handler.warp(player, warp)
              sleep 0.1
              sound = %w[mob.endermen.portal mob.enderdragon.growl mob.ghast.scream mob.horse.donkey.angry mob.villager.hit].sample(1)[0]
              $mcl.server.invoke %{/execute #{player} ~ ~ ~ playsound #{sound} @a[r=25] #{warp.join(" ")} 3 1}
              $mcl.server.invoke %{/particle portal #{warp.join(" ")} 0 1 0 0.25 1000 force}
              tellm(player, {text: "Off you go...", color: "aqua"})
            else
              tellm(player, {text: "Unknown warp!", color: "red"})
            end
          else
            handler.tellm(player, {text: "Warp names may start with $ to be avail. in all worlds.", color: "aqua"})
            handler.tellm(player, {text: "<name>", color: "gold"}, {text: " beam to given warp", color: "reset"})
            handler.tellm(player, {text: "set <name> [<x> <y> <z>]", color: "gold"}, {text: " add/update warp to current or given position", color: "reset"})
            handler.tellm(player, {text: "delete <name>", color: "gold"}, {text: " delete warp", color: "reset"})
            handler.tellm(player, {text: "list [-a|-s] [page|filter] [page]", color: "gold"}, {text: " list/search warps", color: "reset"})
          end
        end
      end
    end

    def com_set player, args
      srv = args.delete("-s")
      name = args.shift.presence
      if name && (args.count == 0 || args.count == 3)
        if args.count == 0
          detect_player_position(player) do |pos|
            if pos
              $mcl.synchronize do
                $mcl.delay do
                  set_warp(srv ? :__server : player, name, pos)
                  tellm(player, {text: "Warp ", color: "green"}, {text: name, color: "aqua"}, {text: " set to ", color: "green"}, {text: pos.join(" "), color: "aqua"}, {text: "!", color: "green"})
                end
              end
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
      if name
        if find_warp(srv ? :__server : player, name)
          delete_warp(srv ? :__server : player, name)
          tellm(player, {text: "Warp is gone!", color: "green"})
        else
          tellm(player, {text: "Unknown warp!", color: "red"})
        end
      else
        tellm(player, {text: "!warp delete <name>", color: "red"})
      end
    end

    def com_list player, args
      acl_verify(player)
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
                  {text: " #{name} ", color: "green"},{text: pos.join(" "), color: "yellow"}
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
  end
end
