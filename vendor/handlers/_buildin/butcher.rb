module Mcl
  Mcl.reloadable(:HMclButcher)
  ## Butcher (kills entities)
  # !butcher [radius] / !butcher h/hostile [radius]
  # !butcher p/player/players [radius]
  # !butcher h/hostile [radius]
  # !butcher m/mob/mobs [radius]
  # !butcher an/animal/animals [radius]
  # !butcher b/boat/boats [radius]
  # !butcher mi/minecart/minecarts [radius]
  # !butcher i/item/items [radius]
  # !butcher x/xp [radius]
  # !butcher t/tnt [radius]
  # !butcher a/arrows [radius]
  # !butcher pr/projectiles [radius]
  class HMclButcher < Handler
    def setup
      register_butcher
    end

    def register_butcher
      register_command :butcher, desc: "Kill certain groups of entities (more info with !butcher help)", acl: :builder do |player, args|
        comm = args.shift.presence || "hostile"
        radius = args.shift.presence || "50"
        radius = nil if radius == "-"
        msg = nil

        case comm
        when "p", "player", "players"
          acl_verify(player, :admin)
          msg = "all players except you"
          butch_p(player, radius)
        when "h", "hostile"
          msg = "hostile mobs"
          butch_e(player, radius, %w[Creeper Skeleton Spider Giant Zombie Slime Ghast PigZombie Enderman CaveSpider Silverfish Blaze LavaSlime WitherBoss Witch Endermite Guardian])
        when "m", "mob", "mobs"
          msg = "mobs"
          butch_e(player, radius, %w[Bat Squid Wolf SnowMan Ozelot VillagerGolem])
        when "an", "animal", "animals"
          acl_verify(player, :mod)
          msg = "animals"
          butch_e(player, radius, %w[Pig Sheep Cow Chicken MushroomCow Rabbit])
        when "b", "boat", "boats"
          acl_verify(player, :mod)
          msg = "boats"
          butch_e(player, radius, %w[Boat])
        when "mi", "minecart", "minecarts"
          acl_verify(player, :mod)
          msg = "minecarts"
          butch_e(player, radius, %w[MinecartRideable MinecartChest MinecartFurnace MinecartTNT MinecartHopper MinecartSpawner MinecartCommandBlock])
        when "i", "item", "items", "drops"
          acl_verify(player, :mod)
          msg = "items"
          butch_e(player, radius, %w[Item])
        when "x", "xp", "orbs"
          acl_verify(player, :mod)
          msg = "xp orbs"
          butch_e(player, radius, %w[XPOrb])
        when "t", "tnt"
          acl_verify(player, :mod)
          msg = "primed TNT"
          butch_e(player, radius, %w[PrimedTnt])
        when "a", "arrow", "arrows"
          acl_verify(player, :mod)
          msg = "arrows"
          butch_e(player, radius, %w[Arrow])
        when "pr", "projectile", "projectiles"
          acl_verify(player, :mod)
          msg = "projectiles"
          butch_e(player, radius, %w[Arrow Snowball Fireball SmallFireball WitherSkull])
        else
          tellm(player, {text: "p/players [rad]", color: "gold"}, {text: " kills players", color: "reset"})
          tellm(player, {text: "h/hostile [rad]", color: "gold"}, {text: " kills hostile mobs", color: "reset"})
          tellm(player, {text: "m/mobs [rad]", color: "gold"}, {text: " kills passive but no farm mobs", color: "reset"})
          tellm(player, {text: "an/animals [rad]", color: "gold"}, {text: " kills animals", color: "reset"})
          tellm(player, {text: "b/boats [rad]", color: "gold"}, {text: " kills boats", color: "reset"})
          tellm(player, {text: "mi/minecart [rad]", color: "gold"}, {text: " kills all kinds of minecarts", color: "reset"})
          tellm(player, {text: "i/items [rad]", color: "gold"}, {text: " kills dropped items", color: "reset"})
          tellm(player, {text: "x/xp [rad]", color: "gold"}, {text: " kills XP orbs", color: "reset"})
          tellm(player, {text: "t/tnt [rad]", color: "gold"}, {text: " kills primed TNT", color: "reset"})
          tellm(player, {text: "a/arrows [rad]", color: "gold"}, {text: " kills arrows", color: "reset"})
          tellm(player, {text: "p/projectiles [rad]", color: "gold"}, {text: " kills arrows and other projectiles", color: "reset"})
        end

        if msg
          msg << " in a #{radius} block radius around you" if radius
          tellm(player, {text: "killed #{msg}.", color: "yellow"})
        end
      end
    end

    module Helper
      def tellm p, *msg
        trawt(p, "Butcher", *msg)
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
    include Helper
  end
end
