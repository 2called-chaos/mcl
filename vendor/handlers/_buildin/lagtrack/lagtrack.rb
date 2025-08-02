#
module Mcl
  Mcl.reloadable(:HMclLagtrack)
  ## Lagtrack (tracks minecraft server lag)
  # !lagtrack
  # !lagtrack help
  # !lagtrack log [-w <world>] [-m <max_entries=42>]
  # !lagtrack announce [<target>|false]
  # !lagtrack stat [-w <world>] [-d <days>|-h <hours=12>]
  class HMclLagtrack < Handler
    def setup
      seed_db
      setup_parser
      register_lagtrack(:member, log: :mod, announce: :admin, stat: :mod)
    end

    def seed_db
      Setting.seed("lagtrack", "lagtrack.announce", "@a")
      update_announce
    end

    def setup_parser
      register_parser(/^Can't keep up! Is the server overloaded\? Running ([\d]+)ms or ([\d]+) tick(?:s)? behind/i) do |res, r|
        handle_incident(r)
      end
      register_parser(/^Can't keep up! Did the system time change, or is the server overloaded\? Running ([\d]+)ms behind, skipping ([\d]+) tick\(s\)/i) do |res, r|
        handle_incident(r)
      end
    end

    def handle_incident r
      log = LagtrackLog.create!(delay: r[1].to_i, skipped_ticks: r[2].to_i, tracked_at: Time.current, world: $mcl.server.world)
      $mcl.log.info "[Lagtrack] Running #{log.delay}ms behind, skipping #{log.skipped_ticks} tick(s)"
      if @announce
        tellm(@announce,
          {text: "Running ", color: "red"}, {text: "#{log.delay}ms", color: "aqua"},
          {text: " behind, skipping ", color: "red"}, {text: "#{log.skipped_ticks}", color: "aqua"}, {text: " tick(s)", color: "red"}
        )
      end
    end

    def register_lagtrack acl_level, acl_levels
      register_command :lagtrack, desc: "Keeps track of minecraft server lag", acl: acl_level do |player, args|
        case args[0]
        when "announce"
          acl_verify(player, acl_levels[:announce])
          update_announce(args[1]) if args[1]
          if @announce
            tellm(player, {text: "lag announcements will be send to ", color: "yellow"}, {text: @announce, color: "aqua"})
          else
            tellm(player, {text: "lag announcements are ", color: "yellow"}, {text: "disabled", color: "red"})
          end
        when "stat"
          acl_verify(player, acl_levels[:stat])
          com_stat player, args.dup
        when "log"
          acl_verify(player, acl_levels[:log])
          logbook(player, args.dup)
        when "help"
          tellm(player, {text: "log [-w <world>] [-m <max_entries=42>]", color: "gold"}, {text: " give you an incident logbook"})
          tellm(player, {text: "stat [-w <world>] [-d <days>|-h <hours=12>]", color: "gold"}, {text: " aggregated data"})
          tellm(player, {text: "announce [<target>|false]", color: "gold"}, {text: " announce lag via chat"})
        else
          com_stat(player, %w[-h 1])
        end
      end
    end

    module Helper
      def update_announce val = nil
        Setting.set("lagtrack.announce", val) unless val.nil?
        @announce = Setting.get("lagtrack.announce")
        @announce = false if @announce == "false"
      end

      def tellm p, *msg
        trawm(p, title("Lagtrack"), *msg)
      end

      def logbook player, args
        world, max_entries = nil, 42
        opt = OptionParser.new
        opt.on("-w WORLD", String) {|v| world = v }
        opt.on("-m MAX_ENTRIES", Integer) {|v| max_entries = v }
        opt.parse!(args)

        logs = LagtrackLog.order(tracked_at: :desc)
        logs = logs.for_world(world) if world
        logs = logs.limit(max_entries)

        if logs.any?
          pages = []
          logs.in_groups_of(14, false).each do |group|
            page = []
            group.each_with_index do |log, i|
              page << %Q{{"text": "#{log.tracked_at.strftime("%F %T")}\\n", "color": "#{i % 2 == 0 ? "blue" : "dark_blue"}", "hoverEvent":{"action":"show_text", "value": "Ran behind #{log.delay}ms and skipped #{log.skipped_ticks} tick(s)\\n(#{Player.fseconds(Time.current - log.tracked_at)} ago)"}}}
            end
            pages << page.join("\n")
          end
          $mcl.server.invoke book(player, "Incident Logbook", pages, author: "Lagtrack")
        else
          tellm(player, {text: "No log entries found.", color: "red"})
        end
      end

      def com_stat player, args
        world, days, hours = nil, nil, 12
        opt = OptionParser.new
        opt.on("-w WORLD", String) {|v| world = v }
        opt.on("-d DAYS", Integer) {|v| days = v }
        opt.on("-h HOURS", Integer) {|v| hours = v }
        opt.parse!(args)

        res = stat_log(world, days, hours)
        tell = []
        tell << {text: "#{res[:incidents]}", color: "aqua"}
        tell << {text: " incidents in the last ", color: "yellow"}
        tell << {text: "#{res[:scale]}", color: "aqua"}
        tell << {text: " for world ", color: "yellow"} if world
        tell << {text: "#{world}", color: "aqua"} if world
        tellm(player, *tell)

        if res[:incidents] > 0
          tellm(player,
            {text: "Ran behind for a total of ", color: "yellow"},
            {text: "#{res[:delay]}ms", color: "aqua"},
            {text: " and skipped ", color: "yellow"},
            {text: "#{res[:skipped_ticks]}", color: "aqua"},
            {text: " tick(s).", color: "yellow"}
          )
        end
      end

      def stat_log world, days, hours
        {world: world, incidents: 0, delay: 0, skipped_ticks: 0}.tap do |res|
          if days
            logs = LagtrackLog.where("tracked_at > ?", days.days.ago)
            res[:scale] = "#{days} day(s)"
          else
            logs = LagtrackLog.where("tracked_at > ?", hours.hours.ago)
            res[:scale] = "#{hours} hour(s)"
          end
          logs = logs.for_world(world) if world
          res[:incidents] += logs.count
          res[:delay] += logs.sum(:delay)
          res[:skipped_ticks] += logs.sum(:skipped_ticks)
        end
      end
    end
    include Helper
  end
end
