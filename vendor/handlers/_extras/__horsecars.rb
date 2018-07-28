module Mcl
  Mcl.reloadable(:ChaosHorseCars)
  class ChaosHorseCars < Handler
    def setup
      register_car
    end

    def register_car
      version_switch do |v|
        v.default { _register_car_pre_133 }
        v.since("1.13", "17w45a") { _register_car_113 }
      end
    end

    def _register_car_pre_133
      register_command :car, desc: "Horsecar commands", acl: :guest do |player, args|
        case args.shift
        when "spawn", "new"
          speed = (args.shift || 4).to_d / 10
          jump = (args.shift || 5).to_d / 10 + 1
          name = args.join(" ").presence || "car"

          # spawn car
          $mcl.server.invoke %{
            execute #{player} ~ ~ ~ summon Horse ~ ~1 ~ {
              Tags:["horsecar"],
              CustomName:"#{name}",
              NoAI:true,
              Tame:1,
              Invulnerable:1b,
              PersistenceRequired:1b,
              DeathLootTable:empty,
              ArmorItem:{
                id:"minecraft:diamond_horse_armor",
                Count:1b,
                Damage:0s
              },
              SaddleItem:{
                id:"minecraft:saddle",
                Count:1b,
                Damage:0s
              },
              Attributes:[
                {Base:#{speed}d,Name:"generic.movementSpeed"},
                {Base:#{jump}d,Name:"horse.jumpStrength"}
              ]
            }
          }.gsub("\n", "").squeeze(" ")
        when "kill"
          if args.first == "all"
            args.shift
            $mcl.server.invoke %{execute #{player} ~ ~ ~ replaceitem @e[tag=horsecar]}
            $mcl.server.invoke %{execute #{player} ~ ~ ~ replaceitem @e[tag=horsecar]}
            $mcl.server.invoke %{execute #{player} ~ ~ ~ kill @e[tag=horsecar]}
            trawt(player, "HorseCar", {text: "Removed all loaded cars!", color: "red"})
            return
          elsif args.first.present?
            r = args.shift.to_i
          else
            r = 2
          end
          $mcl.server.invoke %{execute #{player} ~ ~ ~ kill @e[tag=horsecar,r=#{r}]}
          trawt(player, "HorseCar", {text: "Removed cars in a #{r} block radius!", color: "red"})
        when "speed"
          if args[0].present?
            speed = args.shift.to_d / 10
            if args[0] == "all"
              $mcl.server.invoke %{execute #{player} ~ ~ ~ /entitydata @e[tag=horsecar] {Attributes:[{Base:#{speed}d,Name:"generic.movementSpeed"}]}}
              trawt(player, "HorseCar", {text: "Changed speed for all loaded cars to #{speed}!", color: "green"})
              return
            elsif args.first.present?
              r = args.shift.to_i
            else
              r = 2
            end
            $mcl.server.invoke %{execute #{player} ~ ~ ~ /entitydata @e[tag=horsecar,r=#{r}] {Attributes:[{Base:#{speed}d,Name:"generic.movementSpeed"}]}}
            trawt(player, "HorseCar", {text: "Changed speed for cars in a #{r} block radius to #{speed}!", color: "green"})
          else
            trawt(player, "HorseCar", {text: "!car speed <speed> [radius|all]", color: "gold"}, {text: "change car speed", color: "white"})
          end
        when "jump"
          if args[0].present?
            jump = args.shift.to_d / 10 + 1
            if args[0] == "all"
              $mcl.server.invoke %{execute #{player} ~ ~ ~ /entitydata @e[tag=horsecar] {Attributes:[{Base:#{jump}d,Name:"horse.jumpStrength"}]}}
              trawt(player, "HorseCar", {text: "Changed jump power for all loaded cars to #{jump}!", color: "green"})
              return
            elsif args.first.present?
              r = args.shift.to_i
            else
              r = 2
            end
            $mcl.server.invoke %{execute #{player} ~ ~ ~ /entitydata @e[tag=horsecar,r=#{r}] {Attributes:[{Base:#{jump}d,Name:"horse.jumpStrength"}]}}
            trawt(player, "HorseCar", {text: "Changed jump power for cars in a #{r} block radius to #{jump}!", color: "green"})
          else
            trawt(player, "HorseCar", {text: "!car jump <jump> [radius|all]", color: "gold"}, {text: "change car jump power", color: "white"})
          end
        when "name"
          if args[0].present?
            always = args.delete("-a")
            name = args.join(" ")
            $mcl.server.invoke %{execute #{player} ~ ~ ~ /entitydata @e[tag=horsecar,r=2] {CustomName:"#{name}",CustomNameVisible:#{!!always}}}
            trawt(player, "HorseCar", {text: "Changed name for cars in a 2 block radius to #{name}!", color: "green"})
          else
            trawt(player, "HorseCar", {text: "!car name <newname> [always]", color: "gold"}, {text: "change car name", color: "white"})
          end
        when "summon"
          $mcl.server.invoke %{execute #{player} ~ ~ ~ /tp @e[tag=horsecar,c=1] #{player}}
          trawt(player, "HorseCar", {text: "Teleported nearest car to you, if not summon a new one.", color: "green"})
        else
          trawt(player, "HorseCar", {text: "!car spawn [speed [jump [name]]]", color: "gold"}, {text: "spawn a new horse car", color: "white"})
          trawt(player, "HorseCar", {text: "!car kill [radius|all]", color: "gold"}, {text: "remove horse car", color: "white"})
          trawt(player, "HorseCar", {text: "!car speed <speed> [radius|all]", color: "gold"}, {text: "change car speed", color: "white"})
          trawt(player, "HorseCar", {text: "!car jump <jump> [radius|all]", color: "gold"}, {text: "change car jump power", color: "white"})
          trawt(player, "HorseCar", {text: "!car name <newname> -a", color: "gold"}, {text: "change car name (--alwaysVisible)", color: "white"})
          trawt(player, "HorseCar", {text: "!car summon", color: "gold"}, {text: "teleport (nearest) car to you", color: "white"})
        end
      end
    end

    def _register_car_113
      register_command :car, desc: "Horsecar commands", acl: :guest do |player, args|
        case args.shift
        when "spawn", "new"
          speed = (args.shift || 4).to_d / 10
          jump = (args.shift || 5).to_d / 10 + 1
          name = args.join(" ").presence || "car"

          # spawn car
          $mcl.server.invoke %{
            execute as #{player} at #{player} run summon horse ~ ~1 ~ {
              Tags:["horsecar"],
              CustomName:"\\"#{name}\\"",
              NoAI:true,
              Tame:1,
              Invulnerable:1b,
              PersistenceRequired:1b,
              DeathLootTable:empty,
              ArmorItem:{
                id:"minecraft:diamond_horse_armor",
                Count:1b,
                Damage:0s
              },
              SaddleItem:{
                id:"minecraft:saddle",
                Count:1b,
                Damage:0s
              },
              Attributes:[
                {Base:#{speed}d,Name:"generic.movementSpeed"},
                {Base:#{jump}d,Name:"horse.jumpStrength"}
              ]
            }
          }.gsub("\n", "").squeeze(" ").strip
        when "kill"
          if args.first == "all"
            args.shift
            $mcl.server.invoke %{execute as #{player} at #{player} run replaceitem @e[tag=horsecar]}
            $mcl.server.invoke %{execute as #{player} at #{player} run replaceitem @e[tag=horsecar]}
            $mcl.server.invoke %{execute as #{player} at #{player} run kill @e[tag=horsecar]}
            trawt(player, "HorseCar", {text: "Removed all loaded cars!", color: "red"})
            return
          elsif args.first.present?
            r = args.shift.to_i
          else
            r = 2
          end
          $mcl.server.invoke %{execute as #{player} at #{player} run kill @e[tag=horsecar,distance=0..#{r}]}
          trawt(player, "HorseCar", {text: "Removed cars in a #{r} block radius!", color: "red"})
        when "speed"
          if args[0].present?
            speed = args.shift.to_d / 10
            if args[0] == "all"
              $mcl.server.invoke %{execute as #{player} at #{player} run data merge entity @e[limit=1,tag=horsecar] {Attributes:[{Base:#{speed}d,Name:"generic.movementSpeed"}]}}
              trawt(player, "HorseCar", {text: "Changed speed for all loaded cars to #{speed}!", color: "green"})
              return
            elsif args.first.present?
              r = args.shift.to_i
            else
              r = 2
            end
            $mcl.server.invoke %{execute as #{player} at #{player} run data merge entity @e[limit=1,tag=horsecar,distance=0..#{r}] {Attributes:[{Base:#{speed}d,Name:"generic.movementSpeed"}]}}
            trawt(player, "HorseCar", {text: "Changed speed for cars in a #{r} block radius to #{speed}!", color: "green"})
          else
            trawt(player, "HorseCar", {text: "!car speed <speed> [radius|all]", color: "gold"}, {text: "change car speed", color: "white"})
          end
        when "jump"
          if args[0].present?
            jump = args.shift.to_d / 10 + 1
            if args[0] == "all"
              $mcl.server.invoke %{execute as #{player} at #{player} run data merge entity @e[limit=1,tag=horsecar] {Attributes:[{Base:#{jump}d,Name:"horse.jumpStrength"}]}}
              trawt(player, "HorseCar", {text: "Changed jump power for all loaded cars to #{jump}!", color: "green"})
              return
            elsif args.first.present?
              r = args.shift.to_i
            else
              r = 2
            end
            $mcl.server.invoke %{execute as #{player} at #{player} run data merge entity @e[limit=1,tag=horsecar,distance=0..#{r}] {Attributes:[{Base:#{jump}d,Name:"horse.jumpStrength"}]}}
            trawt(player, "HorseCar", {text: "Changed jump power for cars in a #{r} block radius to #{jump}!", color: "green"})
          else
            trawt(player, "HorseCar", {text: "!car jump <jump> [radius|all]", color: "gold"}, {text: "change car jump power", color: "white"})
          end
        when "name"
          if args[0].present?
            always = args.delete("-a")
            name = args.join(" ")
            $mcl.server.invoke %{execute as #{player} at #{player} run data merge entity @e[limit=1,tag=horsecar,distance=0..2] {CustomName:"#{name}",CustomNameVisible:#{!!always}}}
            trawt(player, "HorseCar", {text: "Changed name for cars in a 2 block radius to #{name}!", color: "green"})
          else
            trawt(player, "HorseCar", {text: "!car name <newname> [always]", color: "gold"}, {text: "change car name", color: "white"})
          end
        when "summon"
          $mcl.server.invoke %{execute as #{player} at #{player} run tp @e[tag=horsecar,limit=1] #{player}}
          trawt(player, "HorseCar", {text: "Teleported nearest car to you, if not summon a new one.", color: "green"})
        else
          trawt(player, "HorseCar", {text: "!car spawn [speed [jump [name]]]", color: "gold"}, {text: "spawn a new horse car", color: "white"})
          trawt(player, "HorseCar", {text: "!car kill [radius|all]", color: "gold"}, {text: "remove horse car", color: "white"})
          trawt(player, "HorseCar", {text: "!car speed <speed> [radius|all]", color: "gold"}, {text: "change car speed", color: "white"})
          trawt(player, "HorseCar", {text: "!car jump <jump> [radius|all]", color: "gold"}, {text: "change car jump power", color: "white"})
          trawt(player, "HorseCar", {text: "!car name <newname> -a", color: "gold"}, {text: "change car name (--alwaysVisible)", color: "white"})
          trawt(player, "HorseCar", {text: "!car summon", color: "gold"}, {text: "teleport (nearest) car to you", color: "white"})
        end
      end
    end
  end
end
