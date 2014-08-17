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

    # ===========
    # = Helpers =
    # ===========
    def schematics
      Dir["#{$mcl.server.root}/schematics/*.schematic"].map{|f| File.basename(f, ".schematic") }
    end

    # ============
    # = Commands =
    # ============
    def setup_parsers
      register_command :schebu, desc: "Schematic Builder (more info with !schebu)" do |handler, player, command, target, args, optparse|
        handler.acl_verify(player)
        pram = memory(p)

        case args[0]
        when "add", "list", "load", "rotate", "masked", "pos", "status", "reset", "build"
          handler.send("com_#{args[0]}", player, args[1..-1])
        else
          handler.tellm(player, {text: "add <name> <url>", color: "gold"}, {text: " add a remote schematic", color: "reset"})
          handler.tellm(player, {text: "list [filter]", color: "gold"}, {text: " list available schematics", color: "reset"})
          handler.tellm(player, {text: "load <name>", color: "gold"}, {text: " load schematic from library", color: "reset"})
          handler.tellm(player, {text: "rotate <±90deg>", color: "gold"}, {text: " rotate the schematic", color: "reset"})
          handler.tellm(player, {text: "air <t/f>", color: "gold"}, {text: "copy air yes or no", color: "reset"})
          handler.tellm(player, {text: "pos <x> <y> <z>", color: "gold"}, {text: " set build start position", color: "reset"})
          handler.tellm(player, {text: "status", color: "gold"}, {text: " show info about the current build settings", color: "reset"})
          handler.tellm(player, {text: "reset", color: "gold"}, {text: " clear your current build settings", color: "reset"})
          handler.tellm(player, {text: "build", color: "gold"}, {text: " parse schematic and build it", color: "reset"})
        end
      end
    end

    def com_add player, args
      tellm(player, {text: "sorry, not yet implemented :(", color: "red"})
    end

    def com_list player, args
      acl_verify(player)
      sfiles = $mcl.command_names.to_a

      # filter
      if args[0] && args[0].to_i == 0
        sfiles = sfiles.select{|c, _| c.to_s =~ /#{args[0]}/ }
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
        page_contents[page-1].each do |com|
          desc = com[1] ? {text: " #{com[1]}", color: "reset"} : {text: " no description", color: "gray", italic: true}
          tellm(player, {text: com[0], color: "light_purple"}, desc)
        end
        tellm(player, {text: "Use ", color: "aqua"}, {text: "!schembu list [str] <page>", color: "light_purple"}, {text: " to [filter] and/or <paginate>.", color: "aqua"})
      else
        tellm(player, {text: "No schematics found for that filter/page!", color: "red"})
      end
    end

    def com_load player, args
      tellm(player, {text: "sorry, not yet implemented :(", color: "red"})
    end

    def com_rotate player, args
      tellm(player, {text: "sorry, not yet implemented :(", color: "red"})
    end

    def com_masked player, args
      tellm(player, {text: "sorry, not yet implemented :(", color: "red"})
    end

    def com_pos player, args
      tellm(player, {text: "sorry, not yet implemented :(", color: "red"})
    end

    def com_status player, args
      tellm(player, {text: "sorry, not yet implemented :(", color: "red"})
    end

    def com_reset player, args
      tellm(player, {text: "sorry, not yet implemented :(", color: "red"})
    end

    def com_build player, args
      tellm(player, {text: "sorry, not yet implemented :(", color: "red"})
    end
  end
end

__END__

r = SchematicBo2sConverter.convert(File.open("/Users/chaos/Downloads/town-hall.schematic"))
