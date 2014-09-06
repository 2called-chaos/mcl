module Mcl
  class PlayerManager
    attr_reader :app, :acl

    def initialize app
      @app = app
      @acl = {}
      @cache = {}
    end

    def acl_reload
      acl.clear
      Player.find_each do |p|
        acl[p.nickname] = p.permission
      end
    end

    def cleanup
      clear_cache
      Player.online.find_each do |p|
        p.update(online: false)
      end
    end

    def acl_verify p, level = 13337
      allowed = acl[p]
      allowed = allowed >= level if allowed
      unless allowed
        app.server.trawm(p, {text: "[ACL] ", color: "light_purple"}, {text: "I hate you, bugger off!", color: "red"})
        throw :handler_exit, :acl
      end
      allowed
    end

    def prec player
      @cache[player] ||= Player.where(nickname: player).first_or_initialize
    end

    def update_uuid player, uuid
      prec(player).uuid = uuid
    end

    def clear_cache save = true
      @cache.values.each(&:save) if save
      @cache.clear
    end

    def logout_user player, opts = {}
      prec(player).tap do |p|
        p.online = false
        p.last_disconnect = Time.current

        # playtime
        p.data[:playtime] += p.session_playtime
        app.log.info "[PMAN] lost player `#{player}' after #{p.fsession_playtime}"
      end
    end

    def login_user player, opts = {}
      prec(player).tap do |p|
        p.online = true
        p.ip = opts[:ip]
        p.data[:last_login_pos] = [opts[:x], y: opts[:y], z: opts[:z]]
        p.data[:playtime] ||= 0
        p.data[:connects] ||= 0
        p.data[:connects] += 1
        p.last_connect = Time.current

        # first connect
        if p.first_connect
          app.log.info "[PMAN] recognized recurring player `#{player}' (#{p.data[:connects]} connects, #{p.fplaytime} playtime)"
        else
          app.log.info "[PMAN] recognized new player `#{player}'"
          p.first_connect = Time.current
          app.async_call do
            sleep 3
            $mcl.sync do
              app.server.trawm(player, {text: "[MCL] ", color: "light_purple"}, {text: "Welcome to MCL!", color: "gold"})
              app.server.trawm(player, {text: "[MCL] ", color: "light_purple"}, {text: "Type ", color: "yellow"}, {text: "!help", color: "aqua"}, {text: " or ", color: "yellow"}, {text: "!cbook self", color: "aqua"}, {text: " to get started!", color: "yellow"})
            end
          end
        end
      end
    end
  end
end
