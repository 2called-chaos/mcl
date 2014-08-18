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
    def available_schematics
      Dir["#{$mcl.server.root}/schematics/*.schematic"].map{|f| File.basename(f, ".schematic") }
    end

    def require_schematic p
      pram = memory(p)
      if pram[:current_schematic]
        return false
      else
        tellm(p, {text: "No schematic loaded yet!", color: "red"})
        return true
      end
    end

    def load_schematic_as_bo2s name
      file = "#{$mcl.server.root}/schematics/#{name}.schematic"
      SchematicBo2sConverter.convert(File.open(file))
    end

    def load_schematic name
      file = "#{$mcl.server.root}/schematics/#{name}.schematic"
      SchematicBo2sConverter.open(File.open(file))
    end

    # ============
    # = Commands =
    # ============
    def setup_parsers
      register_command :schebu, desc: "Schematic Builder (more info with !schebu)" do |handler, player, command, target, args, optparse|
        handler.acl_verify(player)
        pram = memory(player)

        case args[0]
        when "book", "add", "list", "load", "rotate", "air", "pos", "status", "reset", "build"
          handler.send("com_#{args[0]}", player, args[1..-1])
        else
          handler.tellm(player, {text: "book", color: "gold"}, {text: " gives you a book with more info", color: "reset"})
          # handler.tellm(player, {text: "add <name> <url>", color: "gold"}, {text: " add a remote schematic", color: "reset"})
          handler.tellm(player, {text: "list [filter]", color: "gold"}, {text: " list available schematics", color: "reset"})
          handler.tellm(player, {text: "load <name>", color: "gold"}, {text: " load schematic from library", color: "reset"})
          handler.tellm(player, {text: "rotate <±90deg>", color: "gold"}, {text: " rotate the schematic", color: "reset"})
          handler.tellm(player, {text: "air <t/f>", color: "gold"}, {text: " copy air yes or no", color: "reset"})
          # handler.tellm(player, {text: "pos <x> <y> <z>", color: "gold"}, {text: " set build start position", color: "reset"})
          # handler.tellm(player, {text: "status", color: "gold"}, {text: " show info about the current build settings", color: "reset"})
          # handler.tellm(player, {text: "reset", color: "gold"}, {text: " clear your current build settings", color: "reset"})
          # handler.tellm(player, {text: "build", color: "gold"}, {text: " parse schematic and build it", color: "reset"})
        end
      end
    end

    def com_book player, args
      cmd = "/give #{player} written_book 1 0 "
      cmd << %q{{pages:["{\"text\":\"\",\"extra\":[{\"text\":\"ScheBu\n\",\"color\":\"red\",\"bold\":\"true\"},{\"text\":\"Schematic Builder\n\",\"color\":\"red\"},{\"text\":\"-------------------\n\"},{\"text\":\"P2: Important Notes\n\"},{\"text\":\"P3: Process of building\n\"},{\"text\":\"P+: Command help\n\"}]}","{\"text\":\"\",\"extra\":[{\"text\":\"Important Notes\n\",\"color\":\"red\",\"bold\":\"true\"},{\"text\":\"-----------------\n\"},{\"text\":\"ScheBu will read the schematic, convert it to a block matrix and send a setblock command to the server console, FOR EACH BLOCK! This is obviously very imperformant and you shouldn't use that for large schematics.\"}]}","{\"text\":\"\",\"extra\":[{\"text\":\"Important Notes\n\",\"color\":\"red\",\"bold\":\"true\"},{\"text\":\"-----------------\n\"},{\"text\":\"MCL, which is the parent of ScheBu, will be unresponsive during builds.\"}]}","{\"text\":\"\",\"extra\":[{\"text\":\"Process\n\",\"color\":\"red\",\"bold\":\"true\"},{\"text\":\"-----------------\n\"},{\"text\":\"When you load a schematic, we just check if it exists and contains valid NBT data. We also extract the dimensions of the schematic. All settings you change (rotation, etc.) will not be calculated until you issue the build command.\"}]}","{\"text\":\"\",\"extra\":[{\"text\":\"Process\n\",\"color\":\"red\",\"bold\":\"true\"},{\"text\":\"-----------------\n\"},{\"text\":\"Upon build the schematic content will be loaded, converted, processed and then build. You cannot build 2 things at the same time!\"}]}"],title:"ScheBu Infosheet",author:ScheBu}}
      $mcl.server.invoke(cmd)
    end

    def com_add player, args
      tellm(player, {text: "sorry, not yet implemented :(", color: "red"})
    end

    def com_list player, args
      acl_verify(player)
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
        page_contents[page-1].each {|schem| tellm(player, {text: schem, color: "reset"}) }
        tellm(player, {text: "Use ", color: "aqua"}, {text: "!schembu list [str] <page>", color: "light_purple"}, {text: " to [filter] and/or <paginate>.", color: "aqua"})
      else
        tellm(player, {text: "No schematics found for that filter/page!", color: "red"})
      end
    end

    def com_load player, args
      sname = args[0]
      if available_schematics.include?(sname)
        pram = memory(player)
        begin
          schematic = load_schematic(sname)
          new_schematic = {}.tap do |r|
            r[:name] = sname
            r[:x] = schematic["Width"]
            r[:y] = schematic["Height"]
            r[:z] = schematic["Length"]
            r[:dimensions] = [r[:x], r[:y], r[:z]]
            r[:rotation] = 0
            r[:air] = true
            r[:pos] = pram[:current_schematic].try(:[], :pos)
          end
          pram[:current_schematic] = new_schematic
          tellm(player, {text: "Schematic loaded ", color: "green"}, {text: "(#{new_schematic[:dimensions].join("x")} = #{new_schematic[:dimensions].inject(:*)})", color: "reset"})
        rescue
          tellm(player, {text: "Error loading schematic!", color: "red"})
          tellm(player, {text: "#{$!.message}", color: "red"})
        end
      else
        tellm(player, {text: "Schematic couldn't be found!", color: "red"})
      end
    end

    def com_rotate player, args
      unless require_schematic(player)
        pram = memory(player)
        deg = args[0].to_i
        if deg > 0
          pram[:current_schematic][:rotation] = 360 % (args[0].to_i + pram[:current_schematic][:rotation])
        else
          tellm(player, {text: "Rotation must be divisible by 90", color: "red"})
        end
        tellm(player, {text: "Schematic rotation is #{pram[:current_schematic][:rotation]} degrees", color: "yellow"})
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


