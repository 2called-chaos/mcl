module Mcl
  Mcl.reloadable(:HMclSchematicBuilder)
  ## World Edit light (it's almost as good, not)
  # !schebu book
  # !schebu add <name> <url>
  # !schebu list [filter]
  # !schebu load <name>
  # !schebu rotate <±90deg>
  # !schebu air <t/f>
  # !schebu pos <x> <y> <z>
  # !schebu ipos [indicator]
  # !schebu status
  # !schebu reset
  # !schebu build [clear]
  class HMclSchematicBuilder < Handler
    def setup
      register_schebu(:builder, {
        book: :builder,
        add: :mod,
        list: :builder,
        load: :builder,
        rotate: :builder,
        air: :builder,
        pos: :builder,
        ipos: :builder,
        status: :builder,
        reset: :builder,
        build: :builder,
        cancel: :builder,
      })
    end

    def register_schebu acl_level, acl_levels = {}
      register_command :schebu, desc: "Schematic Builder (more info with !schebu)", acl: acl_level do |player, args|
        case args[0]
        when "book", "add", "list", "load", "rotate", "air", "ipos", "pos", "status", "reset", "build", "cancel"
          acl_verify(player, acl_levels[args[0].to_sym])
          send("com_#{args[0]}", player, args[1..-1])
        else
          tellm(player, {text: "book", color: "gold"}, {text: " gives you a book with more info", color: "reset"})
          # tellm(player, {text: "add <name> <url>", color: "gold"}, {text: " add a remote schematic", color: "reset"})
          tellm(player, {text: "list [filter]", color: "gold"}, {text: " list available schematics", color: "reset"})
          tellm(player, {text: "load <name>", color: "gold"}, {text: " load schematic from library", color: "reset"})
          tellm(player, {text: "rotate <±90deg>", color: "gold"}, {text: " rotate the schematic", color: "reset"})
          tellm(player, {text: "air <t/f>", color: "gold"}, {text: " copy air yes or no", color: "reset"})
          tellm(player, {text: "pos <x> <y> <z>", color: "gold"}, {text: " set build start position", color: "reset"})
          tellm(player, {text: "ipos [indicator]", color: "gold"}, {text: " indicate build area", color: "reset"})
          tellm(player, {text: "status", color: "gold"}, {text: " show info about the current build settings", color: "reset"})
          tellm(player, {text: "reset", color: "gold"}, {text: " clear your current build settings", color: "reset"})
          tellm(player, {text: "build", color: "gold"}, {text: " parse schematic and build it", color: "reset"})
        end
      end
    end


    module Commands
      def com_book player, args
        pages = []
        pages << %Q{
          {text:"ScheBu\\n","color":"red","bold":"true"}
          {text:"Schematic Builder\\n","color":"red"}
          {text:"-------------------\\n"}
          {text:"P2: Important Notes\\n"}
          {text:"P4: Process of building\\n"}
          {text:"P+: Command help\\n"}
        }.strip
        pages << %Q{
          {text:"Important Notes\\n","color":"red","bold":"true"}
          {text:"-----------------\\n"}
          {text:"ScheBu will read the schematic, convert it to a block matrix and send a setblock command to the server console, FOR EACH BLOCK! This is obviously very imperformant and you shouldn't use that for large schematics."}
        }.strip
        pages << %Q{
          {text:"Important Notes\\n","color":"red","bold":"true"}
          {text:"-----------------\\n"}
          {text:"MCL, which is the parent of ScheBu, will be unresponsive during builds."}
        }.strip
        pages << %Q{
          {text:"Process\\n","color":"red","bold":"true"}
          {text:"-----------------\\n"}
          {text:"When you load a schematic, we just check if it exists and contains valid NBT data. We also extract the dimensions of the schematic. All settings you change (rotation, etc.) will not be calculated until you issue the build command."}
        }.strip
        pages << %Q{
          {text:"Process\\n","color":"red","bold":"true"}
          {text:"-----------------\\n"}
          {text:"Upon build the schematic content will be loaded, converted, processed and then build. You cannot build 2 things at the same time!"}
        }.strip

        $mcl.server.invoke book(player, "ScheBu Infosheet", pages, author: "ScheBu")
      end

      def com_add player, args
        tellm(player, {text: "sorry, not yet implemented :(", color: "red"})
      end

      def com_list player, args
        sfiles = available_schematics

        # filter
        if args[0] && args[0].to_i == 0
          sfiles = sfiles.select{|c| c.to_s =~ /#{args[0]}/ }
          page = 1
          page = (args[1] || 1).to_i
        else
          page = (args[0] || 1).to_i
        end

        # paginate
        page_contents = sfiles.in_groups_of(7, false)
        pages = (sfiles.count/7.0).ceil

        if sfiles.any?
          tellm(player, {text: "--- Showing page #{page}/#{pages} (#{sfiles.count} schematics) ---", color: "aqua"})
          page_contents[page-1].each {|schem| tellm(player, {text: schem, color: "reset", clickEvent: {action: "suggest_command", value: "!schebu load #{schem}"}}) }
          tellm(player, {text: "Use ", color: "aqua"}, {text: "!schembu list [str] <page>", color: "light_purple"}, {text: " to [filter] and/or <paginate>.", color: "aqua"})
        else
          tellm(player, {text: "No schematics found for that filter/page!", color: "red"})
        end
      end

      def com_load player, args
        pram, sname = memory(player), args[0]

        if pram[:current_schematic] && pram[:current_schematic][:building]
          tellm(player, {text: "Build in progress!", color: "red"})
        elsif !sname
          tellm(player, {text: "!schebu load <name>", color: "red"})
        elsif !available_schematics.include?(sname)
          tellm(player, {text: "Schematic couldn't be found!", color: "red"})
        else
          begin
            schematic = load_schematic(sname)
            new_schematic = {}.tap do |r|
              r[:building] = false
              r[:name] = sname
              r[:x] = schematic["Width"].to_i
              r[:y] = schematic["Height"].to_i
              r[:z] = schematic["Length"].to_i
              r[:dimensions] = [r[:x], r[:y], r[:z]]
              r[:size] = r[:dimensions].inject(:*)
              r[:rotation] = 0
              r[:air] = true
              r[:pos] = pram[:current_schematic].try(:[], :pos)
              r[:blocks_placed] = 0
              r[:blocks_ignored] = 0
              r[:blocks_processed] = 0
            end
            pram[:current_schematic] = new_schematic
            tellm(player, {text: "Schematic loaded ", color: "green"}, {text: "(#{new_schematic[:dimensions].join("x")} = #{new_schematic[:size]})", color: "reset"})
          rescue
            tellm(player, {text: "Error loading schematic!", color: "red"})
            tellm(player, {text: "#{$!.message}", color: "red"})
          end
        end
      end

      def com_air player, args
        unless require_schematic(player)
          pram = memory(player)
          if args[0]
            pram[:current_schematic][:air] = strbool(args[0])
          end
          tellm(player, {text: "Air blocks will be ", color: "yellow"}, (pram[:current_schematic][:air] ? {text: "COPIED", color: "green"} : {text: "IGNORED", color: "red"}))
        end
      end

      def com_reset player, args
        memory(player).delete(:current_schematic)
        tellm(player, {text: "Build settings cleared!", color: "green"})
      end

      def com_rotate player, args
        unless require_schematic(player)
          pram = memory(player)
          deg = args[0].to_i
          if deg != 0
            if deg % 90 == 0
              pram[:current_schematic][:rotation] = (pram[:current_schematic][:rotation] + deg) % 360
              tellm(player, {text: "Schematic rotation is #{pram[:current_schematic][:rotation]} degrees (NOT IMPLEMENTED)", color: "yellow"})
            else
              tellm(player, {text: "Rotation must be divisible by 90", color: "red"})
            end
          else
            tellm(player, {text: "Schematic rotation is #{pram[:current_schematic][:rotation]} degrees (NOT IMPLEMENTED)", color: "yellow"})
          end
        end
      end

      def com_pos player, args
        unless require_schematic(player)
          pram = memory(player)
          if args.count == 3 || (args.count == 1 && args.first == "~")
            detect_relative_coordinate(player, args) do |npos|
              pram[:current_schematic][:pos] = npos
              tellm(player, {text: "Insertion point ", color: "yellow"}, {text: npos.join(" "), color: "green"})
            end
          elsif args.count > 0
            tellm(player, {text: "!schebu pos <x> <y> <z>", color: "red"})
          else
            pos = pram[:current_schematic][:pos]
            tellm(player, {text: "Insertion point ", color: "yellow"}, (pos ? {text: pos.join(" "), color: "green"} : {text: "unset", color: "gray", italic: true}))
          end
        end
      end

      def com_ipos player, args
        unless require_schematic(player, false)
          pram  = memory(player)
          schem = pram[:current_schematic]

          if p1 = schem[:pos]
            p2 = shift_coords(p1, schem[:dimensions])
            case args[1]
              when "o", "outline" then tellm(player, {text: "sorry, not yet implemented :(", color: "red"})
              when "c", "corners" then selection_vertices(p1, p2).values.uniq.each{|coord| indicate_coord(p, coord, args[0]) }
              else indicate_coord(player, p1, args[0]) ; indicate_coord(player, p2, args[0])
            end
          else
            tellm(player, {text: "Insertion point required!", color: "red"})
          end
        end
      end

      def com_cancel player, args
        unless require_schematic(player, false)
          pram  = memory(player)
          schem = pram[:current_schematic]
          if schem[:building]
            schem[:build_canceled] = true
            tellm(player, {text: "Canceling build...", color: "yellow"})
          else
            tellm(player, {text: "No build active!", color: "yellow"})
          end
        end
      end

      def com_status player, args
        pram  = memory(player)
        schem = pram[:current_schematic]
        unless require_schematic(player, false)
          tellm(player, {text: "Name: ", color: "yellow"}, {text: schem[:name], color: "aqua"})
          tellm(player, {text: "Size: ", color: "yellow"}, {text: "#{schem[:dimensions].join("x")} (#{schem[:size]})", color: "aqua"})
          tellm(player, {text: "Rotation: ", color: "yellow"}, {text: "#{schem[:rotation]} degrees", color: "aqua"})
          tellm(player, {text: "Air: ", color: "yellow"}, (schem[:air] ? {text: "COPY", color: "green"} : {text: "IGNORE", color: "red"}))
          if schem[:pos]
            tellm(player,
              {text: "Ins.Point: ", color: "yellow"},
              {text: schem[:pos].join(" "), color: "aqua"},
              {text: " => ", color: "yellow"},
              {text: shift_coords(schem[:pos], schem[:dimensions]).join(" "), color: "aqua"}
            )
          else
            tellm(player, {text: "Ins.Point: ", color: "yellow"}, {text: "unset", color: "gray", italic: true})
          end
          if schem[:building]
            size = schem[:build_size]
            proc = schem[:blocks_processed]
            perc = ((proc / size.to_f) * 100).round(2)
            tellm(player, {text: "BUILDING: ", color: "green"}, {text: proc, color: "yellow"}, spacer, {text: size, color: "gold"}, {text: " (#{perc}%)", color: "reset"})
          end
        end
      end

      def com_build player, args
        unless require_schematic(player)
          pram  = memory(player)
          schem = pram[:current_schematic]

          # clear feature
          if args[0] == "clear"
            coord_32k_units(schem[:pos], shift_coords(schem[:pos], schem[:dimensions])) do |p1, p2|
              $mcl.server.invoke %{/fill #{p1.join(" ")} #{p2.join(" ")} air}
            end
          else
            if !schem[:pos]
              tellm(player, {text: "Insertion point required!", color: "red"})
            else
              async do
                realtime = false
                begin
                  build_reset(schem, true)
                  # Prepare build
                  $mcl.sync do
                    tellm(player, {text: "Preparing build...", color: "yellow"})
                    if schem[:air]
                      coord_32k_units(schem[:pos], shift_coords(schem[:pos], schem[:dimensions])) do |p1, p2|
                        $mcl.server.invoke %{/fill #{p1.join(" ")} #{p2.join(" ")} air}
                      end
                    end
                  end
                  schemdat = load_schematic_as_bo2s(schem[:name])[:data]

                  # Announce build
                  $mcl.sync do
                    schem[:build_size] = schemdat.count
                    tellm(player,
                      {text: "Build started (stop with ", color: "yellow"},
                      {
                        text: "!schebu cancel",
                        color: "aqua",
                        underlined: true,
                        clickEvent: {action: "suggest_command", value: "!schebu cancel"}
                      },
                      {text: ")", color: "yellow"}
                    )
                  end

                  # Actual build
                  realtime = Benchmark.realtime do
                    until schemdat.empty?
                      raise "canceled" if schem[:build_canceled]
                      raise "MCL is shutting down" if Thread.current[:mcl_halting]
                      raise "IPC down" unless $mcl.server.alive?

                      # place(!) 123 blocks and then Thread.pass
                      $mcl.sync do
                        placed = 0

                        while placed <= 123 && !schemdat.empty?
                          ci = schemdat.shift
                          next if ci.blank?
                          entry = bo2s_map(ci)

                          if !schem[:air] && entry[:block_id] == 0 # essentially unused by now
                            schem[:blocks_ignored] += 1
                          else
                            spos = shift_coords(schem[:pos], entry[:coord])
                            $mcl.server.invoke %{/setblock #{spos.join(" ")} #{entry[:tile_name]} #{entry[:data_value]}}
                            placed += 1
                            schem[:blocks_placed] += 1
                            sleep 3 if schem[:blocks_placed] % 2500 == 0
                          end
                          schem[:blocks_processed] += 1
                        end
                      end
                      sleep 0.0001
                      Thread.pass
                    end
                  end
                  $mcl.sync do
                    # tellm(player, {text: "#{schem[:blocks_placed]} placed, #{schem[:blocks_ignored]} ignored", color: "yellow"})
                    tellm(player, {text: "#{schem[:blocks_placed]} placed, #{schem[:size] - schem[:blocks_placed]} ignored", color: "yellow"})
                    tellm(player, {text: "Build finished in #{realtime.round(2)}s (#{(schem[:build_size] / realtime).round(0)} blocks/s)!", color: "green"})
                  end
                rescue
                  $mcl.sync do
                    tellm(player, {text: "#{schem[:blocks_placed]} placed, #{schem[:size] - schem[:blocks_placed]} ignored", color: "yellow"})
                    tellm(player, {text: "Build failed (#{$!.message})!", color: "red"})
                  end
                ensure
                  build_reset(schem, false)
                end
              end
            end
          end
        end
      end
    end
    include Commands

    module Helper
      def memory player
        pmemo(player, :schematic_builder)
      end

      def spacer
        {text: " / ", color: "reset"}
      end

      def tellm player, *msg
        trawt(player, "Schebu", *msg)
      end

      def available_schematics
        Dir["#{$mcl.server.root}/schematics/*.schematic"].map{|f| File.basename(f, ".schematic") }
      end

      def load_schematic_as_bo2s name
        file = "#{$mcl.server.root}/schematics/#{name}.schematic"
        SchematicBo2sConverter.convert(File.open(file, "rb"))
      end

      def load_schematic name
        file = "#{$mcl.server.root}/schematics/#{name}.schematic"
        SchematicBo2sConverter.open(File.open(file, "rb"))
      end

      def build_reset schem, building
        $mcl.sync do
          schem[:building] = building
          schem[:build_canceled] = false
          schem[:blocks_placed] = 0
          schem[:blocks_ignored] = 0
          schem[:blocks_processed] = 0
          schem[:build_size] = schem[:size]
        end
      end

      def bo2s_map entry
        coord, blockdata = entry.split(":")
        bid, bval = blockdata.split(".").map(&:to_i)
        x, z, y = coord.split(",").map(&:to_i)

        {
          coord: [x, y, z],
          data_value: bval,
          tile_id: bid,
          tile_name: Id2mcn.conv(bid),
        }
      end

      def require_schematic player, req_nobuild = true
        pram = memory(player)
        if pram[:current_schematic]
          if req_nobuild && pram[:current_schematic][:building]
            tellm(player,
              {text: "Build in progress (stop with ", color: "red"},
              {
                text: "!schebu cancel",
                color: "aqua",
                underlined: true,
                clickEvent: {action: "suggest_command", value: "!schebu cancel"}
              },
              {text: ")", color: "red"}
            )
            return true
          else
            return false
          end
        else
          tellm(player, {text: "No schematic loaded yet!", color: "red"})
          return true
        end
      end
    end
    include Helper
  end
end
