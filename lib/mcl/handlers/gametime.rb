module Mcl
  Mcl.reloadable(:HMMclGametime)
  class HMMclGametime < Handler
    attr_reader :fields

    def setup
      @fields = {}
      server.time = self

      # register_parser(/\AThe time is (\d+)\z/i) {|res, r| update(r[1].to_i)}
      register_parser(/\A([^\s]+) has (\d+) \[__mcl_gtime\]\z/i) {|res, r| update(r[1].to_sym, r[2].to_i)}
      register_parser(/\A\[[^\s]+: Set the time to \d+\]\z/i) { sync! }
    end

    def init
    end

    def srvrdy
      ensure_scoreboard
      sync!
    end

    def tick!
      if @fields[:pit] && @fields[:pit] < 5.minutes.ago
        $mcl.log.debug "[CORE] synchronizing gametime"
        sync!
      end
    end

    def ensure_scoreboard
      server.invoke %{scoreboard objectives add __mcl_gtime dummy}
    end

    def update field, value
      vwas = @fields[field]
      @fields[field] = value

      if field == :time
        @fields[:pit] = Time.current
        @fields[:world] = (@fields[:day] * 24_000) + @fields[:time]
      end

      $mcl.log.info "[CORE] Recognized time-#{field} `#{value}'#{" - #{translated}" if field.in?(%i[time world])} #{"(#{vwas} +- #{vwas - @fields[field]})" if vwas}"
    end

    def sync!
      @fields = { game: nil, day: nil, time: nil, world: nil }
      server.invoke %{execute store result score game __mcl_gtime run time query gametime}
      server.invoke %{execute store result score day __mcl_gtime run time query day}
      server.invoke %{execute store result score time __mcl_gtime run time query daytime}

      server.invoke %{scoreboard players get game __mcl_gtime}
      server.invoke %{scoreboard players get day __mcl_gtime}
      server.invoke %{scoreboard players get time __mcl_gtime}
    end

    def human field = :world, detail: false
      t = translated(field)
      fields = [
        "#{t[:day]}d ",
        "#{"%02d" % t[:hour]}:",
        "#{"%02d" % t[:minute]}",
      ]
      fields.unshift("#{t[:year]}y ") if t[:year] > 0

      if detail == :second
        fields << ":#{"%02d" % t[:second]}"
      elsif detail == :tick
        fields << ".#{"%02d" % t[:tick].round}"
      end

      fields.join("")
    end

    def translated field = :world
      ticks_year = 365 * 24_000
      ticks_day = 24_000
      ticks_hour = 1000
      ticks_minute = 1000/60.to_f
      ticks_second = ticks_minute / 60.to_f

      total = @fields[field] + tdelta + 6 * ticks_hour
      {
        raw: total
      }.tap do |r|
        # r[:year] = (total / ticks_year).floor
        # total %= ticks_year
        r[:year] = 0
        r[:day] = (total / ticks_day).floor
        total %= ticks_day
        r[:hour] = (total / ticks_hour).floor
        total %= ticks_hour
        r[:minute] = (total / ticks_minute).floor
        total %= ticks_minute
        r[:second] = (total / ticks_second).floor
        r[:tick] = total
      end
    end

    def tdelta
      (Time.current - @fields[:pit]) * 20
    end

    def game
      @fields[:game] + tdelta
    end

    def world
      @fields[:world] + tdelta
    end
  end
end
