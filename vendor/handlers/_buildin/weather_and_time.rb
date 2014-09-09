module Mcl
  Mcl.reloadable(:HMclWeatherAndTime)
  ## Shortcuts for weather and time commands/gamerules
  # !sun [duration=999999]
  # !rain [duration]
  # !thunder [duration]
  #
  # !time <val>
  # !morning
  # !day !noon
  # !evening
  # !midnight
  # !night
  # !freeze
  # !unfreeze
  class HMclWeatherAndTime < Handler
    def setup
      # weather
      register_sun(:member)
      register_rain(:member)
      register_thunder(:member)

      # time
      register_time(:member)
      register_morning(:member)
      register_day(:member)
      register_evening(:member)
      register_midnight(:member)
      register_night(:member)
      register_freeze(:member)
      register_unfreeze(:member)
    end

    def register_sun acl_level
      register_command :sun, desc: "Clears the weather for 11 days or given duration", acl: acl_level do |player, args|
        $mcl.server.invoke "/weather clear #{args.first || 999999}"
      end
    end

    def register_rain acl_level
      register_command :rain, desc: "Lets it rain, you may pass a duration in seconds", acl: acl_level do |player, args|
        $mcl.server.invoke "/weather rain #{args.first}"
      end
    end

    def register_thunder acl_level
      register_command :thunder, desc: "Lets it thunder, you may pass a duration in seconds", acl: acl_level do |player, args|
        $mcl.server.invoke "/weather thunder #{args.first}"
      end
    end

    def register_time acl_level
      register_command :time, desc: "sets the time", acl: acl_level do |player, args|
        if args.any?
          $mcl.server.invoke "/time set #{args.first}"
        else
          trawt(player, "Time", "!time <val>")
        end
      end
    end

    def register_morning acl_level
      register_command :morning, desc: "sets the time to 0", acl: acl_level do |player, args|
        $mcl.server.invoke "/time set 0"
      end
    end

    def register_day acl_level
      register_command :day, :noon, desc: "sets the time to 6k", acl: acl_level do |player, args|
        $mcl.server.invoke "/time set 6000"
      end
    end

    def register_evening acl_level
      register_command :evening, desc: "sets the time to 12k", acl: acl_level do |player, args|
        $mcl.server.invoke "/time set 12000"
      end
    end

    def register_night acl_level
      register_command :night, desc: "sets the time to 14k", acl: acl_level do |player, args|
        $mcl.server.invoke "/time set 14000"
      end
    end

    def register_midnight acl_level
      register_command :midnight, desc: "sets the time to 18k", acl: acl_level do |player, args|
        $mcl.server.invoke "/time set 18000"
      end
    end

    def register_freeze acl_level
      register_command :freeze, desc: "freezes the time (doDaylightCycle)", acl: acl_level do |player, args|
        $mcl.server.invoke "/gamerule doDaylightCycle false"
      end
    end

    def register_unfreeze acl_level
      register_command :unfreeze, desc: "unfreezes the time (doDaylightCycle)", acl: acl_level do |player, args|
        $mcl.server.invoke "/gamerule doDaylightCycle true"
      end
    end
  end
end