"{\"text\":\"\",\"extra\":[{\"text\":\"ScheBu\n\",\"color\":\"red\",\"bold\":\"true\"},{\"text\":\"Schematic Builder\n\",\"color\":\"red\"},{\"text\":\"-------------------\n\"},{\"text\":\"P2: Important Notes\n\"},{\"text\":\"P3: Process of building\n\"},{\"text\":\"P+: Command help\n\"}]}"
"{\"text\":\"\",\"extra\":[{\"text\":\"Important Notes\n\",\"color\":\"red\",\"bold\":\"true\"},{\"text\":\"-----------------\n\"},{\"text\":\"ScheBu will read the schematic, convert it to a block matrix and send a setblock command to the server console, FOR EACH BLOCK! This is obviously very imperformant and you shouldn't use that for large schematics.\"}]}"
"{\"text\":\"\",\"extra\":[{\"text\":\"Important Notes\n\",\"color\":\"red\",\"bold\":\"true\"},{\"text\":\"-----------------\n\"},{\"text\":\"MCL, which is the parent of ScheBu, will be unresponsive during builds.\"}]}"
"{\"text\":\"\",\"extra\":[{\"text\":\"Process\n\",\"color\":\"red\",\"bold\":\"true\"},{\"text\":\"-----------------\n\"},{\"text\":\"When you load a schematic, we just check if it exists and contains valid NBT data. We also extract the dimensions of the schematic. All settings you change (rotation, etc.) will not be calculated until you issue the build command.\"}]}"
"{\"text\":\"\",\"extra\":[{\"text\":\"Process\n\",\"color\":\"red\",\"bold\":\"true\"},{\"text\":\"-----------------\n\"},{\"text\":\"Upon build the schematic content will be loaded, converted, processed and then build. You cannot build 2 things at the same time!\"}]}"



/give @a written_book 1 0 {pages:[],title:"ScheBu Infosheet",author:ScheBu}

