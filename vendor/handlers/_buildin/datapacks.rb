module Mcl
  Mcl.reloadable(:HMclDatapacks)
  ## Centralize your datapacks across worlds and instances
  # !datapacks list [-i] [-u] [filter] [page]
  # !datapacks fetch <zipurl>
  # !datapacks cookbook
  # !datapacks install <pack> [--dev symlink instead of copy]
  # !datapacks uninstall <pack>
  # !datapacks purge <pack>
  class HMclDatapacks < Handler
    COOKBOOK = [
      [
        { caption: "MCL provided packs" },
        {
          name: "Recipe: Notch Apple",
          zip: "mcl://recipe-notch_apple",
          src: "https://github.com/mclistener/mcl-dp-recipe-notch_apple",
        },
        {
          name: "Gameplay: No Phantoms",
          zip: "mcl://gameplay-no_phantoms",
          src: "https://github.com/mclistener/mcl-dp-gameplay-no_phantoms",
        },
        {
          name: "FunAdv: Wait. That's illegal.",
          zip: "mcl://funadv-thats_illegal",
          src: "https://github.com/mclistener/mcl-dp-funadv-thats_illegal",
        },
      ],
      [
        { caption: "MadCatGaming", url: "https://www.madcatgaming.com/data-packs/" },
        {
          name: "One Player Sleep v3 (1.13+ / 1.14)",
          zip: "https://github.com/MadCatHoG/OnePlayerSleepv3-Data-Pack/raw/master/releases/OnePlayerSleepv3.zip",
          src: "https://www.madcatgaming.com/one-player-sleep-data-pack/",
        },
        {
          name: "One Player Sleep v2.1 (1.13, simple version)",
          zip: "https://github.com/MadCatHoG/OnePlayerSleepv3-Data-Pack/raw/master/releases/OnePlayerSleepv2.1.zip",
          src: "https://www.madcatgaming.com/one-player-sleep-data-pack/",
        },
        {
          name: "Player Head Drops v3",
          zip: "https://github.com/MadCatHoG/PlayerHeadDropsV3-Data-Pack/raw/master/releases/PlayerHeadDropsV3.zip",
          src: "https://github.com/MadCatHoG/PlayerHeadDropsV3-Data-Pack",
        },
        {
          name: "Mob Head Drops v2 (easy)",
          zip: "https://github.com/MadCatHoG/MobHeadDropsV2-Data-Pack/raw/master/releases/MobHeadDropsV2-Easy.zip",
          src: "https://github.com/MadCatHoG/MobHeadDropsV2-Data-Pack",
        },
        {
          name: "Mob Head Drops v2 (normal)",
          zip: "https://github.com/MadCatHoG/MobHeadDropsV2-Data-Pack/raw/master/releases/MobHeadDropsV2-Normal.zip",
          src: "https://github.com/MadCatHoG/MobHeadDropsV2-Data-Pack",
        },
        {
          name: "Mob Head Drops v2 (hard)",
          zip: "https://github.com/MadCatHoG/MobHeadDropsV2-Data-Pack/raw/master/releases/MobHeadDropsV2-Hard.zip",
          src: "https://github.com/MadCatHoG/MobHeadDropsV2-Data-Pack",
        },
      ],
    ]

    def setup
      register_datapacks(:root)
    end

    def register_datapacks acl_level
      register_command :dp, :datapack, :datapacks, desc: "Add/remove datapacks ", acl: acl_level do |player, args, handler|
        case args[0]
        when "list", "fetch", "cookbook", "install", "uninstall", "purge"
          handler.send("com_#{args[0]}", player, args[1..-1])
        else
          tellm(player, l("list [-i nstalled] [-u ninstalled] [filter] [page]", :gold), l(" list DPs"))
          tellm(player, l("fetch <zipurl>", :gold), l(" download a DP zip file (must be direct URL)"))
          tellm(player, l("cookbook", :gold), l(" fetch useful DPs at a glance"))
          tellm(player, l("install <pack>", :gold), l(" install a DP from the pool into the current world"))
          tellm(player, l("uninstall <pack>", :gold), l(" uninstalls a DP from the current world"))
          tellm(player, l("purge <pack>", :gold), l(" remove a pack from the pool, will not uninstall from worlds!"))
        end
      end
    end

    def com_cookbook player, args
      $mcl.server.invoke %{/clear #{player} minecraft:written_book{title:"Datapack Cookbook",author:"MCL"}}
      $mcl.server.invoke book(player, "Datapack Cookbook", cookbook_data, author: "MCL")
    end

    def com_fetch player, args
      refreshBook = args.delete("--rcb")
      zipfile = args.join(" ")
      if args.empty?
        return tellm(player, l("!dp fetch <zipurl>", :red))
      end

      # translate mcl protocol
      if m = zipfile.match(/\Amcl:\/\/([^\/]+)\z/i)
        filename ||= mclp2zipname(zipfile)
        zipfile = "https://github.com/mclistener/mcl-dp-#{m[1]}/raw/master/releases/current.zip"
      end

      # prepend https if protocol is missing
      if !zipfile.start_with?("http://", "https://", "ftp://")
        zipfile = "https://#{zipfile}"
      end
      filename ||= File.basename(zipfile)

      # Check if file exists
      if File.exists?("#{pool_root}/#{filename}")
        return tellm(player, l("There is already a DP with this name, ", :red), l("purge it", :light_purple, hover: "purge now", command: "!dp purge #{"--rcb " if refreshBook}#{filename}"), l(" first?", :red))
      end

      fpath = "#{pool_root}/#{filename}"
      async_safe do
        # fetch
        begin
          rt = Benchmark.realtime do
            File.open("#{fpath}.tmp", "wb") do |file|
              hr = HTTParty.get(zipfile, stream_body: true) do |fragment|
                file.write(fragment) if fragment.code == 200
              end
              raise "Download failed: got response #{hr.code} - #{hr.message}" if hr.code != 200
            end
          end
          tellm(player, l("Downloaded file in ", :yellow), l(Player.fseconds(rt), :aqua))

          # verify file
          sync do
            headers = IO.binread("#{fpath}.tmp", 4).bytes
            if headers == [0x50, 0x4b, 0x03, 0x04]
              FileUtils.mv("#{fpath}.tmp", fpath)
              com_cookbook(player, []) if refreshBook
              tellm(player, l("Success! File added to pool.", :green))
              tellm(player, l("[install now]", :aqua, hover: "install to current world: #{File.basename(fpath)}", command: "!dp install #{File.basename(fpath)}"))
            elsif headers == [0x50, 0x4b, 0x03, 0x06]
              # empty archive?
              tellm(player, l("Failed: empty or corrupted archive", :red))
            else
              tellm(player, l("Failed: not a zip or a corrupted zip file", :red))
            end
          end
        rescue Exception
          tellm(player, l($!.message, :red))
        ensure
          if File.exist?("#{fpath}.tmp")
            File.unlink("#{fpath}.tmp") rescue false
          end
        end
      end
    end

    def com_install player, args
      dev = args.delete("--dev")
      pack = args.join(" ")
      if available_packs.include?(pack)
        if installed_packs.include?(pack)
          tellm(player, l("This datapack is already installed!", :red))
        else
          if FileTest.directory?("#{pool_root}/#{pack}")
            FileUtils.send(dev ? :ln_s : :cp_r, "#{pool_root}/#{pack}", "#{server.world_root}/datapacks/")
          elsif FileTest.file?("#{pool_root}/#{pack}") && pack.downcase.ends_with?(".zip")
            FileUtils.send(dev ? :ln_s : :cp, "#{pool_root}/#{pack}", "#{server.world_root}/datapacks/")
          else
            return tellm(player, l("Datapack isn't a directory nor a zip file, aborting!", :red))
          end
          server.invoke "reload"
          tellm(player, l("Datapack successfully installed!", :green))
        end
      else
        tellm(player, l("This datapack does not exist in the pool!", :red))
      end
    end

    def com_uninstall player, args
      pack = args.join(" ")
      if installed_packs.include?(pack)
        path = "#{server.world_root}/datapacks/#{pack}"
        if FileTest.directory?(path)
          FileUtils.rm_r(path)
        elsif FileTest.file?(path) && pack.downcase.ends_with?(".zip")
          File.unlink(path)
        elsif FileTest.symlink?(path)
          File.unlink(path)
        else
          return tellm(player, l("Datapack isn't a directory nor a zip file, aborting!", :red))
        end
        server.invoke "reload"
        tellm(player, l("Datapack successfully uninstalled!", :green))
      else
        tellm(player, l("This datapack is not installed!", :red))
      end
    end

    def com_purge player, args
      refreshBook = args.delete("--rcb")
      pack = args.join(" ")
      if available_packs.include?(pack)
        path = "#{pool_root}/#{pack}"
        if FileTest.directory?(path)
          FileUtils.rm_r(path)
        elsif FileTest.file?("#{pool_root}/#{pack}") && pack.downcase.ends_with?(".zip")
          File.unlink(path)
        else
          return tellm(player, l("Datapack isn't a directory nor a zip file, aborting!", :red))
        end
        tellm(player, l("Datapack successfully purged!", :green))
        tellm(player, l("Note: The pack will NOT be uninstalled from worlds that already have it installed!", :yellow))
        com_cookbook(player, []) if refreshBook
      else
        tellm(player, l("This datapack does not exist in the pool!", :red))
      end
    end

    def com_list player, args
      opt = OptionParser.new
      which = :all
      opt.on("-i") { which = :installed }
      opt.on("-u") { which = :uninstalled }
      args = coord_save_optparse!(opt, args)
      page, filter = 1, nil

      # filter
      if args[0] && args[0].to_i == 0
        filter = /#{args[0]}/i
        page = (args[1] || 1).to_i
      else
        page = (args[0] || 1).to_i
      end

      # packs
      ilist = installed_packs
      alist = available_packs
      spacks = [].tap do |r|
        if [:all, :installed].include?(which)
          ilist.each{|p| r << list_row(p, true) if !filter || p.to_s.match(filter) }
        end
        if [:all, :uninstalled].include?(which)
          alist.each do |p|
            next if which == :all && ilist.include?(p)
            r << list_row(p, false) if !filter || p.to_s.match(filter)
          end
        end
      end

      # paginate
      page_contents = spacks.in_groups_of(7, false)
      pages = (spacks.count/7.0).ceil

      if spacks.any?
        tellm(player, l("--- Showing datapacks page #{page}/#{pages} (#{spacks.count} packs) ---", :aqua))
        (page_contents[page-1]||[]).each {|pack| tellm(player, *pack) }
      else
        tellm(player, l("No datapacks found for that filter/page!", :red))
      end
    end

    module Helper
      def tellm p, *msg
        trawt(p, "Datapacks", *msg)
      end

      def installed_packs
        Dir["#{server.world_root}/datapacks/*"].select do |f|
          FileTest.directory?(f) || (File.file?(f) && f.downcase.ends_with?(".zip")) || File.symlink?(f)
        end.map{|x| File.basename(x) }
      end

      def available_packs
        Dir["#{pool_root}/*"].select do |f|
          FileTest.directory?(f) || (File.file?(f) && f.downcase.ends_with?(".zip"))
        end.map{|x| File.basename(x) }
      end

      def pool_root
        "#{ROOT}/vendor/datapacks"
      end

      def list_row fn, installed = false
        r = [].tap do |r|
          basename = File.basename(fn)
          if installed
            r << l("U", :red, hover: "uninstall from current world", command: "!dp uninstall #{basename}")
          else
            r << l("I", :green, hover: "install into current world", command: "!dp install #{basename}")
          end
          r << l(" " << basename, :yellow)
          if installed && !server.datapacks.include?(basename)
            r << l(" ") << l("DISABLED", :red, hover: "Warning: this datapack got disabled via /datapack command, click to enable via !raw", command: "!raw datapack enable \"file/#{basename}\"")
          end
        end
      end

      def mclp2zipname zipfile
        if m = zipfile.match(/\Amcl:\/\/([^\/]+)\z/i)
          "mcl-#{m[1]}.zip"
        end
      end

      def cookbook_data
        [].tap do |pages|
          page = []
          COOKBOOK.each do |_category|
            category = _category.dup
            cap = category.shift
            category.each do |data|
              page << _cc(cap) if page.empty? && cap
              page << _c(data)
              if page.length >= 13
                pages << page.join("\n")
                page.clear
              end
            end
            pages << page.join("\n") unless page.empty?
            page.clear
          end
          pages << page.join("\n") unless page.empty?
        end
      end

      def _cc data
        if data[:url]
          click = %{, "clickEvent":{"action":"open_url", "value":"#{data[:url]}"}}
        end

        if data[:hover]
          hover = %{, "hoverEvent":{"action":"show_text","value":"#{data[:hover]}"}}
        else
          hover = %{, "hoverEvent":{"action":"show_text","value":"#{data[:caption]}"}}
        end
        %Q{{"text": "#{data[:caption].truncate(20)}\\n", "color": "#{click ? "dark_blue" : "black"}"#{hover}#{click}}}
      end

      def _c data
        [].tap do |r|
          alist = available_packs
          fn = File.basename(data[:zip])
          fnb = fn.gsub(/\.zip\z/i, "")
          pfn = mclp2zipname(data[:zip])
          if alist.include?(fn) || alist.include?(fnb) || alist.include?(pfn)
            r << %Q{{"text": "P", "color": "dark_red", "hoverEvent":{"action":"show_text","value":"purge from pool"}, "clickEvent":{"action":"run_command", "value":"!dp purge --rcb #{pfn ? pfn : File.basename(data[:zip])}"}}}
          else
            r << %Q{{"text": "F", "color": "light_purple", "hoverEvent":{"action":"show_text","value":"fetch/download"}, "clickEvent":{"action":"run_command", "value":"!dp fetch --rcb #{data[:zip]}"}}}
          end
          srcclick = data[:src] ? %Q{, "clickEvent":{"action":"open_url", "value":"#{data[:src]}"}} : nil
          r << %Q{{"text": " "}}
          r << %Q{{"text": "#{data[:name].truncate(18)}\\n", "color": "aqua", "hoverEvent":{"action":"show_text","value":"#{data[:name]}"}#{srcclick}}}
        end.join(",")
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
