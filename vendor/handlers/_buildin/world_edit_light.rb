module Mcl
  Mcl.reloadable(:HMclWorldEditLight)
  ## World Edit light (it's almost as good, not)
  # !!sel [clear]
  # !!isel [mode] [outline]
  # !!set <block> [damage_value] [xargs]
  # !!outline <block> [damage_value] [xargs]
  # !!hollow <block> [damage_value] [xargs]
  # !!fill <block> [damage_value] [xargs]
  # !!replace <IS:TileName> [IS:dataValue] > <SHOULD:TileName> [SHOULD:dataValue]
  # !!insert [-f] <x> <y> <z> [mode] [tilename]
  # !!stack <direction> [amount] [shift_selection] [masked|filtered <TileName>]
  # !!move <direction> [amount]
  # !!pos <x> <y> <z>
  # !!pos <x1> <y1> <z1> <x2> <y2> <z2>
  # !!pos1 <x> <y> <z>
  # !!pos2 <x> <y> <z>
  # !!spos <xD> <yD> <zD>
  # !!spos1 <xD> <yD> <zD>
  # !!spos2 <xD> <yD> <zD>
  # !!ipos [mode]
  # !!ipos1 [mode]
  # !!ipos2 [mode]
  # !!facing
  class HMclWorldEditLight < Handler
    def setup
      register_sel(:builder)
      register_isel(:builder)
      register_set(:builder)
      register_outline(:builder)
      register_hollow(:builder)
      register_fill(:builder)
      register_replace(:builder)
      register_insert(:builder)
      register_stack(:builder)
      register_move(:builder)
      register_pos(:builder)
      register_spos(:builder)
      register_ipos(:builder)
      register_facing(:builder)
    end

    def register_sel acl_level
      register_command "!sel", desc: "shows or clears (!!sel clear) current selection", acl: acl_level do |player, args|
        args[0] == "clear" ? clear_selection(player) : current_selection(player)
      end
    end

    def register_isel acl_level
      register_command "!isel", desc: "indicate current selection with particles", acl: acl_level do |player, args|
        indicate_selection(player, args)
      end
    end

    def register_set acl_level
      register_command "!set", desc: "fills selection with given block", acl: acl_level do |player, args|
        pram = memory(player)
        unless require_selection(player)
          if args.count > 0
            block = args.shift
            bval  = args.shift || "0" unless args[0].to_s.start_with?("{", "[")
            coord_32k_units(pram[:pos1], pram[:pos2], player) do |p1, p2|
              $mcl.server.invoke do |cmd|
                cmd.default %{/execute #{player} ~ ~ ~ fill #{p1.join(" ")} #{p2.join(" ")} #{block} #{bval} replace #{args.join(" ")}}.strip
                cmd.since "1.13", "17w45a", %{/execute as #{player} at #{player} run fill #{p1.join(" ")} #{p2.join(" ")} #{[block, *args].join(" ")}}.strip
              end
            end
          else
            version_switch do |v|
              v.default { tellm(player, {text: "!!set <block> [dataValue] [dataTag]", color: "yellow"}) }
              v.since("1.13", "17w45a") { tellm(player, {text: "!!set <block>[data]{nbt}", color: "yellow"}) }
            end
          end
        end
      end
    end

    def register_outline acl_level
      register_command "!outline", desc: "outlines selection with given block", acl: acl_level do |player, args|
        pram = memory(player)
        unless require_selection(player)
          version_switch do |v|
            v.default do
              if args.count > 0
                $mcl.server.invoke %{/execute #{player} ~ ~ ~ fill #{pram[:pos1].join(" ")} #{pram[:pos2].join(" ")} #{args.shift} #{args.shift || "0"} outline #{args.join(" ")}}
              else
                tellm(player, {text: "!!outline <block> [dataValue] [dataTag]", color: "yellow"})
              end
            end
            v.since "1.13", "17w45a" do
              if args.count > 0
                $mcl.server.invoke(%{/execute as #{player} at #{player} run fill #{pram[:pos1].join(" ")} #{pram[:pos2].join(" ")} #{args.join(" ")}}.strip << " outline")
              else
                tellm(player, {text: "!!outline <block>[data]{nbt}", color: "yellow"})
              end
            end
          end
        end
      end
    end

    def register_hollow acl_level
      register_command "!hollow", desc: "hollow selection with given block", acl: acl_level do |player, args|
        pram = memory(player)
        unless require_selection(player)
          version_switch do |v|
            v.default do
              if args.count > 0
                $mcl.server.invoke %{/execute #{player} ~ ~ ~ fill #{pram[:pos1].join(" ")} #{pram[:pos2].join(" ")} #{args.shift} #{args.shift || "0"} hollow #{args.join(" ")}}
              else
                tellm(player, {text: "!!hollow <block> [dataValue] [dataTag]", color: "yellow"})
              end
            end
            v.since "1.13", "17w45a" do
              if args.count > 0
                $mcl.server.invoke(%{/execute as #{player} at #{player} run fill #{pram[:pos1].join(" ")} #{pram[:pos2].join(" ")} #{args.join(" ")}}.strip << " hollow")
              else
                tellm(player, {text: "!!hollow <block>[data]{nbt}", color: "yellow"})
              end
            end
          end
        end
      end
    end

    def register_fill acl_level
      register_command "!fill", desc: "fill air blocks in selection with given block", acl: acl_level do |player, args|
        pram = memory(player)
        unless require_selection(player)
          version_switch do |v|
            v.default do
              if args.count > 0
                block = args.shift
                bval  = args.shift || "0"
                coord_32k_units(pram[:pos1], pram[:pos2], player) do |p1, p2|
                  $mcl.server.invoke %{/execute #{player} ~ ~ ~ fill #{p1.join(" ")} #{p2.join(" ")} #{block} #{bval} keep #{args.join(" ")}}
                end
              else
                tellm(player, {text: "!!fill <TileName> [dataValue] [dataTag]", color: "yellow"})
              end
            end
            v.since "1.13", "17w45a" do
              if args.count > 0
                $mcl.server.invoke(%{/execute as #{player} at #{player} run fill #{pram[:pos1].join(" ")} #{pram[:pos2].join(" ")} #{args.join(" ")}}.strip << " keep")
              else
                tellm(player, {text: "!!fill <block>[data]{nbt}", color: "yellow"})
              end
            end
          end
        end
      end
    end

    def register_replace acl_level
      register_command "!replace", desc: "replace b1 in selection with given b2", acl: acl_level do |player, args|
        pram = memory(player)
        unless require_selection(player)
          is, should = args.join(" ").split(">").map(&:strip).reject(&:blank?)
          version_switch do |v|
            v.default do
              if is && should && is.is_a?(String) && should.is_a?(String)
                should = should.split(" ")
                coord_32k_units(pram[:pos1], pram[:pos2], player) do |p1, p2|
                  $mcl.server.invoke %{/execute #{player} ~ ~ ~ fill #{p1.join(" ")} #{p2.join(" ")} #{should[0]} #{should[1] || "1"} replace #{is}}
                end
              else
                tellm(player, {text: "!!replace <IS:TileName> [IS:dataValue] > <SHOULD:TileName> [SHOULD:dataValue]", color: "yellow"})
              end
            end
            v.since "1.13", "17w45a" do
              if is && should && is.is_a?(String) && should.is_a?(String)
                $mcl.server.invoke %{/execute as #{player} at #{player} run fill #{pram[:pos1].join(" ")} #{pram[:pos2].join(" ")} #{should} replace #{is}}
              else
                tellm(player, {text: "!!replace <IS:block>[data]{nbt} > <SHOULD:block>[data]{nbt}", color: "yellow"})
              end
            end
          end
        end
      end
    end

    def register_insert acl_level
      register_command "!insert", desc: "inserts selection at given coords", acl: acl_level do |player, args|
        insert_selection(player, args)
      end
    end

    def register_stack acl_level
      register_command "!stack", desc: "stacks selection", acl: acl_level do |player, args|
        stack_selection(player, args)
      end
    end

    def register_pos acl_level
      register_command "!pos", desc: "sets pos1&2 to given coords", acl: acl_level do |player, args|
        take_pos(nil, player, args)
      end

      [1,2].each do |num|
        register_command "!pos#{num}", desc: "sets pos#{num} to given coords", acl: acl_level do |player, args|
          take_pos(num, player, args)
        end
      end
    end

    def register_spos acl_level
      register_command "!spos", desc: "shifts pos1 and pos2 by given values", acl: acl_level do |player, args|
        shift_pos(nil, player, args)
      end
      [1,2].each do |num|
        register_command "!spos#{num}", desc: "shifts pos#{num} by given values", acl: acl_level do |player, args|
          shift_pos(num, player, args)
        end
      end
    end

    def register_move acl_level
      register_command "!move", desc: "move selection by its own volume", acl: acl_level do |player, args|
        if args.empty? || args.length > 2
          tellm(player, {text: "!!move <direction> [amount]", color: "aqua"})
        else
          xargs = args.dup
          xargs << "1" if xargs.length == 1
          xargs << "true"
          stack_selection(player, xargs, false)
        end
      end
    end

    def register_ipos acl_level
      register_command "!ipos", desc: "indicate pos1 and pos2 with particles", acl: acl_level do |player, args|
        if !memory(player)[:pos1] && !memory(player)[:pos2]
          tellm(player, {text:"pos1 & pos2 are unset!", color: "aqua"})
        else
          indicate_pos(nil, player, args)
        end
      end

      [1,2].each do |num|
        register_command "!ipos#{num}", desc: "indicate pos#{num} with particles", acl: acl_level do |player, args|
          if !memory(player)[:"pos#{num}"]
            tellm(player, {text:"pos#{num} is unset!", color: "aqua"})
          else
            indicate_pos(num, player, args)
          end
        end
      end
    end

    def register_facing acl_level
      register_command "!facing", desc: "(debug) shows your facing", acl: acl_level do |player, args|
        detect_player_rotation(player) do |(yaw, pitch)|
          facing = rotation2facing(yaw, pitch)
          tellm(player, { text: "Yaw: ", color: "yellow" }, { text: "%.2f" % yaw, color: "aqua"}, { text: " Pitch: ", color: "yellow" }, { text: "%.2f" % pitch, color: "aqua"})
          tellm(player, { text: "Facing: ", color: "yellow" }, { text: facing[0].join("-"), color: "aqua" }, { text: " / ", color: "yellow" }, { text: facing[1].join("-"), color: "aqua" })
          tellm(player, *facing2relatives(facing).map.with_index {|(k, f), i|
            [{ text: "#{k.to_s.capitalize}: ", color: "yellow" }, { text: f.to_s, color: "aqua"}].tap {|r| r.unshift({text: " "}) unless i.zero? }
          }.flatten)
        end
      end
    end


    module Commands
      def clear_selection player
        memory(player).delete(:pos1)
        memory(player).delete(:pos2)
        tellm(player, {text: "Selection cleared!", color: "green"})
      end

      def current_selection player, spos1 = true, spos2 = true, ssize = true, scorners = true
        pram = memory(player)

        # pos1
        if coords = pram[:pos1]
          pos1 = {text: coords.join(" "), color: "aqua"}
        else
          pos1 = {text: "unset", color: "gray", italic: true}
        end

        # pos2
        if coords = pram[:pos2]
          pos2 = {text: coords.join(" "), color: "dark_aqua"}
        else
          pos2 = {text: "unset", color: "gray", italic: true}
        end

        # selection size
        if pram[:pos1] && pram[:pos2]
          sel_size = {text: "#{selection_size(player)} blocks", color: "yellow", italic: true}
        else
          sel_size = {text: "???", color: "gray", italic: true}
        end

        # corners
        if pram[:pos1] && pram[:pos2]
          sel_corners = {text: "#{sel_explode_selection(player).values.uniq.count} corners", color: "gold", italic: true}
        else
          sel_corners = {text: "0 corners", color: "gray", italic: true}
        end

        a = []
        a << pos1 if spos1
        a << pos2 if spos2
        a << sel_size if ssize
        a << sel_corners if scorners

        tellm(player, *a.zip([spacer] * (a.length-1)).flatten.compact)
      end

      def sel_insert player, pos, *args
        pram = memory(player)
        $mcl.server.invoke do |cmd|
          cmd.default %{/execute #{player} ~ ~ ~ clone #{pram[:pos1].join(" ")} #{pram[:pos2].join(" ")} #{pos.join(" ")} #{args.join(" ")}}.strip
          cmd.since "1.13", "17w45a", %{/execute as #{player} at #{player} run clone #{pram[:pos1].join(" ")} #{pram[:pos2].join(" ")} #{pos.join(" ")} #{args.join(" ")}}.strip
        end
      end

      def insert_selection player, args
        chunks = args.map(&:strip).map{|i| i.to_s =~ /^-?[0-9]+$/ ? i.to_i : i}
        force = chunks.delete("-f") ? "force" : "normal"
        pram = memory(player)

        if chunks.count >= 3 || (chunks.count == 1 && chunks.first == "~")
          unless require_selection(player)
            tileid = chunks.pop if chunks.count == 5
            mode = chunks.pop if chunks.count == 4
            detect_relative_coordinate(player, chunks) do |npos|
              sel_insert(player, npos, [mode || "replace", force, tileid].compact)
              tellm(player, {text: "#{selection_size(player)} blocks involved", color: "gold"})
            end
          end
        else
          tellm(player, {text: "!!insert [-f] <x> <y> <z> [mode] [tile]", color: "aqua"})
        end
      end

      def take_pos num, player, args
        chunks = args.map(&:strip).map{|i| i.to_s =~ /^-?[0-9]+$/ ? i.to_i : i}
        pram = memory(player)

        if chunks.count == 0
          current_selection(player, num == 1 || num.nil?, num == 2 || num.nil?, false, false)
        elsif chunks.count == 1 && chunks.first == "~"
          detect_relative_coordinate(player, chunks) do |npos|
            if num.nil?
              pram[:pos1] = pram[:pos2] = npos
            else
              pram[:"pos#{num}"] = npos
            end
            current_selection(player)
          end
        elsif chunks.count == 3
          detect_relative_coordinate(player, chunks) do |npos|
            if num.nil?
              pram[:pos1] = pram[:pos2] = npos
            else
              pram[:"pos#{num}"] = npos
            end
            current_selection(player)
          end
        elsif chunks.count == 6 && num.nil?
          pram[:pos1] = chunks[0..2]
          pram[:pos2] = chunks[3..5]
          current_selection(player)
        else
          tellm(player, {text: "!!pos#{num} [x] [y] [z]#{" [x2] [y2] [z2]" if num.nil?}", color: "aqua"})
        end
      end

      def shift_pos num, player, args
        chunks = args.map(&:strip).map{|i| i.to_s =~ /^-?[0-9]+$/ ? i.to_i : i}
        pram = memory(player)

        if chunks.count == 0
          current_selection(player, num == 1 || num.nil?, num == 2 || num.nil?, false, false)
        elsif chunks.count == 3
          if num.nil?
            unless require_selection(player)
              pram[:pos1] = shift_coords(pram[:pos1], chunks)
              pram[:pos2] = shift_coords(pram[:pos2], chunks)
              current_selection(player)
            end
          else
            unless send(:"require_pos#{num}", player)
              pram[:"pos#{num}"] = shift_coords(pram[:"pos#{num}"], chunks)
              current_selection(player)
            end
          end
        elsif chunks.count == 6 && num.nil?
          unless require_selection(player)
            pram[:pos2] = shift_coords(pram[:pos1], chunks[0..2])
            pram[:pos2] = shift_coords(pram[:pos2], chunks[3..5])
            current_selection(player)
          end
        else
          tellm(player, {text: "!!spos#{num} [x] [y] [z]#{" [x2] [y2] [z2]" if num.nil?}", color: "aqua"})
        end
      end

      def stack_selection player, args, doclone = true
        chunks = args.map(&:strip).map{|i| i.to_s =~ /^-?[0-9]+$/ ? i.to_i : i}
        pram = memory(player)

        if chunks.count == 0
          tellm(player, {text: "!!stack <direction> [amount] [shift_selection] [masked|filtered <TileName>]", color: "aqua"})
        else
          unless require_selection(player)
            resolve_relative_direction(player, chunks[0]) do |dir|
              chunks[0] = dir
              _stack_selection(player, chunks, doclone)
            end
          end
        end
      end

      def _stack_selection player, chunks, doclone
        # vars
        direction = chunks.shift
        amount    = chunks.any? ? [chunks.shift.to_i, 1].max : 1
        shift_sel = chunks.any? ? strbool(chunks.shift) : false
        mode      = chunks.any? ? chunks.shift : "replace"
        tile_name = chunks.join(" ")

        # precheck
        if !pmemo(player)[:danger_mode] && amount > 50
          return require_danger_mode(player, "Stacking >50 times require danger mode to be enabled!")
        end

        # prepare
        cube                = sel_explode_selection(player)       # corners
        s1, s2              = cube[:xyz], cube[:XYZ]              # source selection
        p1, p2              = cube[:xyz], cube[:XYZ]              # frame selection
        seldim              = selection_dimensions(player)        # selection dimensions
        dir, axis, operator = coord_shifting_direction(direction) # coord shifting instructions

        # stack
        amount.times do
          # shift frame position
          p1 = shift_frame_selection(p1, seldim, axis, operator)
          p2 = shift_frame_selection(p2, seldim, axis, operator)

          # clone source => working
          $mcl.server.invoke do |cmd|
            cmd.default %{/execute #{player} ~ ~ ~ /clone #{s1.join(" ")} #{s2.join(" ")} #{p1.join(" ")} #{mode} normal #{tile_name}}
            cmd.since "1.13", "17w45a", %{/execute as #{player} at #{player} run clone #{s1.join(" ")} #{s2.join(" ")} #{p1.join(" ")} #{mode} normal #{tile_name}}.strip
          end if doclone

          # shift source position
          s1, s2 = p1, p2
        end

        # move selection
        if shift_sel
          pram[:pos1] = p1
          pram[:pos2] = p2
          current_selection(player, true, true, false, false)
        end
      end
    end
    include Commands

    module Helper
      def spacer
        {text: " / "}
      end

      def tellm player, *msg
        trawm(player, title("WEL"), *msg)
      end

      def selection_dimensions player
        coord_dimensions(memory(player)[:pos1], memory(player)[:pos2])
      end

      def selection_size player
        selection_dimensions(player).try(:inject, &:*)
      end

      def sel_explode_selection player
        selection_vertices(memory(player)[:pos1], memory(player)[:pos2])
      end

      def memory player
        pmemo(player, :world_edit_light)
      end

      def shift_frame_selection p, seldim, axis, operator
        case axis
          when :x then [p[0].send(operator, seldim[0]), p[1], p[2]]
          when :y then [p[0], p[1].send(operator, seldim[1]), p[2]]
          when :z then [p[0], p[1], p[2].send(operator, seldim[2])]
        end
      end

      def indicate_selection player, args
        pram = memory(player)
        unless require_selection(player)
          case args[1]
            when "o", "outline" then tellm(player, {text: "sorry, not yet implemented :(", color: "red"})
            when "m", "minmax" then indicate_coord(player, memory(player)[:pos1], args[0]) ; indicate_coord(player, memory(player)[:pos2], args[0])
            else sel_explode_selection(player).values.uniq.each{|coord| indicate_coord(p, coord, args[0]) }
          end
        end
      end

      def indicate_pos num, player, args
        indicate, pram = [], memory(player)
        [].tap do |indicate|
          indicate << pram[:pos1] if pram[:pos1] && (num.nil? || num == 1)
          indicate << pram[:pos2] if pram[:pos2] && (num.nil? || num == 2)
        end.each{|coord| indicate_coord(player, coord, args[0]) }
      end

      def require_pos1 player
        pram = memory(player)
        if pram[:pos1]
          return false
        else
          tellm(player, {text: "Pos1 required!", color: "red"})
          return true
        end
      end

      def require_pos2 player
        pram = memory(player)
        if pram[:pos2]
          return false
        else
          tellm(player, {text: "Pos2 required!", color: "red"})
          return true
        end
      end

      def require_selection player
        pram = memory(player)
        if pram[:pos1] && pram[:pos2]
          return false
        else
          tellm(player, {text: "Selection required!", color: "red"})
          return true
        end
      end
    end
    include Helper
  end
end
