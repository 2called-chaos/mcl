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
    end
  end
end
