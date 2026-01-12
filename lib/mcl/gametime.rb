module Mcl
  class Gametime
    attr_reader :app
    delegate :server, to: :app

    def initialize app
      @app = app
      @gametime = -1
      @gametime_at = nil
    end

    def ticks
      return if @gametime < 0
      tdelta = Time.current - @gametime_at
      @gametime + tdelta * 20
    end

    def sync!
      @waiting_for_gametime = true
      server.invoke %{time query gametime}
    end

    def update *args
      return unless @waiting_for_gametime
      @waiting_for_gametime = false
      update!(*args)
    end

    def update! time, pit = nil
      gtwas = ticks
      @gametime = time
      @gametime_at = pit || Time.current
      $mcl.log.info "[CORE] Recognized gametime `#{@gametime}' - #{translated} #{"(#{gtwas} +- #{gtwas - @gametime})" if gtwas}"
    end

    def human
      t = translated
      "#{t[:day]}d #{t[:hour]}:#{t[:minute]}.#{t[:tick].round}"
    end

    def translated
      total = ticks
      {
        raw: total
      }.tap do |r|
        ticks_day = 20 * 60 * 24
        ticks_hour = 20 * 60
        ticks_minute = 20

        r[:days] = (total / ticks_day).floor
        total %= ticks_day
        r[:hour] = (total / ticks_hour).floor
        total %= ticks_hour
        r[:minute] = (total / ticks_minute).floor
        total %= ticks_minute
        r[:tick] = total
      end
    end
  end
end
