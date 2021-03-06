module Mcl
  Mcl.reloadable(:HMclButcher)
  ## Butcher (kills entities)
  # !butcher [radius] / !butcher h/hostile [radius]
  # !butcher p/player/players [radius]
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
          types = %w[]
        when "h", "hostile"
          msg = "hostile mobs"
          butch_e(player, radius, %w[blaze cave_spider creeper drowned elder_guardian enderman endermite evocation_illager evoker ghast giant guardian husk illusion_illager illusioner magma_cube phantom shulker silverfish skeleton slime spider stray vex vindication_illager vindicator witch wither wither_skeleton zombie zombie_pigman zombie_villager])
        when "b", "bat", "bats"
          msg = "bats"
          butch_e(player, radius, %w[bat])
        when "m", "mob", "mobs"
          acl_verify(player, :admin)
          msg = "mobs"
          butch_e(player, radius, %w[bat cod dolphin donkey horse iron_golem llama mule ocelot parrot polar_bear pufferfish salmon skeleton_horse snow_golem snowman squid turtle tropical_fish villager_golem wolf zombie_horse])
        when "an", "animal", "animals"
          acl_verify(player, :mod)
          msg = "animals"
          butch_e(player, radius, %w[chicken cow mooshroom pig rabbit sheep])
        when "as", "armor_stand", "armor_stands"
          acl_verify(player, :mod)
          msg = "armor stands"
          butch_e(player, radius, %w[armor_stand])
        when "aec", "area_effect_cloud", "area_effect_clouds"
          acl_verify(player, :mod)
          msg = "area effect clouds"
          butch_e(player, radius, %w[area_effect_clouds])
        when "b", "boat", "boats"
          acl_verify(player, :mod)
          msg = "boats"
          butch_e(player, radius, %w[boat])
        when "mi", "minecart", "minecarts"
          acl_verify(player, :mod)
          msg = "minecarts"
          butch_e(player, radius, %w[minecart chest_minecart furnace_minecart hopper_minecart commandblock_minecart command_block_minecart spawner_minecart tnt_minecart])
        when "i", "item", "items", "drops"
          acl_verify(player, :mod)
          msg = "items"
          butch_e(player, radius, %w[item])
        when "x", "xp", "orbs"
          acl_verify(player, :mod)
          msg = "xp orbs"
          butch_e(player, radius, %w[xp_orb experience_orb])
        when "t", "tnt"
          acl_verify(player, :mod)
          msg = "primed TNT"
          butch_e(player, radius, %w[tnt])
        when "v", "villager", "villagers"
          acl_verify(player, :mod)
          msg = "villagers"
          butch_e(player, radius, %w[villager])
        when "a", "arrow", "arrows"
          acl_verify(player, :mod)
          msg = "arrows"
          butch_e(player, radius, %w[arrow spectral_arrow])
        when "pr", "projectile", "projectiles"
          acl_verify(player, :mod)
          msg = "projectiles"
          butch_e(player, radius, %w[arrow dragon_fireball egg ender_pearl evocation_fangs evoker_fangs experience_bottle eye_of_ender eye_of_ender_signal fireball fireworks_rocket lightning_bolt llama_spit potion shulker_bullet small_fireball snowball spectral_arrow trident wither_skull xp_bottle])
        else
          tellm(player, {text: "p/players [rad]", color: "gold"}, {text: " kills players", color: "reset"})
          tellm(player, {text: "h/hostile [rad]", color: "gold"}, {text: " kills hostile mobs", color: "reset"})
          tellm(player, {text: "b/bats [rad]", color: "gold"}, {text: " kills bats", color: "reset"})
          tellm(player, {text: "m/mobs [rad]", color: "gold"}, {text: " kills passive but no farm mobs", color: "reset"})
          tellm(player, {text: "an/animals [rad]", color: "gold"}, {text: " kills animals", color: "reset"})
          tellm(player, {text: "as/armor_stands [rad]", color: "gold"}, {text: " kills armor stands", color: "reset"})
          tellm(player, {text: "aec/area_effect_cloud [rad]", color: "gold"}, {text: " kills effect clouds", color: "reset"})
          tellm(player, {text: "b/boats [rad]", color: "gold"}, {text: " kills boats", color: "reset"})
          tellm(player, {text: "mi/minecart [rad]", color: "gold"}, {text: " kills all kinds of minecarts", color: "reset"})
          tellm(player, {text: "i/items [rad]", color: "gold"}, {text: " kills dropped items", color: "reset"})
          tellm(player, {text: "x/xp [rad]", color: "gold"}, {text: " kills XP orbs", color: "reset"})
          tellm(player, {text: "t/tnt [rad]", color: "gold"}, {text: " kills primed TNT (no carts!)", color: "reset"})
          tellm(player, {text: "v/villagers [rad]", color: "gold"}, {text: " kills villagers", color: "reset"})
          tellm(player, {text: "a/arrows [rad]", color: "gold"}, {text: " kills arrows", color: "reset"})
          tellm(player, {text: "p/projectiles [rad]", color: "gold"}, {text: " kills all projectiles", color: "reset"})
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
        version_switch do |v|
          v.default do
            which.each do |w|
              $mcl.server.invoke %{/execute #{player} ~ ~ ~ kill @e[type=#{w}#{",r=#{radius}" if radius}]}
            end
          end
          v.since "1.13", "17w45a" do
            which.each do |w|
              $mcl.server.invoke %{/execute as #{player} at @s run kill @e[type=#{w}#{",distance=..#{radius}" if radius}]}
            end
          end
        end
      end

      def butch_p player, radius
        $mcl.server.invoke %{/execute #{player} ~ ~ ~ kill }
        version_switch do |v|
          v.default do
            which.each do |w|
              $mcl.server.invoke %{/execute #{player} ~ ~ ~ kill @p[name=!#{player}#{",r=#{radius}" if radius}]}
            end
          end
          v.since "1.13", "17w45a" do
            which.each do |w|
              $mcl.server.invoke %{/execute as #{player} at @s run @p[name=!#{player}#{",distance=..#{radius}" if radius}]}
            end
          end
        end
      end
    end
    include Helper
  end
end
