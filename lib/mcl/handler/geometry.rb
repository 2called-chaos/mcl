module Mcl
  class Handler
    module Geometry
      def coord_32k_units p1, p2, require_danger_mode_for_player = nil, &block
        [].tap do |r|
          pdim = coord_dimensions(p1, p2)
          if pdim.inject(:*) > 32768
            # require danger mode
            if p = require_danger_mode_for_player
              return [] if require_dm_for_selection(p, p1, p2)
            end

            # calc
            mtrx = selection_vertices(p1, p2)
            pa, pb = mtrx[:xyz], mtrx[:XYZ]
            xt, yt, zt = pdim[0] / 32, pdim[1] / 32, pdim[2] / 32
            xr, yr, zr = pdim[0] % 32, pdim[1] % 32, pdim[2] % 32

            zt.times do |zi|
              yt.times do |yi|
                xt.times do |xi|
                  a = [pa[0] + xi * 32, pa[1] + yi * 32, pa[2] + zi * 32]
                  r << [a, shift_coords(a, [31, 31, 31])]
                end
                # xrest
                a = [pa[0] + xt * 32, pa[1] + yi * 32, pa[2] + zi * 32]
                r << [a, shift_coords(a, [xr - 1, 31, 31])]
              end
              # yrest
              xt.times do |xi|
                a = [pa[0] + xi * 32, pa[1] + yt * 32, pa[2] + zi * 32]
                r << [a, shift_coords(a, [31, yr-1, 31])]
              end
              a = [pa[0] + xt * 32, pa[1] + yt * 32, pa[2] + zi * 32]
              r << [a, shift_coords(a, [xr-1, yr-1, 31])]
            end

            # zrest
            yt.times do |yi|
              xt.times do |xi|
                a = [pa[0] + xi * 32, pa[1] + yi * 32, pa[2] + zt * 32]
                r << [a, shift_coords(a, [31, 31, zr-1])]
              end
              # xrest
              a = [pa[0] + xt * 32, pa[1] + yi * 32, pa[2] + zt * 32]
              r << [a, shift_coords(a, [xr-1, 31, zr-1])]
            end
            # yrest
            xt.times do |xi|
              a = [pa[0] + xi * 32, pa[1] + yt * 32, pa[2] + zt * 32]
              r << [a, shift_coords(a, [31, yr-1, zr-1])]
            end
            a = [pa[0] + xt * 32, pa[1] + yt * 32, pa[2] + zt * 32]
            r << [a, shift_coords(a, [xr-1, yr-1, zr-1])]
          else
            r << [p1, p2]
          end
        end.each(&block)
      end

      def relative_coordinate coord, rel
        coord.map.with_index do |c, i|
          r = (rel[i] || "~").to_s
          if r.start_with? "~"
            r = r[1..-1]
            c.to_i + r.to_i
          else
            r.to_i
          end
        end
      end

      def detect_relative_coordinate player, rel, &block
        if rel.any?{|s| s.to_s.include?("~") }
          detect_player_position(player) do |pos|
            if pos
              block.call relative_coordinate(pos, rel)
            else
              tellm(player, {text: "Couldn't determine your position :/ Is your head in water?", color: "red"})
            end
          end
        else
          block.call rel.map(&:to_i)
        end
      end

      def selection_vertices p1, p2
        corners = %w[xyz Xyz xYz XYz xyZ XyZ xYZ XYZ]
        x = [p1[0], p2[0]].sort
        y = [p1[1], p2[1]].sort
        z = [p1[2], p2[2]].sort

        corners.each_with_object({}) do |corner, res|
          res[corner.to_sym] = corner.each_char.map do |c|
            case c
              when "x" then x[0]
              when "X" then x[1]
              when "y" then y[0]
              when "Y" then y[1]
              when "z" then z[0]
              when "Z" then z[1]
            end
          end
        end
      end

      def coord_dimensions p1, p2
        p1 && p2 && p1.zip(p2).map{|lh| (lh.max - lh.min).round(0) + 1 }
      end

      def shift_coords coord, shift_by
        [coord[0] + shift_by[0], coord[1] + shift_by[1], coord[2] + shift_by[2]]
      end

      def coord_shifting_direction strdir
        case strdir
          when "n", "north" then [:north, :z, :-]
          when "e", "east" then [:east, :x, :+]
          when "s", "south" then [:south, :z, :+]
          when "w", "west" then [:west, :x, :-]
          when "u", "up" then [:up, :y, :+]
          when "d", "down" then [:down, :y, :-]
          else raise "unknown direction (n/e/s/w/u/d)"
        end
      end

      def direction_indicator_points coord, directions, num = 10, spacing = 0
        [].tap do |points|
          x, y, z = coord
          directions = directions.map(&:second)
          unspaced = 0
          num.times do |i|
            x += 1 if directions.include?(:east)
            y += 1 if directions.include?(:up)
            z += 1 if directions.include?(:south)
            x -= 1 if directions.include?(:west)
            y -= 1 if directions.include?(:down)
            z -= 1 if directions.include?(:north)
            if spacing > 0 && unspaced >= spacing
              unspaced = 0
              next
            else
              unspaced += 1 unless i = 0
              points << [x, y, z]
            end
          end
        end
      end

      def direction_vector p1, p2
        [p1[0] - p2[0], p1[1] - p2[1], p1[2] - p2[2]]
      end

      def coord_vector_line p1, p2, t = 0
        dv = direction_vector(p1, p2)
        [
          p2[0].to_d + dv[0].to_d * t.to_d,
          p2[1].to_d + dv[1].to_d * t.to_d,
          p2[2].to_d + dv[2].to_d * t.to_d,
        ]
      end

      def coord_distance p1, p2
        dv = direction_vector(p1, p2)
        Math.sqrt (dv[0] ** 2) + (dv[1] ** 2) + (dv[2] ** 2)
      end

      def coord_direction_str p1, p2 = nil
        "".tap do |str|
          dir = (p2 ? coord_direction(p1, p2) : p1).map(&:second)
          up = dir.delete(:up)
          down = dir.delete(:down)
          str << dir.join("-")
          str << " (up)" if up
          str << " (down)" if down
        end.strip
      end

      # direction from p1 to reach p2
      def coord_direction p1, p2, filter = true
        xd = p2[0] - p1[0]
        yd = p2[1] - p1[1]
        zd = p2[2] - p1[2]
        north = zd < 0
        south = zd > 0
        east = xd > 0
        west = xd < 0
        up = yd > 0
        down = yd < 0
        dary = [xd.abs, yd.abs, zd.abs]
        xp = dary[0] == 0 ? 0 : dary[0].to_f / dary.max.to_f * 100
        yp = dary[1] == 0 ? 0 : dary[1].to_f / dary.max.to_f * 100
        zp = dary[2] == 0 ? 0 : dary[2].to_f / dary.max.to_f * 100

        # assign
        dir = []
        dir << [zp, :south] if south
        dir << [zp, :north] if north
        dir << [xp, :west] if west
        dir << [xp, :east] if east
        dir << [yp, :up] if up
        dir << [yp, :down] if down

        # filter
        dir = dir.select {|r, d| r > 15 } if filter && dir.length >= 2
        dir
      end
    end
  end
end
