module Mcl
  class Promise
    attr_accessor :tick, :tries, :opts

    def initialize app, opts = {}, &block
      @app = app
      @opts = opts.reverse_merge(tries: 50, ticks: 10)
      @tick = $mcl.eman.tick
      @tries = 0
      @alive = true
      block.try(:call, self)
    end

    def alive?
      @alive
    end

    def condition &block
      @condition = block
    end

    def callback &block
      @callback = block
    end

    def kill
      @condition = ->{ true }
      @alive = false
    end

    def tick!
      @tries += 1
      return unless alive?
      kill if @tries > @opts[:tries] || ($mcl.eman.tick - @tick) > @opts[:ticks]

      if c = @condition.call || !alive?
        kill
        @callback.call(c)
      end
    end
  end
end
