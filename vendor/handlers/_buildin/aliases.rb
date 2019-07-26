module Mcl
  Mcl.reloadable(:HMclAliases)
  ## Aliases (custom commands/macros)
  # !alias <name>
  # !alias list    [-u user] [-s] [page|filter] [page]
  # !alias add     [-u user] [-s] <name> <command>
  # !alias info    [-u user] [-s] <name>
  # !alias delete  [-u user] [-s] <name> [index]
  class HMclAliases < Handler
    def setup
      register_alias(:member)
    end

    def register_alias acl_level
      register_command :_alias_invoke, desc: "internal shortcut handler", wildcard: true, acl: acl_level do |player, args, handler|
        com_resolve(player, [args[2]], true)
        false
      end
      register_command :alias, :aliases, desc: "custom commands/macros (more info with !alias)", acl: acl_level do |player, args, handler|
        case args[0]
        when "add", "delete", "list", "info"
          handler.send("com_#{args[0]}", player, args[1..-1])
        else
          com_resolve(player, args[1..-1])
        end
      end
    end

    def com_resolve player, args, silent = false
      muser = player
      opt = OptionParser.new
      opt.on("-s") { muser = :__server }
      opt.on("-u USER", String) {|v| muser = v }
      args = coord_save_optparse!(opt, args||[])
      c = args.join(" ").split("(")
      name = c.first
      _args = Shellwords.shellsplit(c[1][0..-2]) if c[1] && c[1].end_with?(")")

      acl_verify(player, acl_mod) if muser != :__server && muser != player
      if name.present?
        if ualias = find_alias(muser, name)
          execute_alias(player, ualias, _args || [])
        elsif !silent
          tellm(player, {text: "Unknown alias!", color: "red"})
        end
      elsif !silent
        tellm(player, {text: "add [-s] [-u user] <name> <command>", color: "gold"}, {text: " add command to alias", color: "reset"})
        tellm(player, {text: "delete [-s] [-u user] <name>", color: "gold"}, {text: " delete alias", color: "reset"})
        tellm(player, {text: "info [-s] [-u user] <name>", color: "gold"}, {text: " show commands", color: "reset"})
        tellm(player, {text: "list [-s] [-u user] [page|filter] [page]", color: "gold"}, {text: " list/search aliases", color: "reset"})
      end
    end

    def com_add player, args
      muser = player
      opt = OptionParser.new
      opt.on("-s") { muser = :__server }
      opt.on("-u USER", String) {|v| muser = v }
      args = coord_save_optparse!(opt, args)
      name = args.shift.presence
      command = args.join(" ")
      acl_verify(player, acl_srv) if muser == :__server
      acl_verify(player, acl_mod) if muser != :__server && muser != player

      if name && command.present?
        add_alias(muser, name, command) do |_fresh, _name, _commands|
          if _fresh
            tellm(player, {text: "Alias ", color: "green"}, {text: _name, color: "aqua"}, {text: " has been created!", color: "green"})
          else
            tellm(player, {text: "Alias ", color: "green"}, {text: _name, color: "aqua"}, {text: " got a command added (", color: "green"}, {text: "#{_commands.length} commands", color: "aqua"}, {text: ")!", color: "green"})
          end
        end
      else
        tellm(player, {text: "!alias add <name> <command>", color: "red"})
      end
    end

    def com_delete player, args
      muser = player
      opt = OptionParser.new
      opt.on("-s") { muser = :__server }
      opt.on("-u USER", String) {|v| muser = v }
      args = coord_save_optparse!(opt, args)
      name = args.shift.presence
      index = args.shift.to_i if args.any?
      acl_verify(player, acl_srv) if muser == :__server
      acl_verify(player, acl_mod) if muser != :__server && muser != player

      if name
        if al = find_alias(muser, name, false)
          if index
            if al[index]
              delete_alias(muser, name, index)
              if find_alias(muser, name, false)
                tellm(player, {text: "Alias ", color: "green"}, {text: name, color: "aqua"}, {text: " removed index ", color: "green"}, {text: "#{index}", color: "aqua"}, {text: "!", color: "green"})
              else
                tellm(player, {text: "Alias ", color: "green"}, {text: name, color: "aqua"}, {text: " removed (no commands left)!", color: "green"})
              end
            else
              tellm(player, {text: "Alias ", color: "red"}, {text: name, color: "aqua"}, {text: " doesn't have index ", color: "red"}, {text: "#{index}", color: "aqua"}, {text: "!", color: "red"})
            end
          else
            delete_alias(muser, name)
            tellm(player, {text: "Alias ", color: "green"}, {text: name, color: "aqua"}, {text: " removed!", color: "green"})
          end
        else
          tellm(player, {text: "Unknown alias!", color: "red"})
        end
      else
        tellm(player, {text: "!alias delete <name>", color: "red"})
      end
    end

    def com_info player, args
      muser = player
      opt = OptionParser.new
      opt.on("-s") { muser = :__server }
      opt.on("-u USER", String) {|v| muser = v }
      args = coord_save_optparse!(opt, args)
      name = args.shift.presence
      acl_verify(player, acl_srv) if muser == :__server
      acl_verify(player, acl_mod) if muser != :__server && muser != player

      if name
        if al = find_alias(muser, name, false)
          tellm(player, {text: "---Showing ", color: "green"}, {text: "#{al.length}", color: "aqua"}, {text: " commands for #{"server " if muser == :__server}alias ", color: "green"}, {text: name, color: "light_purple"}, {text: "---", color: "green"})
          al.each_with_index do |cmd, i|
            tellm(player, {text: "[", color: "yellow"}, {text: "#{i}", color: "light_purple"}, {text: "] ", color: "yellow"}, {text: cmd, color: "aqua"})
          end
        else
          tellm(player, {text: "Unknown alias!", color: "red"})
        end
      else
        tellm(player, {text: "!alias info <name>", color: "red"})
      end
    end

    def com_list player, args
      muser = player
      opt = OptionParser.new
      opt.on("-s") { muser = :__server }
      opt.on("-u USER", String) {|v| muser = v }
      recall = ->(m){
        "!alias #{m}".tap do |r|
          r << " -s" if muser == :__server
          r << " -u #{muser}" if muser != :__server && muser != player
        end
      }
      args = coord_save_optparse!(opt, args)
      acl_verify(player, acl_mod) if muser != :__server && muser != player

      pram = memory(muser)
      page, filter = 1, nil

      # filter
      if args[0] && args[0].to_i == 0
        filter = /#{args[0]}/
        page = (args[1] || 1).to_i
      else
        page = (args[0] || 1).to_i
      end

      # aliases
      saliases = [].tap do |r|
        pram.sort_by(&:first).each do |sname, scommands|
          if !filter || sname.to_s.match(filter)
            r << [
              {text: "#{sname}", color: "green", hoverEvent: {action: "show_text", value: {text: "execute #{sname} now"}}, clickEvent: {action: "run_command", value: "!#{sname}"}},
              {text: " (", color: "yellow"},
              {text: "#{scommands.length} commands", color: "aqua", hoverEvent: {action: "show_text", value: {text: "show commands for alias #{sname}"}}, clickEvent: {action: "run_command", value: "#{recall["info"]} #{sname}"}},
              {text: ") ", color: "yellow"},
              {text: "X", color: "red", hoverEvent: {action: "show_text", value: {text: "delete alias #{sname}"}}, clickEvent: {action: "suggest_command", value: "#{recall["delete"]} #{sname}"}},
            ]
          end
        end
      end

      # paginate
      page_contents = saliases.in_groups_of(7, false)
      pages = (saliases.count/7.0).ceil

      if saliases.any?
        tellm(player, {text: "--- Showing #{saliases.count} #{"server " if muser == :__server}aliases page #{page}/#{pages} ---", color: "aqua"})
        (page_contents[page-1]||[]).each {|ualias| tellm(player, *ualias) }
        if muser != :__server
          tellm(player, {text: "Use ", color: "aqua"}, {text: "-s", color: "light_purple"}, {text: " to show server aliases.", color: "aqua"})
        end
      else
        tellm(player, {text: "No aliases found for that filter/page!", color: "red"})
      end
    end

    module Helper
      # ACL for modifying server aliases
      def acl_srv
        :admin
      end

      # ACL for modifying/seeing other users aliases
      def acl_mod
        :mod
      end

      def memory p, &block
        if block
          prec(p).tap do |r|
            r.data[:mcl_aliases] ||= {}
            block.call(r.data[:mcl_aliases])
            r.save!
          end
        else
          prec(p).data[:mcl_aliases] ||= {}
        end
      end

      def tellm p, *msg
        trawt(p, "Alias", *msg)
      end

      def execute_alias player, ualias, args = []
        async do
          ualias.each do |ucmd|
            ucmd = ucmd.gsub(/{{([\d]{1,2})}}/) {|n| args[n.to_i] }
            if m = ucmd.match(/delay:([\d\.]+)/)
              sleep m[1].to_d
            else
              $mcl.server.invoke do |cmd|
                cmd.default %{/execute #{player} ~ ~ ~ say #{ucmd}}
                cmd.since "1.13", "17w45a", %{/execute as #{player} run say #{ucmd}}
              end
            end
          end
        end
      end

      def find_alias player, name, fallback = true
        pram, sram = memory(player), memory(:__server)
        pram[name.to_s] || (fallback && sram[name.to_s])
      end

      def add_alias player, name, cmd, &block
        memory(player) do |pram|
          if pram.key?(name.to_s)
            fresh = false
            pram[name.to_s] << cmd
          else
            fresh = true
            pram[name.to_s] = [cmd]
          end
          block&.call(fresh, name, pram[name.to_s])
        end
      end

      def delete_alias player, name, index = nil
        memory(player) do |pram|
          if index
            pram[name.to_s].delete_at(index)
            pram.delete(name.to_s) if pram[name.to_s].empty?
          else
            pram.delete(name.to_s)
          end
        end
      end
    end
    include Helper
  end
end
