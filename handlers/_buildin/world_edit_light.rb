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

    def wel
      {text: "[WEL] ", color: "light_purple"}.to_json
    end

    def spacer
      {text: " / ", color: "reset"}.to_json
    end

    def clear_selection p
      memory(p).delete(:pos1)
      memory(p).delete(:pos2)
      $mcl.server.invoke %{/tellraw #{p} [#{wel},#{{text: "Selection cleared!"}.to_json}]}
    end

    def require_pos1 p
      pram = memory(p)
      if pram[:pos1]
        return false
      else
        $mcl.server.invoke %{/tellraw #{p} [#{wel},#{{text: "Pos1 required!"}.to_json}]}
        return true
      end
    end

    def require_pos2 p
      pram = memory(p)
      if pram[:pos2]
        return false
      else
        $mcl.server.invoke %{/tellraw #{p} [#{wel},#{{text: "Pos2 required!"}.to_json}]}
        return true
      end
    end

    def require_selection p
      pram = memory(p)
      if pram[:pos1] && pram[:pos2]
        return false
      else
        $mcl.server.invoke %{/tellraw #{p} [#{wel},#{{text: "Selection required!"}.to_json}]}
        return true
      end
    end

    def selection_size p
      pram = memory(p)
      if pram[:pos1] && pram[:pos2]
        zip = pram[:pos1].zip(pram[:pos2])
        xd = (zip[0].max - zip[0].min).round(0) + 1
        yd = (zip[1].max - zip[1].min).round(0) + 1
        zd = (zip[2].max - zip[2].min).round(0) + 1
        xd * yd * zd
      else
        false
      end
    end

    def current_selection p, spos1 = true, spos2 = true, ssize = true
      pram = memory(p)

      if coords = pram[:pos1]
        pos1 = {text: coords.join(" "), color: "aqua"}.to_json
      else
        pos1 = {text: "unset", color: "gray", italic: true}.to_json
      end

      if coords = pram[:pos2]
        pos2 = {text: coords.join(" "), color: "blue"}.to_json
      else
        pos2 = {text: "unset", color: "gray", italic: true}.to_json
      end

      if pram[:pos1] && pram[:pos2]
        sel_size = {text: "#{selection_size(p)} blocks", color: "aqua", italic: true}.to_json
      else
        sel_size = {text: "???", color: "gray", italic: true}.to_json
      end

      a = []
      a << pos1 if spos1
      a << pos2 if spos2
      a << sel_size if ssize

      cmd =  %{/tellraw #{p} [#{wel},#{a.join(",#{spacer},")}]}
      $mcl.server.invoke(cmd)
    end

    def take_pos num, p, c
      chunks = c.split(" ")[1..-1].map(&:strip).map{|i| i.to_s =~ /^-?[0-9]+$/ ? i.to_i : i}
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
        pos = {text: "!!pos#{num} [x] [y] [z]#{" [x2] [y2] [z2]" if num.nil?}", color: "blue"}.to_json
        $mcl.server.invoke %{/tellraw #{p} [#{h.wel},#{pos}]}
      end
    end

    def shift_coords one, two
      [one[0] + two[0], one[1] + two[1], one[2] + two[2]]
    end

    def shift_pos num, p, c
      chunks = c.split(" ")[1..-1].map(&:strip).map{|i| i.to_s =~ /^-?[0-9]+$/ ? i.to_i : i}
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
        pos = {text: "!!spos#{num} [x] [y] [z]#{" [x2] [y2] [z2]" if num.nil?}", color: "blue"}.to_json
        $mcl.server.invoke %{/tellraw #{p} [#{h.wel},#{pos}]}
      end
    end

    def reg_sel
      register_command "!sel" do |h, p, c, t, o|
        if c.split(" ")[1] == "clear"
          h.clear_selection(p)
        else
          h.current_selection(p)
        end
      end

      register_command "!fill" do |h, p, c, t, o|
        pram = h.memory(p)
        unless require_selection(p)
          pram = memory(p)
          $mcl.server.invoke %{/execute #{p} ~ ~ ~ fill #{pram[:pos1].join(" ")} #{pram[:pos2].join(" ")} #{c.split(" ")[1..-1].join(" ")}}
        end
      end
    end

    def reg_pos
      register_command "!pos" do |h, p, c, t, o|
        h.take_pos(nil, p, c)
      end

      register_command "!spos" do |h, p, c, t, o|
        h.shift_pos(nil, p, c)
      end

      [1,2].each do |num|
        register_command "!pos#{num}" do |h, p, c, t, o|
          h.take_pos(num, p, c)
        end

        register_command "!spos#{num}" do |h, p, c, t, o|
          h.shift_pos(num, p, c)
        end

        register_command "!spos#{num}" do |h, p, c, t, o|
          chunks = c.split(" ")[1..-1].map(&:strip).map{|i| i.to_s =~ /^-?[0-9]+$/ ? i.to_i : i}
          pram = h.memory(p)

          if chunks.count == 0
            h.current_selection(p, num == 1, num == 2, false)
          elsif chunks.count == 3
            pram[:"pos#{num}"] = chunks
            h.current_selection(p)
          else
            pos = {text: "!!pos#{num} [x] [y] [z]", color: "blue"}.to_json
            $mcl.server.invoke %{/tellraw #{p} [#{h.wel},#{pos}]}
          end
        end
      end
    end
  end
end

__END__
# mcedit light
!!pos1   # selection start
!!pos2   # selection end
!!insert # insert selection here
!!set    # set blocks to (fill)
