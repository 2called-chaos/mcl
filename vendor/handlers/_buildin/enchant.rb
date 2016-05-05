module Mcl
  Mcl.reloadable(:HMclEnchant)
  ## Wrapper for /enchant command
  # !enchant
  class HMclEnchant < Handler
    def setup
      register_enchant :mod
    end

    def register_enchant acl_level
      register_command(:enchant, desc: "Enchant held item in primary hand", acl: acl_level) do |player, args|
        case args[0]
        when "list"
          query = args[1..-1].join(" ")
          list = enchantments
          list = list.grep((/#{query}/i)) if query.present?
          list.each {|l| tellm(player, {text: l, color: "yellow"}) }
        when "examples"
          tellm(player, {text: "!enchant unb:3 feather:1 mending:1 fire:1", color: "gold"})
          tellm(player, {text: "!enchant SomeUser asp:1 men:1", color: "gold"})
        else
          if args.any?
            if args[0][":"]
              target = player
              enchants = args
            else
              target = args[0]
              enchants = args[1..-1]
            end

            enchants.each do |enchant|
              name, level = enchant.split(":")
              resolved_name = enchantments.include?(name.downcase) ? name : enchantments.grep(/#{name}/i).first
              $mcl.server.invoke %{/execute #{player} ~ ~ ~ enchant #{target} #{resolved_name} #{level.presence || 1}}
            end
          else
            tellm(player, {text: "examples", color: "gold"}, {text: " examples for partial enchantment names", color: "reset"})
            tellm(player, {text: "list [query]", color: "gold"}, {text: " list enchantments (test lookup with query argument)", color: "reset"})
            tellm(player, {text: "[target] <enchantment:level> …", color: "gold"}, {text: " enchant held item for you or target with given enchantments", color: "reset"})
          end
        end
      end
    end

    module Helper
      def tellm p, *msg
        trawt(p, "Enchant", *msg)
      end

      def enchantments
        %w[
          protection
          aqua_affinity
          bane_of_arthropodos
          blast_protection
          depth_strider
          efficiency
          feather_falling
          fire_protection
          fire_aspect
          flame
          fortune
          frost_walker
          infinity
          knockback
          looting
          luck_of_the_sea
          lure
          mending
          power
          projectile_protection
          punch
          respiration
          sharpness
          silk_touch
          smite
          thorns
          unbreaking
        ]
      end
    end
    include Helper
  end
end
