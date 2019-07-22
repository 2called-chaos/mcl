module Mcl
  Mcl.reloadable(:HMclWorlds)
  ## Simple world manager
  # !world(s)                                                              shows this help
  # !world(s) list                                                         list known worlds
  # !world(s) <name>                                                       switch to given world
  # !world(s) scan                                                         rescan file system for unknown worlds, remove broken known worlds
  # !world(s) new <name> [sprops...]                                       create a new world
  # !world(s) info [name]                                                  shows information about given or current world
  # !world(s) backup [name]                                                creates a world backup for given or current world
  # !world(s) backups [name] [page]                                        list existing backups (newest first)
  # !world(s) backups [name] --delete <tarfile>                            delete existing backup
  # !world(s) restore <name> <tarfile> [backup_current=true]               reverts a given world to a backed up state
  # !world(s) delete <name> [purge_backups=false]                          deletes a given world and optionally it's backups
  class HMclWorlds < Handler
    ACTIONS = %w[list scan info backup backups restore delete new activate]

    def setup
      register_worlds(:admin)
    end

    def srvrdy
      unless File.exist?(kwf)
        app.log.info "[MCLiverse] scanning worlds once, this might take a while..."
        server.invoke "save-all"
        async do
          30.times do
            sleep 1
            break if $world_saved
          end
          scan_worlds
          sync { app.log.info "[MCLiverse] found #{known_worlds.length} worlds" }
        end
      end
    end

    def register_worlds acl_level
      register_command :world, :worlds, desc: "simple world manager", acl: acl_level do |player, args, handler|
        case args[0]
        when *ACTIONS
          handler.send("com_#{args[0]}", player, args[1..-1])
        else
          if args[0]
            com_activate(player, args)
          else
            com_help(player, args)
          end
        end
      end
    end

    def com_help player, args
      tellm_cworld(player)
      tellm(player, l("list", :gold), l(" list known worlds", :reset))
      tellm(player, l("<name>", :gold), l(" switch to given world", :reset))
      tellm(player, l("scan", :gold), l(" scan filesystem for unknown worlds", :reset))
      tellm(player, l("new <name> [sprop=value]…", :gold), l(" create new world", :reset))
      tellm(player, l("info [name]", :gold), l(" show world info", :reset))
      tellm(player, l("backup [name]", :gold), l(" create world backup", :reset))
      tellm(player, l("backups [name] [page]", :gold), l(" list backups", :reset))
      tellm(player, l("backups [name] --delete <tarfile>", :gold), l(" delete backup", :reset))
      tellm(player, l("restore <name> <tarfile> [backup_current=true]", :gold), l(" restore world backup", :reset))
      tellm(player, l("delete <name> [purge_backups=false]", :gold), l(" delete a world", color: :reset))
    end

    def com_new player, args
      if args.any?
        world_name = args.shift.to_s
        sprops = Shellwords.shellsplit(args.join(" "))
        if ACTIONS.include?(world_name) || !world_name.match(/\A[0-9a-z_\-\/]+\z/i)
          tellm(player, l("Invalid world name!", :red))
        else
          new_world = World.new(world_name, server)
          `mkdir#{" -p" unless Mcl.windows?} "#{new_world.root}"`
          add_known_world(new_world)

          # sprop
          if sprops.any?
            sproph = sprops.each_with_object({}) {|kv, r| k, v = kv.split("=", 2); r[k] = v }
            new_world.properties.update(server.properties.data.merge(sproph).merge({"level-name" => new_world.name}))
          end

          tellm(player, l("Created world #{world_name}! ", :green), l("[switch now]", :light_purple, hover: "switch to world #{world_name}", command: "!world #{world_name}"))
        end
      else
        tellm(player, l("!world new <name> [sprop=value]…", :red))
      end
    end

    def com_list player, args
      tellm_cworld(player)
      known_worlds.in_groups_of(5, false).each do |worldl|
        array = [l("known worlds: ", :gold)]
        worldl.each_with_index do |world, i|
          array << l(", ", :gold) unless i.zero?
          array << l(world, color: "aqua", hover: "show info for #{world}", command: "!world info #{world}")
        end
        tellm(player, *array)
      end
    end

    def com_scan player, args
      tellm(player, l("Scanning filesystem for worlds (may take a while)...", :gold))
      async do
        ow = known_worlds
        nw = scan_worlds
        sync do
          tellm(player,
            l("Found ", :gold),
            l("#{(nw - ow).length}", :aqua),
            l(" worlds (", :gold),
            l("#{nw.length}", :dark_aqua),
            l(" in total)!", :gold),
            l(" "), l("[show list]", color: :aqua, hover: "show list now", command: "!world list")
          )
        end
      end
    end

    def com_info player, args
      if world = iknown_worlds[args[0] || server.world]
        async_safe do
          tellm(player, l(world.name, :aqua))
          tellm(player, l(" size: ", :gold), l(server.human_bytes(world.size), :yellow))
          tellm(player, l(" last modified: ", :gold), l(world.fmtime, :yellow))
          backups = world.backups(true)
          if backups.length > 0
            tellm(player, l(" backups: ", :gold), l("#{backups.count} (#{world.fbackups_size(backups)})", :yellow, hover: "list backups", command: "!world backups #{world.name}"))
            tellm(player, l(" last backup: ", :gold), l("#{world.last_backup(backups)}", :yellow))
           else
            tellm(player, l(" backups: ", :gold), l("none", :yellow, italic: true))
          end
        end
      else
        tellm(player, l("Unknown world!", :red))
      end
    end

    def com_backup player, args
      if world = iknown_worlds[args[0] || server.world]
        tellm(player, l("Starting backup!", :gold))
        world.create_backup! do |rt|
          tellm(player, l("Backup done (", :gold), l(Player.fseconds(rt), :aqua), l(")!", :gold))
        end
      else
        tellm(player, l("Unknown world!", :red))
      end
    end

    def com_backups player, args
      if args.delete("--delete")
        delete_backup = args.pop()
      else
        if args[0].to_s.match(/\A[0-9]+\z/)
          page = args.shift.to_i
        elsif args[1].to_s.match(/\A[0-9]+\z/)
          page = args.pop.to_i
        else
          page = 1
        end
      end

      if world = iknown_worlds[args[0] || server.world]
        if delete_backup
          async_safe do
            blist = world.backups(false)
            sync do
              if rec = blist.detect{|_, fn, _, _| fn == delete_backup }
                begin
                  File.unlink(rec[0])
                  tellm(player, l("Backup removed successfully!", :green))
                end
              else
                tellm(player, l("This backup doesn't belong to this world or does not exist!", :red))
              end
            end
          end
        else
          async_safe do
            blist = world.backups(true)
            sync do
              if blist.any?
                # paginate
                page_contents = blist.in_groups_of(7, false)
                pages = (blist.count/7.0).ceil

                tellm(player, l("--- Showing backups page #{page}/#{pages} (#{blist.count} backups) ---", :aqua))
                (page_contents[page-1]||[]).each do |b|
                  tellm(player,
                    l("[", :yellow),
                    l("R", :green, hover: "restore (backup current)", scommand: "!world restore #{world.name} #{b[1]} true"),
                    l(" "),
                    l("R", :red, hover: "restore (discard current)", scommand: "!world restore #{world.name} #{b[1]} false"),
                    l(" "),
                    l("X", :red, hover: "delete this backup", scommand: "!world backups #{world.name} --delete #{b[1]}"),
                    l("] ", :yellow),
                    l(b[2].strftime("%F %T"), :dark_green, hover: "#{Player.fseconds((Time.current - b[2]).to_i)} ago"),
                    l(" (", :yellow), l(server.human_bytes(b[3]), :yellow), l(") ", :yellow),
                  )
                end
              else
                tellm(player, l("This world has no backups yet or page is invalid!", :red))
              end
            end
          end
        end
      else
        tellm(player, l("Unknown world!", :red))
      end
    end

    def com_restore player, args
      # switch restore of current world after server stopped
      if args.delete("--post-mortem")
        xargs = Shellwords.shellsplit(args.join(" "))
        unless world = iknown_worlds[xargs.shift]
          return tellm(player, l("Unknown world!", :red))
        end

        udir = "#{server.root}/#{xargs.shift}"
        unless FileTest.directory?(udir)
          if FileTest.directory?("#{udir}-pending")
            return tellm(player, l("Restore process already pending! ", :red), l("Restart the server!", :aqua, hover: "restart now", command: "!mclreboot false"))
          else
            return tellm(player, l("The restore directory is invalid!", :red))
          end
        end

        # prevent double calls
        FileUtils.mv(udir, "#{udir}-pending")

        async do
          sleep 1 while server.alive?
          sync do
            app.log.info "[MCLiverse] Restoring world #{world.name}..."
            sleep 1
            FileUtils.rm_rf(world.root)
            FileUtils.mv("#{udir}-pending", world.root)
            world.apply_properties!
          end
        end

        announce_server_restart
        tellm("@a", l("SERVER IS ABOUT TO RESTART!", :red))
        async do
          sleep 5
          sync { $mcl_reboot = true }
        end
        return
      end

      if args.length < 2 || args.length > 4
        return tellm(player, l("!restore <name> <tarfile> [backup_current=true]", :red))
      end

      # get world
      unless world = iknown_worlds[args.shift]
        return tellm(player, l("Unknown world!", :red))
      end

      hsh = server.world_hash(world.name)
      sure = args.delete(hsh[0..5])
      tarfile = args.shift
      blist = world.backups
      backup_current = args.any? ? strbool(args.shift) : true
      is_current = server.world == world.name

      # find backup
      unless bf = blist.detect{|fn, f, d, s| f == tarfile }
        return tellm(player, l("This backup doesn't belong to this world or does not exist!", :red))
      end

      # ensure world hash if current version should be discarded
      if !backup_current && !sure
        tellm(player, l("WARNING: This command cannot be undone!", :red))
        tellm(player, l("To remove the world append to your command:", :gold))
        tellm(player, l("  #{hsh[0..5]}", :aqua))
        return
      end

      async_safe do
        maxstep = backup_current ? 3 : 2
        curstep = 0
        step = ->(inc = false) {
          curstep += 1 if inc
          [l("[", :gray), l("#{curstep}", :aqua), l("/", :gray), l("#{maxstep}", :aqua), l("] ", :gray)]
        }
        tellm(player, l("Restoring ", :gold), l(world.name, :light_purple), l(" with ", :gold), l(tarfile, :aqua))
        trt = Benchmark.realtime do
          # extract backup into temporary directory
          tellm(player, *step[true], l("Extracting desired backup...", :gold))
          unpacked_dir = nil
          world.unpack_backup!(bf[0]) do |ud, rt|
            unpacked_dir = ud
            tellm(player, *step[], l("Extraction done (", :gold), l(Player.fseconds(rt), :aqua), l(")!", :gold))
          end.tap(&:join)

          # backup current
          if backup_current
            tellm(player, *step[true], l("Starting backup of current version!", :gold))
            world.create_backup! do |rt|
              tellm(player, *step[], l("Backup done (", :gold), l(Player.fseconds(rt), :aqua), l(")!", :gold))
            end.tap(&:join)
          end

          # switch
          if is_current
            tellm(player, *step[true], l("Swapping files...", :gold), l(" RESTART REQUIRED!", :red))
            tellm(player, *step[], l("[restart & restore]", :light_purple, hover: "restart & restore NOW!", command: %{!world restore --post-mortem "#{world.name}" "#{unpacked_dir.gsub("#{server.root}/", "")}"}))
          else
            tellm(player, *step[true], l("Swapping files...", :gold))
            FileUtils.rm_rf(world.root)
            FileUtils.mv(unpacked_dir, world.root)
          end
        end
        tellm(player, l("Successfully restored ", :gold), l(world.name, :light_purple), l(" in ", :gold), l(Player.fseconds(trt), :aqua), l("!", :gold))
      end
    end

    def com_delete player, args
      if world = iknown_worlds[args[0] || server.world]
        hsh = server.world_hash(world.name)
        sure = args.delete(hsh[0..5])
        purge_backups = strbool(args[1])
        if world.name == server.world
          tellm(player, l("You cannot delete the current world!", :red))
        else
          if sure
            world.destroy(purge_backups) do |backups_removed|
              tellm(player, l("World#{" and #{backups_removed} backups" if backups_removed} removed!", :red))
            end
          else
            tellm(player, l("WARNING: This command cannot be undone!", :red))
            tellm(player, l("To remove the world append to your command:", :gold))
            tellm(player, l("  #{hsh[0..5]}", :aqua))
          end
        end
      else
        tellm(player, l("Unknown world!", :red))
      end
    end

    def com_activate player, args
      if world = iknown_worlds[args[0]]
        if world.name == server.world
          tellm(player, l("Already on that world!", :red))
        else
          tellm(player, l("Swapping to world ", "aqua"), l(world.name, :light_purple), l("...", :aqua))

          # update property file after server is stopped
          async do
            sleep 1 while server.alive?
            sync do
              app.log.info "[MCLiverse] Swapping world to #{world.name}..."
              sleep 1
              world.apply_properties!
              server.properties.update("level-name" => world.name)
            end
          end

          announce_server_restart
          tellm("@a", l("SERVER IS ABOUT TO RESTART!", :red))
          async do
            sleep 5
            sync { $mcl_reboot = true }
          end
        end
      else
        tellm(player, l("Unknown world!", :red))
      end
    end

    class World
      attr_reader :name, :server

      def initialize(name, server)
        @name = name
        @server = server
      end

      def root
        server.world_root(name)
      end

      def valid?
        File.exist?("#{root}/level.dat")
      end

      def sprop_path
        "#{root}/server.properties"
      end

      def sprops?
        File.exist?(sprop_path)
      end

      def apply_properties!
        File.unlink(server.properties_path) if File.symlink?(server.properties_path)
        if sprops?
          FileUtils.mv(server.properties_path, "#{server.properties_path}.restore") if File.exist?(server.properties_path)
          FileUtils.ln_s(sprop_path, server.properties_path)
        else
          FileUtils.mv("#{server.properties_path}.restore", server.properties_path) if File.exist?("#{server.properties_path}.restore")
        end
      end

      def properties
        Server::Properties.new(sprop_path)
      end

      def size
        server.world_size(name)
      end

      def fsize
        server.human_bytes size
      end

      def mtime
        File.mtime("#{root}/level.dat")
      end

      def fmtime
        _mtime = mtime
        "#{_mtime.strftime("%F %T")} (#{Player.fseconds((Time.current - _mtime).to_i)})"
      end

      def create_backup! &block
        server.backup_world(name, &block)
      end

      def unpack_backup! fn, &block
        server.decompress_backup(root, fn, &block)
      end

      def backups with_size = false
        server.backups(name, with_size)
      end

      def destroy remove_backups
        blist = backups if remove_backups
        server.world_destroy(name, remove_backups)
        yield(blist&.length) if block_given?
      end

      def backups_size list = nil
        list ||= backups(true)
        list.map{|b| b[3] }.inject(:+)
      end

      def fbackups_size list = nil
        server.human_bytes backups_size(list)
      end

      def last_backup list = nil
        list ||= backups
        return unless list.first
        "#{list.first[2].strftime("%F %T")} (#{Player.fseconds((Time.current - list.first[2]).to_i)})"
      end
    end

    module Helper
      def tellm p, *msg
        trawt(p, "MCLiverse", *msg)
      end

      def tellm_cworld(p, w = nil)
        w ||= current_world
        tellm(p, l("Current world is: ", :green), l(w.name, color: "aqua", hover: "show info", command: "!world info #{w.name}"))
      end

      def kwf
        "#{server.root}/known_worlds.mcl"
      end

      def current_world
        World.new(server.world, server)
      end

      def known_worlds
        File.exist?(kwf) ? File.readlines(kwf).reject(&:blank?).map(&:strip) : []
      end

      def iknown_worlds
        {}.tap do |r|
          known_worlds.each do |w|
            r[w] = World.new(w, server)
          end
        end
      end

      def add_known_world world
        world = world.name if world.is_a?(World)
        (known_worlds + [world]).sort.tap do |nw|
          sync { File.open(kwf, "w+") {|f| f.puts nw } }
        end
      end

      def remove_known_world world
        world = world.name if world.is_a?(World)
        cn = known_worlds
        nw = cn - [world]
        return nw if cn == nw
        sync { File.open(kwf, "w+") {|f| f.puts nw } }
        nw
      end

      def scan_worlds
        nw = $mcl.server.known_worlds
        sync { File.open(kwf, "w+") {|f| f.puts nw } }
        nw
      end

      def ll input
        case input
          when Hash then input
          when Array then input.map{|i| l(i) }
          when String then l(input)
          else raise(ArgumentError, "unknown input type #{input.class}")
        end
      end

      def l str, color_or_opts = nil, opts = {}
        if color_or_opts.is_a?(Hash)
          opts = color_or_opts
        else
          opts[:color] = color_or_opts
        end
        {}.tap do |r|
          r[:text] = str
          r[:color] = opts[:color] if opts[:color]
          r[:obfuscated] = !!opts[:obfuscated]
          if hover = opts.delete(:hover)
            r[:hoverEvent] = { action: "show_text", value: ll(hover) }
          end
          if cmd = opts.delete(:command)
            r[:clickEvent] = { action: "run_command", value: cmd }
          end
          if cmd = opts.delete(:scommand)
            r[:clickEvent] = { action: "suggest_command", value: cmd }
          end
          if url = opts.delete(:url)
            r[:clickEvent] = { action: "open_url", value: url }
          end
        end
      end
    end
    include Helper
  end
end
