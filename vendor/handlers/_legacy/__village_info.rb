module Mcl
  Mcl.reloadable(:HMclVillageInfo)
  ## Village info by using server side NBT files
  # ONLY WORKS UP TO 1.13
  # !villages
  # !villages stat
  # !villages doorbook
  # !villages playerbook
  # !villages indicate
  # !villages indicate purge                         # remove all indicators
  # !villages indicate center [block=diamond]        # indicate center
  # !villages indicate doors  [block=emerald_block]  # indicate valid doors
  # !villages indicate radius [block=redstone_block] # indicate radius
  # !villages indicate spherical [block=glass]       # indicate radius
  class HMclVillageInfo < Handler
    def setup
      register_villages(:admin)
    end

    def register_villages acl_level
      register_command [:villages], desc: "examines Village.dat and allows accessing these data", acl: acl_level do |player, args|
        opts = {
          world: server.world,
          dimension: nil,
          save_world: false,
          vindex: nil,
        }

        opt = OptionParser.new
        opt.on("-d", "--dimension DIM", String) {|v| opts[:dimension] = v }
        opt.on("-w", "--world WORLD", String) {|v| opts[:world] = v }
        opt.on("-s", "--save-world") { opts[:save_world] = true }
        opt.on("-v", "--village NUM", Integer) {|v| opts[:vindex] = v.to_i }
        opt.parse!(args)

        if opts[:save_world]
          server.invoke "save-all"
          sleep 0.25
        end

        file = case opts[:dimension]
          when "nether" then "data/villages_nether.dat"
          when "end" then "data/villages_end.dat"
          else "data/villages.dat"
        end

        # check file
        if !File.exist?(nbt_path(file, opts[:world]))
          tellm(player, {text: "couldn't find ", color: "red"}, {text: file, color: "aqua"}, {text: " for world ", color: "red"}, {text: opts[:world], color: "aqua"}, {text: "!", color: "red"})
          throw :handler_exit
        end

        villages = nbt_load(file, opts[:world])[1]["data"]["Villages"]

        case args.first.to_s.to_sym
          when :playerbook then do_playerbook(player, villages, opts, args)
          when :doorbook then do_doorbook(player, villages, opts, args)
          when :indicate then do_indicate(player, villages, opts, args)
          else do_stat(player, villages, opts, args)
        end
      end

      def do_indicate player, villages, opts = {}, args = []
        villages.each_with_index do |village, i|
          next if opts[:vindex] && opts[:vindex] != i + 1
          center = [village["CX"], village["CY"], village["CZ"]]
          if args.delete("purge")
            purged = true
            server.invoke %{/kill @e[type=armor_stand,tag=villager_info_marker]}
          end

          case args[1]
          when "center"
            block = args[2].presence || "emerald_block"
            spawn_indicator(center, block: block)
          when "doors"
            block = args[2].presence || "emerald_block"
            village["Doors"].each do |d|
              spawn_indicator([d["X"], d["Y"], d["Z"]], block: block)
            end
          when "radius"
            block = args[2].presence || "redstone_block"
            village["Radius"].times do |i| # for each radius
              next if i == 0
              3.times do |xyz| # in all axis directions
                nc = [center[0], center[1], center[2]]
                2.times do |posneg| # +/- axis
                  nc[xyz] = posneg.zero? ? nc[xyz] + i : nc[xyz] - (i*2)
                  spawn_indicator(nc, block: block)
                end
              end
            end
          when "spherical"
            block = args[2].presence || "glass"
            make_sphere(village["Radius"]).each do |v|
              spawn_indicator([v[0] + center[0], v[1] + center[1], v[2] + center[2]], block: block)
            end
          else
            tellm(player, l("Add 2nd argument, available: purge center doors radius spherical", "yellow")) unless purged
          end
        end
      end

      def do_playerbook player, villages, opts = {}, args = []
        if !opts[:vindex]
          tellm(player, {text: "village must be specified!", color: "red"})
          throw :handler_exit
        end

        village = villages[opts[:vindex] - 1]

        unless village
          tellm(player, {text: "invalid village specified!", color: "red"})
          throw :handler_exit
        end

        if village["Players"].empty?
          tellm(player, {text: "this village has no player data!", color: "yellow"})
          throw :handler_exit
        end

        pages = []

        x, bs = 0, []
        village["Players"].each_with_index do |p, i|
          if prec = pman.by_uuid(p["UUID"])
            s = "#{prec.nickname.truncate(19)}"
            h = "#{prec.nickname} – #{prec.uuid}"
          else
            s = "#{prec.uuid.truncate(19)}"
            h = "User not known to MCL – #{prec.uuid}"
          end
          [{"S"=>-1, "UUID"=>"93cc6d87-776e-459f-b40a-530a5670c07c"}]

          x += s.to_s.length > 22 ? 2 : 1
          if p["S"] == 0
            ss = [l("0", "aqua", hover: "Neutral (-30..15)")]
          elsif p["S"] < -14
            ss = [l("#{p["S"]}", "red", hover: "Hostile (-30..15)")]
          elsif p["S"] < 0
            ss = [l("#{p["S"]}", "gold", hover: "Negative (-30..15)")]
          elsif p["S"] > 0
            ss = [l("#{p["S"]}", "green", hover: "Positive (-30..15)")]
          end
          ss << l(" ")
          ss << l("#{s}\n", "black", hover: h)
          bs << ss.to_json[1..-2]
          if x >= 13
            pages << bs.join("\n")
            x, bs = 0, []
          end
        end
        pages << bs.join("\n")

        server.invoke book(player, "Village ##{village["Players"].count} Players", pages, author: "MCL-VillageInfo")
      end

      def do_doorbook player, villages, opts = {}, args = []
        if !opts[:vindex]
          tellm(player, {text: "village must be specified!", color: "red"})
          throw :handler_exit
        end

        village = villages[opts[:vindex] - 1]

        unless village
          tellm(player, {text: "invalid village specified!", color: "red"})
          throw :handler_exit
        end

        pages = []
        doors = village["Doors"]

        x, bs = 0, []
        doors.each_with_index do |d, i|
          dc = [d["X"], d["Y"], d["Z"]]
          s = "Door ##{i+1}: #{dc.join(" ")}"
          x += s.to_s.length > 22 ? 2 : 1
          bs << l("#{s}\n", hover: "teleport to door ##{i+1} #{dc.join(" ")}", command: "!tp #{dc.join(" ")}").to_json
          if x >= 13
            pages << bs.join("\n")
            x, bs = 0, []
          end
        end
        pages << bs.join("\n")

        server.invoke book(player, "Village ##{doors.count} Doors", pages, author: "MCL-VillageInfo")
      end

      def do_stat player, villages, opts = {}, args = []
        if !villages.any?
          return tellm(player, l("no village found", "red"))
        end
        villages.each_with_index do |village, i|
          next if opts[:vindex] && opts[:vindex] != i + 1
          center = [village["CX"], village["CY"], village["CZ"]]

          tellm(player,
            l("found village ", "yellow"),
            l("##{i+1}", "light_purple", hover: "only show village ##{i+1}", command: "!villages #{build_command_string(opts.merge(vindex: i+1), args)}"),
          )

          # center / radius
          tellm(player,
            l("  Center: ", "aqua"),
            l(center.join(" "), "green", hover: "teleport to #{center.join(" ")}", command: "!tp #{center.join(" ")}"),
            l(" // ", "gray"),
            l("Radius: ", "aqua"),
            l("#{village["Radius"]}", "green", hover: "spherical around center block"),
          )

          # doors
          tellm(player,
            l("  Doors: ", :aqua),
            l("#{village["Doors"].length} ", :green),
            l("(book)", :gray, hover: "give book with door list", command: "!villages #{build_command_string(opts.merge(vindex: i+1), ["doorbook"])}"),
          )

          # population
          pcap = (village["Doors"].length * 0.35).floor.to_i
          tellm(player,
            l("  Population: ", :aqua),
            l("#{village["PopSize"]}", :green, hover: "villagers within boundaries"),
            l(" / ", "gray"),
            l("#{pcap} ", :green, hover: "villager cap based on valid doors"),
          )

          # golems
          vcap = ((village["PopSize"].to_d - 9.1) / 10).floor + 1
          dcap = ((pcap.to_d - 9.1) / 10).floor + 1
          tellm(player,
            l("  Golems: ", :aqua),
            l("#{village["Golems"]}", :green, hover: "golems within boundaries (incl. player generated ones)"),
            l(" / ", "gray"),
            l("#{vcap}", :green, hover: "golem cap based on villagers within boundaries"),
            l(" / ", "gray"),
            l("#{dcap}", :green, hover: "golem cap based on population cap"),
          )

          # players
          tellm(player,
            l("  Players: ", :aqua),
            l("#{village["Players"].length} ", :green, hover: "players that have reputation in this village"),
            l("(book)", :gray, hover: "give book with player list", command: "!villages #{build_command_string(opts.merge(vindex: i+1), ["playerbook"])}"),
          )
        end
      end
    end



    module Helper
      def tellm p, *msg
        trawm(p, title("VI"), *msg)
      end

      def ll input
        case input
          when Hash then input
          when Array then input.map{|i| l(i) }
          when String then l(input)
          else raise(ArgumentError, "unknown input type #{input.class}")
        end
      end

      def l str, color_or_opts = nil, opts = {}
        if color_or_opts.is_a?(Hash)
          opts = color_or_opts
        else
          opts[:color] = color_or_opts
        end
        {}.tap do |r|
          r[:text] = str
          r[:color] = opts[:color] if opts[:color]
          if hover = opts.delete(:hover)
            r[:hoverEvent] = { action: "show_text", value: ll(hover) }
          end
          if cmd = opts.delete(:command)
            r[:clickEvent] = { action: "run_command", value: cmd }
          end
          if url = opts.delete(:url)
            r[:clickEvent] = { action: "open_url", value: url }
          end
        end
      end

      def nbt_path file, world = nil
        "#{server.world_root(world)}/#{file}"
      end

      def nbt_load file, world = nil
        NBTFile.load(File.read(nbt_path(file, world)))
      end

      def build_command_string opts, args
        [].tap do |r|
          r << "-d #{opts[:dimension]}" if opts[:dimension]
          r << "-s" if opts[:dimension]
          r << "-w #{opts[:world]}" if opts[:world] != server.world
          r << "-v #{opts[:vindex]}" if opts[:vindex]
          r << args.join(" ")
        end.join(" ")
      end

      def spawn_indicator coord, opts = {}
        tags = opts.delete(:tags) || []
        tags << "villager_info_marker"
        stags = tags.map(&:inspect).join(",")
        server.invoke %{/summon armor_stand #{as_coord(coord) * " "} {Fire:32767,Marker:1b,Invulnerable:1b,NoGravity:1b,Invisible:1b,Tags:[#{stags}],ArmorItems:[{},{},{},{id:"#{opts[:block]}",Count:1b}]}}
      end

      def as_coord *coord
        coord = coord.flatten
        [coord[0], coord[1] - 1.2, coord[2]]
      end

      def length_sq *coord
        coord = coord.flatten
        coord[0] * coord[0] + coord[1] * coord[1] + coord[2] * coord[2]
      end

      def make_sphere radius
        [].tap do |res|
          radius += 0.5 # to make calc smooth

          inv_radius_x = 1.to_d / radius
          inv_radius_y = 1.to_d / radius
          inv_radius_z = 1.to_d / radius

          ceil_radius_x = radius.ceil.to_i;
          ceil_radius_y = radius.ceil.to_i;
          ceil_radius_z = radius.ceil.to_i;

          next_xn = 0
          catch :for_x do
            ceil_radius_x.times do |x|
              xn = next_xn
              next_xn = (x + 1) * inv_radius_x
              next_yn = 0
              catch :for_y do
                ceil_radius_y.times do |y|
                  yn = next_yn
                  next_yn = (y + 1) * inv_radius_y
                  next_zn = 0
                  catch :for_z do
                    ceil_radius_z.times do |z|
                      zn = next_zn
                      next_zn = (z + 1) * inv_radius_z

                      distance_sq = length_sq(xn, yn, zn)
                      if distance_sq > 1
                        if z.zero?
                          throw :for_x if y.zero?
                          throw :for_y
                        end
                        throw :for_z
                      end

                      # we want it hollow
                      next if length_sq(next_xn, yn, zn) <= 1 && length_sq(xn, next_yn, zn) <= 1 && length_sq(xn, yn, next_zn) <= 1

                      res << [x, y, z]
                      res << [-x, y, z]
                      res << [x, -y, z]
                      res << [x, y, -z]
                      res << [-x, -y, z]
                      res << [x, -y, -z]
                      res << [-x, y, -z]
                      res << [-x, -y, -z]
                    end # Z
                  end # catch Z
                end # Y
              end # catch Y
            end # X
          end # catch X
        end # tap
      end # def
    end
    include Helper
  end
end
