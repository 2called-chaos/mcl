module Mcl
  Mcl.reloadable(:HSchematicBuilder)
  class HSchematicBuilder < Handler
    def setup
      setup_parsers
      app.ram[:schematic_builder] ||= {}
    end

    def memory *arg
      if arg.count == 0
        app.ram[:schematic_builder]
      else
        app.ram[:schematic_builder][arg.first] ||= {}
        app.ram[:schematic_builder][arg.first]
      end
    end

    def title
      {text: "[ScheBu] ", color: "light_purple"}
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
    def setup_parsers
      register_command :schebu, desc: "Schematic Builder (more info with !schebu)" do |handler, player, command, target, args, optparse|
        handler.acl_verify(player)

        case args[0]
        when "add"
          handler.tellm(player, {text: "sorry, not yet implemented :(", color: "red"})
        when "list"
          handler.tellm(player, {text: "sorry, not yet implemented :(", color: "red"})
        when "load"
          handler.tellm(player, {text: "sorry, not yet implemented :(", color: "red"})
        when "rotate"
          handler.tellm(player, {text: "sorry, not yet implemented :(", color: "red"})
        when "masked"
          handler.tellm(player, {text: "sorry, not yet implemented :(", color: "red"})
        when "pos"
          handler.tellm(player, {text: "sorry, not yet implemented :(", color: "red"})
        when "status"
          handler.tellm(player, {text: "sorry, not yet implemented :(", color: "red"})
        when "reset"
          handler.tellm(player, {text: "sorry, not yet implemented :(", color: "red"})
        when "build"
          handler.tellm(player, {text: "sorry, not yet implemented :(", color: "red"})
        else
          handler.tellm(player, {text: "add <name> <url>", color: "gold"}, {text: " add a remote schematic to the library", color: "reset"})
          handler.tellm(player, {text: "list [filter]", color: "gold"}, {text: " list available schematics in the library", color: "reset"})
          handler.tellm(player, {text: "load <name>", color: "gold"}, {text: " load schematic from the library", color: "reset"})
          handler.tellm(player, {text: "rotate <±90deg>", color: "gold"}, {text: " rotate the schematic", color: "reset"})
          handler.tellm(player, {text: "masked <true/false>", color: "gold"}, {text: " when building with mask, air blocks won't get copied", color: "reset"})
          handler.tellm(player, {text: "pos <x> <y> <z>", color: "gold"}, {text: " set build start position", color: "reset"})
          handler.tellm(player, {text: "status", color: "gold"}, {text: " show info about the current build settings", color: "reset"})
          handler.tellm(player, {text: "reset", color: "gold"}, {text: " clear your current build settings", color: "reset"})
          handler.tellm(player, {text: "build", color: "gold"}, {text: " parse schematic and build it", color: "reset"})
        end
      end
    end
  end
end

__END__

r = SchematicBo2sConverter.convert(File.open("/Users/chaos/Downloads/town-hall.schematic"))
