module Mcl
  Mcl.reloadable(:WorldEditLight)
  class WorldEditLight < Handler
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
      register_command "!!sel" do |handler, player, command, target, optparse|
        pram = memory(p)
        wel = {text: "[WEL] ", color: "light_purple"}.to_json
        spacer = {text: " / ", color: "reset"}.to_json

        if pram[:pos1]
          pos1 = {text: "", color: "aqua"}.to_json
        else
          pos1 = {text: "unset", color: "gray", italic: true}.to_json
        end

        if pram[:pos2]
          pos1 = {text: "", color: "blue"}.to_json
        else
          pos1 = {text: "unset", color: "gray", italic: true}.to_json
        end

        if pram[:pos1] && pram[:pos2]
        else
          sel_size = {text: "???", color: "gray", italic: true}.to_json
        end

        $mcl.server.invoke %{/tellraw #{player} [#{wel},#{pos1},#{spacer},#{pos2},#{spacer},#{sel_size}]}
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
