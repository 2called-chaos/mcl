module Mcl
  Mcl.reloadable(:HMclNBTInspector)
  ## Inspector for server side NBT files
  # !stronghold [-w --world WORLD]
  class HMclNBTInspector < Handler
    NBT_STRONGHOLDS = "data/Stronghold.dat"

    def setup
      register_stronghold(:admin)
    end

    def register_stronghold acl_level
      register_command [:stronghold, :strongholds], desc: "examines strongholds.dat and shows you coordinates of portal rooms", acl: acl_level do |player, args|
        world = $mcl.server.world

        opt = OptionParser.new
        opt.on("-w", "--world WORLD", String) {|v| world = v }
        opt.parse!(args)

        # check file
        if !File.exist?(nbt_path(NBT_STRONGHOLDS, world))
          tellm(player, {text: "couldn't find ", color: "red"}, {text: NBT_STRONGHOLDS, color: "aqua"}, {text: " for world ", color: "red"}, {text: world, color: "aqua"}, {text: "!", color: "red"})
          throw :handler_exit
        end

        nbt = nbt_load(NBT_STRONGHOLDS, world)
        data = nbt[1]["data"]["Features"]

        data.each_with_index do |(chunk_coord, sh), i|
          prc = sh["Children"].detect{|c| c["id"] == "SHPR" }
          x1, y1, z1, x2, y2, z2 = prc["BB"]
          xd, yd, zd = x2 - x1, y2 - y1, z2 - z1

          yc = y1 + yd -3
          case prc["O"]
            when 0 then xc, zc, yr, xr = x1 + xd / 2, z1 - 1 + zd / 2, 0, 0 # north
            when 1 then xc, zc, yr, xr = x1 + 2 + xd / 2, z1 + zd / 2, 90, 0 # east
            when 2 then xc, zc, yr, xr = x1 + xd / 2, z1 + 2 + zd / 2, 180, 0 # south
            when 3 then xc, zc, yr, xr = x1 - 1 + xd / 2, z1 + zd / 2, -90, 0 # west
          end

          tellm(player,
            {text: "found stronghold ", color: "yellow"},
            {text: "##{i+1} #{prc["O"]}", color: "light_purple"},
            {text: " #{chunk_coord}", color: "gray"},
            {text: " => ", color: "yellow"},
            {text: "#{xc} #{yc} #{zc}", color: "aqua", hoverEvent: {action: "show_text", value: {text: "click to teleport to portal room"}}, clickEvent: {action: "run_command", value: "!tp #{xc} #{yc} #{zc} #{yr} #{xr}"}}
          )
        end
      end
    end



    module Helper
      def tellm p, *msg
        trawm(p, title("NBT"), *msg)
      end

      def nbt_path file, world = nil
        "#{$mcl.server.world_root(world)}/#{file}"
      end

      def nbt_load file, world = nil
        NBTFile.load(File.read(nbt_path(file, world)))
      end
    end
    include Helper
  end
end
