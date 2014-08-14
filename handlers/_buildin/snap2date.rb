module Mcl
  Mcl.reloadable(:HSnap2date)
  class HSnap2date < Handler
    attr_reader :cron, :watched_versions

    def setup
      @snapurl = "https://s3.amazonaws.com/Minecraft.Download/versions/%VERSION%/minecraft_server.%VERSION%.jar"
      @announced = []
      seed_db
      setup_parsers
      setup_checker
    end

    def seed_db
      Setting.seed("snap2date", "snap2date.watched_versions", "")
      Setting.seed("snap2date", "snap2date.cron", "false")
      @cron = Setting.get("snap2date.cron") == "true"
      @watched_versions = Setting.fetch("snap2date.watched_versions").split(" ")
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
            (watched_versions - @announced).each do |ver|
              hit = released?(ver)
              $mcl.synchronize do
                if hit && !@announced.include?(ver)
                  @announced << ver
                  tellm("@a", {text: "#{ver.downcase}: ", color: "light_purple"}, {
                    text: "RELEASED (#{hit[:date]})",
                    color: "green",
                    clickEvent: { action: "open_url", value: hit[:link] },
                    hoverEvent: { action: "show_text", value: "click to download" }
                  })
                end
              end
            end
          end
          sleep 3
        end
      end
    end

    def setup_parsers
      register_command :snap2date do |handler, player, command, target, optparse|
        handler.acl_verify(player)
        args = command.split(" ")[1..-1]

        case args[0]
        when "status"
          handler.tellm(player, {text: "watched versions ", color: "gold"}, {text: handler.watched_versions.join(" ").presence || "none", color: "reset"})
          handler.tellm(player, {text: "watcher enabled? ", color: "gold"}, {text: handler.cron.to_s, color: "reset"})
        when "check"
          handler.async do
            handler.watched_versions.each do |ver|
              if hit = released?(ver)
                msg = {
                  text: "RELEASED (#{hit[:date]})",
                  color: "green",
                  clickEvent: { action: "open_url", value: hit[:link] },
                  hoverEvent: { action: "show_text", value: "click to download" }
                }
              else
                msg = {text: "UNRELEASED", color: "red"}
              end
              $mcl.synchronize{ handler.tellm(player, {text: "#{ver.downcase}: ", color: "light_purple"}, msg) }
            end
          end
        when "watch"
          if args[1]
            args[1..-1].each do |v|
              handler.watch_version v.downcase
              handler.tellm(player, {text: "Watching version #{v.downcase}...", color: "reset"})
            end
          else
            handler.tellm(player, {text: "Define a version to watch!", color: "red"})
          end
        when "unwatch"
          if args[1]
            args[1..-1].each do |v|
              handler.unwatch_version v.downcase
              handler.tellm(player, {text: "Stop watching version #{v.downcase}...", color: "reset"})
            end
          else
            handler.tellm(player, {text: "Define a version to watch!", color: "red"})
          end
        when "update"
          handler.tellm(player, {text: "Watcher disabled", color: "reset"})
          # @todo UPDATE
        when "cron"
          Setting.set("snap2date.cron", "true")
          @cron = true
          handler.tellm(player, {text: "Watcher enabled", color: "reset"})
        when "uncron"
          Setting.set("snap2date.cron", "false")
          @cron = false
          handler.tellm(player, {text: "Watcher disabled", color: "reset"})
        else
          handler.tellm(player, {text: "status", color: "gold"}, {text: " list watched versions and watch status", color: "reset"})
          handler.tellm(player, {text: "check [ver]", color: "gold"}, {text: " check for [ver] or all watched versions", color: "reset"})
          handler.tellm(player, {text: "watch <ver>", color: "gold"}, {text: " start watching <ver>", color: "reset"})
          handler.tellm(player, {text: "unwatch <ver>", color: "gold"}, {text: " stop watching <ver>", color: "reset"})
          handler.tellm(player, {text: "update <ver>", color: "gold"}, {text: " update to <ver>", color: "reset"})
          handler.tellm(player, {text: "cron", color: "gold"}, {text: " check versions all 250 ticks", color: "reset"})
          handler.tellm(player, {text: "uncron", color: "gold"}, {text: " stop checking versions all 250 ticks", color: "reset"})
        end
      end
    end

    def watch_version ver
      @watched_versions = @watched_versions + [ver.downcase]
      Setting.set("snap2date.watched_versions", @watched_versions.join(" "))
    end

    def unwatch_version ver
      @watched_versions = @watched_versions - [ver.downcase]
      Setting.set("snap2date.watched_versions", @watched_versions.join(" "))
    end

    def title
      {text: "[S2D] ", color: "light_purple"}.to_json
    end

    def spacer
      {text: " / ", color: "reset"}.to_json
    end

    def tellm p, *msg
      $mcl.server.invoke %{/tellraw #{p} [#{title},#{msg.map(&:to_json).join(",")}]}
    end


    # ==========
    # = Update =
    # ==========
    def url_for_version version
      @snapurl.gsub("%VERSION%", version)
    end

    def uri_for_version version
      URI.parse(url_for_version(version))
    end

    def released? version
      uri = uri_for_version(version)
      Net::HTTP.start(uri.host) do |http|
        req = Net::HTTP::Head.new(uri)
        res = http.request(req)

        if res.code.to_i == 200
          {
            version: version,
            link: url_for_version(version),
            date: Time.parse(res["Last-Modified"]),
          }
        else
          false
        end
      end
    end
  end
end
