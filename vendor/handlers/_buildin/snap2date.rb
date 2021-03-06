module Mcl
  Mcl.reloadable(:HMclSnap2date)
  ## Snap2date (autoupdate minecraft server)
  # !snap2date status
  # !snap2date check [version...]
  # !snap2date watch [version...]
  # !snap2date unwatch [version...]
  # !snap2date update <version>
  # !snap2date cron
  # !snap2date uncron
  class HMclSnap2date < Handler
    attr_reader :cron, :watched_versions

    def setup
      @version_manifest = "https://launchermeta.mojang.com/mc/game/version_manifest.json"
      @announced = []
      seed_db
      setup_checker
      FileUtils.mkdir_p(version_path)
      register_snap2date(:member, status: :member, check: :member, watch: :admin, unwatch: :admin, update: :admin, cron: :admin, uncron: :admin)
    end

    def seed_db
      Setting.seed("snap2date", "snap2date.watched_versions", "")
      Setting.seed("snap2date", "snap2date.cron", "false")
      @cron = Setting.get("snap2date.cron") == "true"
      @watched_versions = Setting.fetch("snap2date.watched_versions").split(" ").sort
    end

    def setup_checker
      @tick_checked = eman.tick
      Thread.main[:snap2date_checker].try(:kill)
      Thread.main[:snap2date_checker] = @checker = async do
        loop do
          Thread.current.kill if Thread.current[:mcl_halting]
          Thread.current.kill if Thread.current != Thread.main[:snap2date_checker]
          if @cron && (eman.tick - @tick_checked) >= 250
            @tick_checked = eman.tick
            version_manifest(true)
            (watched_versions - @announced).uniq.sort.reverse.each do |ver|
              hit = released?(ver)
              $mcl.sync do
                if hit && !@announced.include?(ver)
                  @announced << ver
                  tellm("@a", {text: "#{ver.downcase}: ", color: "aqua"}, {
                    text: "RELEASED (#{hit[:date]})",
                    color: "green",
                    clickEvent: { action: "open_url", value: hit[:link] },
                    hoverEvent: { action: "show_text", value: "click to download" }
                  })
                  update(hit) if update?(hit)
                end
              end
            end
          end
          sleep 3
        end
      end
    end

    def register_snap2date acl_level, acl_levels
      register_command :snap2date, desc: "Automatic snapshot updating (more info with !snap2date)", acl: acl_level do |player, args|
        case args[0]
        when "status"
          acl_verify(player, acl_levels[:status])
          tellm(player, {text: "watched versions ", color: "gold"}, {text: watched_versions.join(" ").presence || "none", color: "reset"})
          tellm(player, {text: "watcher enabled? ", color: "gold"}, {text: cron.to_s, color: "reset"})
        when "check"
          acl_verify(player, acl_levels[:check])
          async do
            vs = args[1] ? args[1..-1] : watched_versions
            version_manifest(true)
            vs.each do |ver|
              ve = StringExpandRange.expand(ver)
              if ve.count > 30
                tellm(player, {text: "Expression result in too many items (#{ve.count}>30)...", color: "reset"})
              else
                ve.each do |v|
                  if hit = released?(v)
                    msg = {
                      text: "RELEASED (#{hit[:date]})",
                      color: "green",
                      clickEvent: { action: "open_url", value: hit[:link] },
                      hoverEvent: { action: "show_text", value: "click to download" }
                    }
                  else
                    msg = {text: "UNRELEASED", color: "red"}
                  end
                  $mcl.sync{ tellm(player, {text: "#{v.downcase}: ", color: "aqua"}, msg) }
                end
              end
            end
          end
        when "watch"
          acl_verify(player, acl_levels[:watch])
          if args[1]
            args[1..-1].each do |v|
              ve = StringExpandRange.expand(v)
              if ve.count > 30
                tellm(player, {text: "Expression result in too many items (#{ve.count}>30)...", color: "reset"})
              else
                ve.each do |v|
                  watch_version v.downcase
                  tellm(player, {text: "Watching version #{v.downcase}...", color: "reset"})
                end
              end
            end
          else
            tellm(player, {text: "Define a version to watch!", color: "red"})
          end
        when "unwatch"
          acl_verify(player, acl_levels[:unwatch])
          case args[1]
            when nil then tellm(player, {text: "Define a version to unwatch!", color: "red"})
            when "all" then vel = watched_versions
            when "old" then vel = watched_versions.reject{|v| update?(v) }
            else vel = args[1..-1]
          end
          vel.each do |v|
            ve = StringExpandRange.expand(v)
            if ve.count > 30
              tellm(player, {text: "Expression result in too many items (#{ve.count}>30)...", color: "reset"})
            else
              ve.each do |v|
                unwatch_version v.downcase
                tellm(player, {text: "Stop watching version #{v.downcase}...", color: "reset"})
              end
            end
          end
        when "update"
          acl_verify(player, acl_levels[:update])
          tellm(player, {text: "Attempting update...", color: "reset"})
          update(args[1].try(:downcase), args[2] == "force")
        when "cron"
          acl_verify(player, acl_levels[:cron])
          Setting.set("snap2date.cron", "true")
          @cron = true
          tellm(player, {text: "Watcher enabled", color: "reset"})
        when "uncron", "decron", "nocron"
          acl_verify(player, acl_levels[:uncron])
          Setting.set("snap2date.cron", "false")
          @cron = false
          tellm(player, {text: "Watcher disabled", color: "reset"})
        else
          tellm(player, {text: "status", color: "gold"}, {text: " list watched versions and watch status", color: "reset"})
          tellm(player, {text: "check [ver]", color: "gold"}, {text: " check for [ver] or all watched versions", color: "reset"})
          tellm(player, {text: "watch <ver>", color: "gold"}, {text: " start watching <ver>", color: "reset"})
          tellm(player, {text: "unwatch <ver>", color: "gold"}, {text: " stop watching <ver>", color: "reset"})
          tellm(player, {text: "update <ver>", color: "gold"}, {text: " update to <ver>", color: "reset"})
          tellm(player, {text: "cron", color: "gold"}, {text: " check versions all 250 ticks", color: "reset"})
          tellm(player, {text: "uncron", color: "gold"}, {text: " stop checking versions all 250 ticks", color: "reset"})
        end
      end
    end

    module Helper
      def watch_version ver
        @watched_versions = (@watched_versions + [ver.downcase]).uniq.sort
        Setting.set("snap2date.watched_versions", @watched_versions.join(" "))
      end

      def unwatch_version ver
        @watched_versions = (@watched_versions - [ver.downcase]).uniq.sort
        Setting.set("snap2date.watched_versions", @watched_versions.join(" "))
      end

      def tellm p, *msg
        trawm(p, title("S2D"), *msg)
      end

      # ==========
      # = Update =
      # ==========
      def version_manifest reload = false
        @_version_manifest = nil if reload
        @_version_manifest ||= begin
          {latest: {}, versions: {}}.tap do |r|
            JSON.parse(HTTParty.get(@version_manifest).body).each do |k, v|
              if k == "latest"
                r[:latest] = v.symbolize_keys
              elsif k == "versions"
                v.each do |ver|
                  r[:versions][ver["id"]] = ver.symbolize_keys
                end
              end
            end
          end
        end
      rescue StandardError => ex
        @app.log.error "[#{ex.class}] Failed to gather version manifest: #{ex.message}"
        return {}
      end

      def get_version v, details = true
        manifest = version_manifest
        if v.to_s == "latest"
          v = manifest[:latest][:release]
        elsif v.to_s == "snapshot"
          v = manifest[:latest][:snapshot]
        end

        res = manifest[:versions][v].dup
        res[:jar_name] = "minecraft_server.#{res[:id]}.jar"
        if details
          begin
            x = JSON.parse(HTTParty.get(manifest[:versions][v][:url]).body)
            res = res.merge(x.deep_symbolize_keys)
          rescue StandardError => ex
            @app.log.debug "[#{ex.class}] Failed to gather version details: #{ex.message}"
          end
        end
        res
      end

      def released? version
        vdata = get_version(version)
        {
          version: vdata[:id],
          jar_name: vdata[:jar_name],
          link: vdata.dig(:downloads, :server, :url),
          date: Time.parse(vdata[:releaseTime]),
          vdata: vdata,
        }
      rescue
        return false
      end

      def update? hit
        av = mc_comparable_version($mcl.server.version)
        sv = mc_comparable_version(hit[:version])

        if av.class == sv.class
          sv > av
        elsif av.is_a?(Gem::Version) && sv.is_a?(Integer)
          true
        else
          false
        end
      end

      def version_path
        "#{$mcl.server.root}/#{$mcl.config["mcv_infix"]}"
      end

      def update ver, force = false
        async do
          begin
            $mcl.sync do
              if $mcl_snap2date_updating
                tellm("@a", {text: "Updating failed (already updating)... ", color: "red"})
                Thread.current.kill
              end
              $mcl_snap2date_updating = true
            end

            hit = ver.is_a?(Hash) ? ver : released?(ver)
            if hit
              if force || update?(hit)
                if !File.exist?("#{version_path}#{hit[:jar_name]}") || force
                  download(hit)
                end

                # symlink
                $mcl.sync { tellm("@a", {text: "Updating... ", color: "gold"}, {text: "(linking)", color: "reset"}) }
                FileUtils.rm("#{$mcl.server.root}/minecraft_server.jar", force: true) rescue nil if Mcl.windows?
                FileUtils.ln_s "#{version_path}#{hit[:jar_name]}", "#{$mcl.server.root}/minecraft_server.jar", force: true

                # backup
                tellm("@a", {text: "Updating... ", color: "gold"}, {text: "(creating backup)", color: "reset"})
                $mcl.server.backup_world do
                  # restart
                  tellm("@a", {text: "Backup done!", color: "gold"})
                  $mcl.sync { tellm("@a", {text: "Updating... ", color: "gold"}, {text: "(restarting)", color: "reset"}) }
                  sleep 1
                  announce_server_restart
                  $mcl.sync { tellm("@a", {text: "SERVER IS ABOUT TO RESTART!", color: "red"}) }
                  sleep 5
                  $mcl.sync { $mcl_reboot = true }
                end
              else
                $mcl.sync { tellm("@a", {text: "Updating failed (version outdated)... ", color: "red"}) }
              end
            else
              $mcl.sync { tellm("@a", {text: "Updating failed (no valid version)... ", color: "red"}) }
            end
          ensure
            $mcl_snap2date_updating = false
          end
        end
      end

      def download hit, &callback
        announcer = async do
          loop do
            Thread.current.kill if Thread.current[:mcl_halting]
            if @bytes_total
              $mcl.sync { tellm("@a", {text: "Updating... ", color: "gold"}, {text: "(download #{((@bytes_transferred / @bytes_total.to_f) * 100).round(0)}%)", color: "reset"}) }
            else
              $mcl.sync { tellm("@a", {text: "Updating... ", color: "gold"}, {text: "(download init)", color: "reset"}) }
            end
            sleep 3
          end
        end

        begin
          @bytes_total = nil
          open(
            hit[:link], "rb",
            content_length_proc: ->(content_length) { @bytes_total = content_length },
            progress_proc: ->(bytes_transferred) { @bytes_transferred = bytes_transferred },
          ) do |page|
            File.open("#{version_path}#{hit[:jar_name]}", "wb") do |file|
              while chunk = page.read(1024)
                file.write(chunk)
                Thread.pass
              end
            end
          end
          $mcl.sync { tellm("@a", {text: "Updating... ", color: "gold"}, {text: "(download 100%)", color: "reset"}) }
        ensure
          announcer.try(:kill)
        end
      end
    end
    include Helper
  end
end
