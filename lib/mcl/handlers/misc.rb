module Mcl
  Mcl.reloadable(:HMMclMisc)
  class HMMclMisc < Handler
    def setup
      # player position detection
      register_parser(/\A\[([^:]+): Successfully found the block at ([\d\.,\-]+),(?:\s)?([\d\.,\-]+),(?:\s)?([\d\.,\-]+?)(?:\.)?\]\z/i) do |res, r|
        pmemo(r[1])[:detected_pos] = [r[2].to_i, r[3].to_i-1, r[4].to_i]
      end

      # player position detection (1.13)
      register_parser(/\ATeleported ([^\s]+) to ([\d\.,\-]+),(?:\s)?([\d\.,\-]+),(?:\s)?([\d\.,\-]+?)(?:\.)?\z/i) do |res, r|
        x, y, z = r[2].to_f, r[3].to_f, r[4].to_f
        x -= 1 if x < 0
        y -= 1 if y < 0
        z -= 1 if z < 0
        pmemo(r[1])[:detected_pos] = [x.to_i, y.to_i, z.to_i]
      end

      # player position (and more) detection (1.13) based on "/data" information
      register_parser(/\A([^\s]+) has the following entity data: (.+)\z/i) do |res, r|
        begin
          nbt = pmemo(r[1])[:latest_nbt] = Mnhnp.parse!(r[2])

          # update position
          x, y, z = *nbt["Pos"]
          x -= 1 if x < 0
          y -= 1 if y < 0
          z -= 1 if z < 0
          pmemo(r[1])[:detected_pos] = [x.to_i, y.to_i, z.to_i]

          # update rotation
          pmemo(r[1])[:detected_rot] = nbt["Rotation"]
        rescue StandardError => ex
          # fallback to teleport method if NBT parsing fails
          app.log.warn "Player detection via /data failed, falling back to teleporting ONCE"
          app.log.debug "\t#{ex.class}: #{ex.message}"
          ex.backtrace.each {|l| app.log.debug "\t\t#{l}" }
          server.invoke %{/execute as #{r[1]} at #{r[1]} run tp #{r[1]} ~ ~ ~}
        end
      end
    end
  end
end
