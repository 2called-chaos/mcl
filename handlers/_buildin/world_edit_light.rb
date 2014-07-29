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
      memory(p).delete(:pos1, :pos2)
      $mcl.server.invoke %{/tellraw #{p} [#{wel},#{{text: "Selection cleared!"}.to_json}]}
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
        sel_size = {text: "213 blocks", color: "aqua", italic: true}.to_json
      else
        sel_size = {text: "???", color: "gray", italic: true}.to_json
      end

      cmd =  %{/tellraw #{p} [#{wel}}
      cmd << %{,#{pos1}} if spos1
      cmd << %{,#{spacer},#{pos2}} if spos2
      cmd << %{,#{spacer},#{sel_size}} if ssize
      cmd << %{]}
      $mcl.server.invoke(cmd)
    end

    def reg_sel
      register_command "!sel" do |h, p, c, t, o|
        if c.split(" ")[1] == "clear"
          h.clear_selection(p)
        else
          h.current_selection(p)
        end
      end
    end

    def reg_pos
      [*1..2].each do |num|
        register_command "!pos#{num}" do |h, p, c, t, o|
          chunks = c.split(" ")[1..-1].map(&:strip)
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
