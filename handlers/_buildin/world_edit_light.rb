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
      register_command "!sel [clear]", desc: "shows or clears current selection" do |h, p, c, t, a, o|
        a[0] == "clear" ? h.clear_selection(p) : h.current_selection(p)
      end

      register_command "!set <block>", desc: "fills selection with given block" do |h, p, c, t, a, o|
        h.acl_verify(p)
        pram = h.memory(p)
        unless require_selection(p)
          $mcl.server.invoke %{/execute #{p} ~ ~ ~ fill #{pram[:pos1].join(" ")} #{pram[:pos2].join(" ")} #{a.join(" ")}}
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

      [1,2].each do |num|
        register_command "!pos#{num}", desc: "sets pos#{num} to given coords" do |h, p, c, t, a, o|
          h.take_pos(num, p, a)
        end

        register_command "!spos#{num}", desc: "shifts pos#{num} by given values" do |h, p, c, t, a, o|
          h.shift_pos(num, p, a)
        end
      end
    end



    # ===========
    # = Helpers =
    # ===========

    def selection_dimensions p
      pram = memory(p)
      if pram[:pos1] && pram[:pos2]
        zip = pram[:pos1].zip(pram[:pos2])
        xd = (zip[0].max - zip[0].min).round(0) + 1
        yd = (zip[1].max - zip[1].min).round(0) + 1
        zd = (zip[2].max - zip[2].min).round(0) + 1
        [xd, yd, zd]
      else
        false
      end
    end

    def selection_size p
      if dim = selection_dimensions(p)
        dim.inject(&:*)
      else
        false
      end
    end

    def shift_coords one, two
      [one[0] + two[0], one[1] + two[1], one[2] + two[2]]
    end

    def lg_coord p1, p2
      [p1, p2]
    end

    def stack_coord_shifting lp, strdir
      case strdir
        when "n", "north" then [:north, :z, :-]
        when "e", "east" then [:east, :x, :+]
        when "s", "south" then [:south, :z, :+]
        when "w", "west" then [:west, :x, :-]
        when "u", "up" then [:up, :y, :+]
        when "d", "down" then [:down, :y, :-]
        else raise "unknown direction (n/e/s/w/u/d)"
      end
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

    def current_selection p, spos1 = true, spos2 = true, ssize = true
      pram = memory(p)

      if coords = pram[:pos1]
        pos1 = {text: coords.join(" "), color: "aqua"}
      else
        pos1 = {text: "unset", color: "gray", italic: true}
      end

      if coords = pram[:pos2]
        pos2 = {text: coords.join(" "), color: "blue"}
      else
        pos2 = {text: "unset", color: "gray", italic: true}
      end

      if pram[:pos1] && pram[:pos2]
        sel_size = {text: "#{selection_size(p)} blocks", color: "aqua", italic: true}
      else
        sel_size = {text: "???", color: "gray", italic: true}
      end

      a = []
      a << pos1 if spos1
      a << pos2 if spos2
      a << sel_size if ssize

      tellm(p, *a.zip([",#{spacer},"] * a.count))
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
        tellm(p, {text: "!!insert <x> <y> <z>", color: "blue"})
      end
    end

    def take_pos num, p, a
      chunks = a.map(&:strip).map{|i| i.to_s =~ /^-?[0-9]+$/ ? i.to_i : i}
      pram = memory(p)

      if chunks.count == 0
        current_selection(p, num == 1 || num.nil?, num == 2 || num.nil?, false)
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
        tellm(p, {text: "!!pos#{num} [x] [y] [z]#{" [x2] [y2] [z2]" if num.nil?}", color: "blue"})
      end
    end

    def shift_pos num, p, a
      chunks = a.map(&:strip).map{|i| i.to_s =~ /^-?[0-9]+$/ ? i.to_i : i}
      pram = memory(p)

      if chunks.count == 0
        current_selection(p, num == 1 || num.nil?, num == 2 || num.nil?, false)
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
        tellm(p, {text: "!!spos#{num} [x] [y] [z]#{" [x2] [y2] [z2]" if num.nil?}", color: "blue"})
      end
    end

    def stack_selection p, a
      chunks = a.map(&:strip).map{|i| i.to_s =~ /^-?[0-9]+$/ ? i.to_i : i}
      pram = memory(p)

      if chunks.count == 0
        tellm(p, {text: "!!stack <direction> [amount] [move_selection]", color: "blue"})
      else
        unless require_selection(p)
          direction = chunks.shift
          amount = chunks.any? ? [chunks.shift.to_i, 1].max : 1
          shift = chunks.any? ? strbool(chunks.shift) : false

          # sorted position
          p1, p2 = lg_coord(pram[:pos1], pram[:pos2])
          c1, c2 = p1, p2
          dirmap = stack_coord_shifting(p1, direction)

          tellm(p, {text: "#{p1.join(",")} / #{p2.join(",")} / #{dirmap[0]} (#{dirmap[2]}#{dirmap[1]})", color: "blue"})
        end
      end
    end
  end
end
