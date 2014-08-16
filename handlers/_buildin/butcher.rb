module Mcl
  Mcl.reloadable(:HButcher)
  class HButcher < Handler
    attr_reader :cron, :watched_versions

    def setup
      setup_parsers
    end

    def setup_parsers
      register_command :butcher, desc: "Kill certain groups of entities (more info with !butcher help)" do |handler, player, command, target, optparse|
        handler.acl_verify(player)
        args = command.split(" ")[1..-1]
        comm = args.shift.presence || "mobs"
        radius = args.shift.presence || "128"
        radius = nil if radius == "-"
        msg = nil

        case comm
        when "p", "player", "players"
          msg = "all players except you"
          handler.butch_p(player, radius)
        when "h", "hostile"
          msg = "hostile mobs"
          handler.butch_e(player, radius, %w[Creeper Skeleton Spider Giant Zombie Slime Ghast PigZombie Enderman CaveSpider Silverfish Blaze LavaSlime WitherBoss Witch Endermite Guardian])
        when "m", "mob", "mobs"
          msg = "mobs"
          handler.butch_e(player, radius, %w[Bat Squid Wolf SnowMan Ozelot VillagerGolem])
        when "an", "animal", "animals"
          msg = "animals"
          handler.butch_e(player, radius, %w[Pig Sheep Cow Chicken MushroomCow Rabbit])
        when "b", "boat", "boats"
          msg = "boats"
          handler.butch_e(player, radius, %w[Boat])
        when "mi", "minecart", "minecarts"
          msg = "minecarts"
          handler.butch_e(player, radius, %w[MinecartRideable MinecartChest MinecartFurnace MinecartTNT MinecartHopper MinecartSpawner MinecartCommandBlock])
        when "i", "item", "items", "drops"
          msg = "items"
          handler.butch_e(player, radius, %w[Item])
        when "x", "xp", "orbs"
          msg = "xp orbs"
          handler.butch_e(player, radius, %w[XPOrb])
        when "t", "tnt"
          msg = "primed TNT"
          handler.butch_e(player, radius, %w[PrimedTnt])
        when "a", "arrow", "arrows"
          msg = "arrows"
          handler.butch_e(player, radius, %w[Arrow])
        when "pr", "projectile", "projectiles"
          msg = "projectiles"
          handler.butch_e(player, radius, %w[Arrow Snowball Fireball SmallFireball WitherSkull])
        else
          handler.tellm(player, {text: "p/players [rad]", color: "gold"}, {text: " kills players", color: "reset"})
          handler.tellm(player, {text: "h/hostile [rad]", color: "gold"}, {text: " kills hostile mobs", color: "reset"})
          handler.tellm(player, {text: "m/mobs [rad]", color: "gold"}, {text: " kills passive but no farm mobs", color: "reset"})
          handler.tellm(player, {text: "an/animals [rad]", color: "gold"}, {text: " kills animals", color: "reset"})
          handler.tellm(player, {text: "b/boats [rad]", color: "gold"}, {text: " kills boats", color: "reset"})
          handler.tellm(player, {text: "mi/minecart [rad]", color: "gold"}, {text: " kills all kinds of minecarts", color: "reset"})
          handler.tellm(player, {text: "i/items [rad]", color: "gold"}, {text: " kills dropped items", color: "reset"})
          handler.tellm(player, {text: "x/xp [rad]", color: "gold"}, {text: " kills XP orbs", color: "reset"})
          handler.tellm(player, {text: "t/tnt [rad]", color: "gold"}, {text: " kills primed TNT", color: "reset"})
          handler.tellm(player, {text: "a/arrows [rad]", color: "gold"}, {text: " kills arrows", color: "reset"})
          handler.tellm(player, {text: "p/projectiles [rad]", color: "gold"}, {text: " kills arrows and other projectiles", color: "reset"})
        end

        if msg
          msg << " in a #{radius} block radius around you" if radius
          handler.tellm(player, {text: "killed #{msg}.", color: "yellow"})
        end
      end
    end



    def title
      {text: "[Butcher] ", color: "light_purple"}
    end

    def tellm p, *msg
      trawm(p, *([title] + msg))
    end

    def butch_e player, radius, which
      which.each do |w|
        $mcl.server.invoke %{/execute #{player} ~ ~ ~ kill @e[type=#{w}#{",r=#{radius}" if radius}]}
      end
    end

    def butch_p player, radius
      $mcl.server.invoke %{/execute #{player} ~ ~ ~ kill @p[name=!#{player}#{",r=#{radius}" if radius}]}
    end
  end
end
