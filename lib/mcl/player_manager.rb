module Mcl
  class PlayerManager
    attr_reader :app, :acl, :groups

    def initialize app
      @app = app
      @acl = {}
      @cache = {}
      @groups = {
        "root"    => 13333337,
        "admin"   => 1333337,
        "mod"     => 133337,
        "builder" => 13337,
        "member"  => 1337,
        "guest"   => 0,
      }
    end

    def lvlname name
      @groups.key(name.to_i) || name
    end

    def lvlval val
      return val if val.is_a?(Integer)
      @groups[val.to_s] || 0
    end

    def minlvl val
      val = lvlval(val) if val.is_a?(String)
      @groups.detect{|n, l| n if l <= val }.try(&:second)
    end

    def acl_reload
      clear_cache
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

    def acl_verify p, level = :admin
      level = lvlval(level)
      perm = acl[p] || 0
      diff = level - perm
      if diff > 0
        app.server.trawm(p, {text: "[ACL] ", color: "light_purple"}, {text: "#{diff} more magic orbs required!", color: "red"})
        throw :handler_exit, :acl
      end
      true
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
        if p.online
          p.online = false
          p.last_disconnect = Time.current

          # playtime
          p.playtime += p.session_playtime
          app.log.info "[PMAN] lost player `#{player}' after #{p.fsession_playtime}"
        end
      end
    end

    def login_user player, opts = {}
      prec(player).tap do |p|
        p.online = true
        p.ip = opts[:ip]
        p.data[:last_login_pos] = [opts[:x], y: opts[:y], z: opts[:z]]
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
