module Mcl
  Mcl.reloadable(:HWorldEditLight)
  class HWorldEditLight < Handler
    def setup
      setup_parsers
      app.ram[:world_edit_light] ||= {}
    end

    def memory *arg
      if arg.count == 0
        app.ram[:world_edit_light]
      else
        app.ram[:world_edit_light][arg.first] ||= {}
        app.ram[:world_edit_light][arg.first]
      end
    end

    def setup_parsers
      reg_sel
      reg_pos
    end

    def title
      {text: "[WEL] ", color: "light_purple"}
    end

    def spacer
      {text: " / ", color: "reset"}
    end

    def tellm p, *msg
      trawm(p, *([title] + msg))
    end


    # ============
    # = Commands =
    # ============
    def reg_sel
      register_command "!sel", desc: "shows or clears (!!sel clear) current selection" do |h, p, c, t, a, o|
        a[0] == "clear" ? h.clear_selection(p) : h.current_selection(p)
      end

      register_command "!isel", desc: "indicate current selection with particles" do |h, p, c, t, a, o|
        h.indicate_selection(p, a)
      end

      register_command "!set", desc: "fills selection with given block" do |h, p, c, t, a, o|
        h.acl_verify(p)
        pram = h.memory(p)
        unless require_selection(p)
          if a.count > 0
            block = a.shift
            bval  = a.shift || "0"
            h.coord_32k_units(pram[:pos1], pram[:pos2], p) do |p1, p2|
              $mcl.server.invoke %{/execute #{p} ~ ~ ~ fill #{p1.join(" ")} #{p2.join(" ")} #{block} #{bval} replace #{a.join(" ")}}
            end
          else
            tellm(p, {text: "!!set <TileName> [dataValue] [dataTag]", color: "yellow"})
          end
        end
      end

      register_command "!outline", desc: "outlines selection with given block" do |h, p, c, t, a, o|
        h.acl_verify(p)
        pram = h.memory(p)
        unless require_selection(p)
          if a.count > 0
            $mcl.server.invoke %{/execute #{p} ~ ~ ~ fill #{pram[:pos1].join(" ")} #{pram[:pos2].join(" ")} #{a.shift} #{a.shift || "0"} outline #{a.join(" ")}}
          else
            tellm(p, {text: "!!outline <TileName> [dataValue] [dataTag]", color: "yellow"})
          end
        end
      end

      register_command "!hollow", desc: "hollow selection with given block" do |h, p, c, t, a, o|
        h.acl_verify(p)
        pram = h.memory(p)
        unless require_selection(p)
          if a.count > 0
            $mcl.server.invoke %{/execute #{p} ~ ~ ~ fill #{pram[:pos1].join(" ")} #{pram[:pos2].join(" ")} #{a.shift} #{a.shift || "0"} hollow #{a.join(" ")}}
          else
            tellm(p, {text: "!!hollow <TileName> [dataValue] [dataTag]", color: "yellow"})
          end
        end
      end

      register_command "!fill", desc: "fill air blocks in selection with given block" do |h, p, c, t, a, o|
        h.acl_verify(p)
        pram = h.memory(p)
        unless require_selection(p)
          if a.count > 0
            block = a.shift
            bval  = a.shift || "0"
            h.coord_32k_units(pram[:pos1], pram[:pos2], p) do |p1, p2|
              $mcl.server.invoke %{/execute #{p} ~ ~ ~ fill #{p1.join(" ")} #{p2.join(" ")} #{block} #{bval} keep #{a.join(" ")}}
            end
          else
            tellm(p, {text: "!!fill <TileName> [dataValue] [dataTag]", color: "yellow"})
          end
        end
      end

      register_command "!replace", desc: "replace b1 in selection with given b2" do |h, p, c, t, a, o|
        h.acl_verify(p)
        pram = h.memory(p)
        unless require_selection(p)
          is, should = a.join(" ").split(">").map(&:strip).reject(&:blank?)
          if is && should && is.is_a?(String) && should.is_a?(String)
            should = should.split(" ")
            h.coord_32k_units(pram[:pos1], pram[:pos2], p) do |p1, p2|
              $mcl.server.invoke %{/execute #{p} ~ ~ ~ fill #{p1.join(" ")} #{p2.join(" ")} #{should[0]} #{should[1] || "1"} replace #{is}}
            end
          else
            tellm(p, {text: "!!replace <IS:TileName> [IS:dataValue] > <SHOULD:TileName> [SHOULD:dataValue]", color: "yellow"})
          end
        end
      end

      register_command "!insert", desc: "inserts selection at given coords" do |h, p, c, t, a, o|
        h.acl_verify(p)
        h.insert_selection(p, a)
      end

      register_command "!stack", desc: "NotImplemented: stacks selection" do |h, p, c, t, a, o|
        h.acl_verify(p)
        h.stack_selection(p, a)
      end
    end

    def reg_pos
      register_command "!pos", desc: "sets pos1&2 to given coords" do |h, p, c, t, a, o|
        h.take_pos(nil, p, a)
      end

      register_command "!spos", desc: "shifts pos1 and pos2 by given values" do |h, p, c, t, a, o|
        h.shift_pos(nil, p, a)
      end

      register_command "!ipos", desc: "indicate pos1 and pos2 with particles" do |h, p, c, t, a, o|
        if !memory(p)[:pos1] && !memory(p)[:pos2]
          h.tellm(p, {text:"pos1 & pos2 are unset!", color: "aqua"})
        else
          h.indicate_pos(nil, p, a)
        end
      end

      [1,2].each do |num|
        register_command "!pos#{num}", desc: "sets pos#{num} to given coords" do |h, p, c, t, a, o|
          h.take_pos(num, p, a)
        end

        register_command "!spos#{num}", desc: "shifts pos#{num} by given values" do |h, p, c, t, a, o|
          h.shift_pos(num, p, a)
        end

        register_command "!ipos#{num}", desc: "indicate pos#{num} with particles" do |h, p, c, t, a, o|
          if !memory(p)[:"pos#{num}"]
            h.tellm(p, {text:"pos#{num} is unset!", color: "aqua"})
          else
            h.indicate_pos(num, p, a)
          end
        end
      end
    end



    # ===========
    # = Helpers =
    # ===========

    def selection_dimensions p
      pram = memory(p)
      coord_dimensions(pram[:pos1], pram[:pos2])
    end

    def selection_size p
      selection_dimensions(p).try(:inject, &:*)
    end

    def sel_explode_selection p
      pram = memory(p)
      selection_vertices(pram[:pos1], pram[:pos2])
    end


    # ============
    # = Handlers =
    # ============

    def clear_selection p
      memory(p).delete(:pos1)
      memory(p).delete(:pos2)
      tellm(p, {text: "Selection cleared!", color: "green"})
    end

    def require_pos1 p
      pram = memory(p)
      if pram[:pos1]
        return false
      else
        tellm(p, {text: "Pos1 required!", color: "red"})
        return true
      end
    end

    def require_pos2 p
      pram = memory(p)
      if pram[:pos2]
        return false
      else
        tellm(p, {text: "Pos2 required!", color: "red"})
        return true
      end
    end

    def require_selection p
      pram = memory(p)
      if pram[:pos1] && pram[:pos2]
        return false
      else
        tellm(p, {text: "Selection required!", color: "red"})
        return true
      end
    end

    def current_selection p, spos1 = true, spos2 = true, ssize = true, scorners = true
      pram = memory(p)

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
        sel_size = {text: "#{selection_size(p)} blocks", color: "yellow", italic: true}
      else
        sel_size = {text: "???", color: "gray", italic: true}
      end

      # corners
      if pram[:pos1] && pram[:pos2]
        sel_corners = {text: "#{sel_explode_selection(p).values.uniq.count} corners", color: "gold", italic: true}
      else
        sel_corners = {text: "0 corners", color: "gray", italic: true}
      end

      a = []
      a << pos1 if spos1
      a << pos2 if spos2
      a << sel_size if ssize
      a << sel_corners if scorners

      tellm(p, *a.zip([spacer] * (a.length-1)).flatten.compact)
    end

    def sel_insert p, pos
      pram = memory(p)
      $mcl.server.invoke %{/execute #{p} ~ ~ ~ clone #{pram[:pos1].join(" ")} #{pram[:pos2].join(" ")} #{pos.join(" ")}}
    end

    def insert_selection p, a
      chunks = a.map(&:strip).map{|i| i.to_s =~ /^-?[0-9]+$/ ? i.to_i : i}
      pram = memory(p)

      if chunks.count == 3
        unless require_selection(p)
          sel_insert(p, chunks)
          tellm(p, {text: "#{selection_size(p)} blocks involved", color: "gold"})
        end
      else
        tellm(p, {text: "!!insert <x> <y> <z>", color: "aqua"})
      end
    end

    def take_pos num, p, a
      chunks = a.map(&:strip).map{|i| i.to_s =~ /^-?[0-9]+$/ ? i.to_i : i}
      pram = memory(p)

      if chunks.count == 0
        current_selection(p, num == 1 || num.nil?, num == 2 || num.nil?, false, false)
      elsif chunks.count == 3
        if num.nil?
          pram[:pos1] = pram[:pos2] = chunks
        else
          pram[:"pos#{num}"] = chunks
        end
        current_selection(p)
      elsif chunks.count == 6 && num.nil?
        pram[:pos1] = chunks[0..2]
        pram[:pos2] = chunks[3..5]
        current_selection(p)
      else
        tellm(p, {text: "!!pos#{num} [x] [y] [z]#{" [x2] [y2] [z2]" if num.nil?}", color: "aqua"})
      end
    end

    def shift_pos num, p, a
      chunks = a.map(&:strip).map{|i| i.to_s =~ /^-?[0-9]+$/ ? i.to_i : i}
      pram = memory(p)

      if chunks.count == 0
        current_selection(p, num == 1 || num.nil?, num == 2 || num.nil?, false, false)
      elsif chunks.count == 3
        if num.nil?
          unless require_selection(p)
            pram[:pos1] = shift_coords(pram[:pos1], chunks)
            pram[:pos2] = shift_coords(pram[:pos2], chunks)
            current_selection(p)
          end
        else
          unless send(:"require_pos#{num}", p)
            pram[:"pos#{num}"] = shift_coords(pram[:"pos#{num}"], chunks)
            current_selection(p)
          end
        end
      elsif chunks.count == 6 && num.nil?
        unless require_selection(p)
          pram[:pos2] = shift_coords(pram[:pos1], chunks[0..2])
          pram[:pos2] = shift_coords(pram[:pos2], chunks[3..5])
          current_selection(p)
        end
      else
        tellm(p, {text: "!!spos#{num} [x] [y] [z]#{" [x2] [y2] [z2]" if num.nil?}", color: "aqua"})
      end
    end

    def indicate_pos num, p, a
      indicate, pram = [], memory(p)
      [].tap do |indicate|
        indicate << pram[:pos1] if pram[:pos1] && (num.nil? || num == 1)
        indicate << pram[:pos2] if pram[:pos2] && (num.nil? || num == 2)
      end.each{|coord| indicate_coord(p, coord, a[0]) }
    end

    def indicate_selection p, a
      pram = memory(p)
      unless require_selection(p)
        if a[1] == "outline"
          # sel_outline_explode(p)
          tellm(p, {text: "Not yet implemented, sorry", color: "red"})
        else
          sel_explode_selection(p).values.uniq.each{|coord| indicate_coord(p, coord, a[0]) }
        end
      end
    end

    def stack_selection p, a
      chunks = a.map(&:strip).map{|i| i.to_s =~ /^-?[0-9]+$/ ? i.to_i : i}
      pram = memory(p)

      if chunks.count == 0
        tellm(p, {text: "!!stack <direction> [amount] [shift_selection] [masked|filtered <TileName>]", color: "aqua"})
      else
        unless require_selection(p)
          # vars
          direction = chunks.shift
          amount    = chunks.any? ? [chunks.shift.to_i, 1].max : 1
          shift_sel = chunks.any? ? strbool(chunks.shift) : false
          mode      = chunks.any? ? chunks.shift : "replace"
          tile_name = chunks.shift

          # precheck
          if !pmemo(p)[:danger_mode] && amount > 50
            return require_danger_mode(p, "Stacking >50 times require danger mode to be enabled!")
          end

          # prepare
          cube                = sel_explode_selection(p)            # corners
          s1, s2              = cube[:xyz], cube[:XYZ]              # source selection
          p1, p2              = cube[:xyz], cube[:XYZ]              # frame selection
          seldim              = selection_dimensions(p)             # selection dimensions
          dir, axis, operator = coord_shifting_direction(direction) # coord shifting instructions

          # stack
          amount.times do
            # shift frame position
            p1 = shift_frame_selection(p1, seldim, axis, operator)
            p2 = shift_frame_selection(p2, seldim, axis, operator)

            # clone source => working
            $mcl.server.invoke %{/execute #{p} ~ ~ ~ /clone #{s1.join(" ")} #{s2.join(" ")} #{p1.join(" ")} #{mode} normal #{tile_name}}

            # shift source position
            s1, s2 = p1, p2
          end

          # move selection
          if shift_sel
            pram[:pos1] = p1
            pram[:pos2] = p2
            current_selection(p, true, true, false, false)
          end
        end
      end
    end

    def shift_frame_selection p, seldim, axis, operator
      case axis
        when :x then [p[0].send(operator, seldim[0]), p[1], p[2]]
        when :y then [p[0], p[1].send(operator, seldim[1]), p[2]]
        when :z then [p[0], p[1], p[2].send(operator, seldim[2])]
      end
    end
  end
end
