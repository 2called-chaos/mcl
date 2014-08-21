module Mcl
  class Handler
    attr_reader :app

    def setup
      # called on creation
    end

    def init
      # called when all handlers have went through their setup
    end

    def tick!
      # called on every tick (should be fast)
    end

    # -------


    def self.descendants
      @descendants ||= []
    end

    # Descendant tracking for inherited classes.
    def self.inherited(descendant)
      descendants << descendant
    end


    def initialize app
      @app = app
      setup
    end

    def server
      app.server
    end

    def eman
      app.eman
    end

    def register_command *cmds, &b
      opts = cmds.extract_options!
      handler = self
      cmds = [*cmds].flatten

      # register name
      app.command_names["!" << cmds.join(" !")] = opts[:desc]

      # register handler
      cmds.each do |cmd|
        cmd = cmd.to_s
        register_parser(/<([^>]+)> \!(.+)/i) do |res, r|
          if r[2] == "#{cmd}" || r[2].start_with?("#{cmd} ")
            catch(:handler_exit) do
              b[handler, r[1], r[2], "#{r[2]}".split(" ")[1].presence || r[1], r[2].split(" ")[1..-1], OptionParser.new]
            end
          end
        end
      end
    end

    def register_parser *a, &b
      eman.parser.register(*a, &b)
    end

    def register_pre_parser *a, &b
      eman.parser.register_pre(*a, &b)
    end

    def gm *a
      $mcl.server.gm(*a)
    end

    def traw *a
      $mcl.server.traw(*a)
    end

    def trawm *a
      $mcl.server.trawm(*a)
    end

    def strbool v
      v = true if ["true", "t", "1", "y", "yes"].include?(v)
      v = false if ["false", "f", "0", "n", "no"].include?(v)
      v
    end

    def prec p
      Player.where(nickname: p).first_or_initialize
    end

    def acl_verify p, level = 13337
      $mcl.acl_verify(p, level)
    end

    def async &block
      $mcl.async_call(&block)
    end

    def indicate_coord p, coord, type = nil
      coord = coord.join(" ") if coord.respond_to?(:each)
      parts = coord.split(" ").map(&:to_f)
      case type.to_s.strip
        when "p", "particle" then $mcl.server.invoke "/particle reddust #{coord} 0 0 0 1 100 force"
        when "b", "barrier" then $mcl.server.invoke "/particle barrier #{coord} 0 0 0 1 1 force"
        when "crystal" then $mcl.server.invoke "/summon EnderCrystal #{parts[0]} #{parts[1] - 0.5} #{parts[2]}"
        when "c", "cross"
          $mcl.server.invoke "/particle reddust #{coord} 1 0 0 1 100 force"
          $mcl.server.invoke "/particle reddust #{coord} 0 1 0 1 100 force"
          $mcl.server.invoke "/particle reddust #{coord} 0 0 1 1 100 force"
        else $mcl.server.invoke "/particle largeexplode #{coord} 0 0 0 1 10 force"
      end
    end

    def coord_32k_units p1, p2, &block
      [].tap do |r|
        pdim = coord_dimensions(p1, p2)
        if pdim.inject(:*) > 32768
          mtrx = selection_vertices(p1, p2)
          pa, pb = mtrx[:xyz], mtrx[:XYZ]
          xt, yt, zt = pdim[0] / 32, pdim[1] / 32, pdim[2] / 32
          xr, yr, zr = pdim[0] % 32, pdim[1] % 32, pdim[2] % 32

          zt.times do |zi|
            yt.times do |yi|
              xt.times do |xi|
                a = [pa[0] + xi * 32, pa[1] + yi * 32, pa[2] + zi * 32]
                r << [:x, a, shift_coords(a, [31, 31, 31])]
              end
              # xrest
              a = [pa[0] + xt * 32, pa[1] + yi * 32, pa[2] + zi * 32]
              r << [:xr, a, shift_coords(a, [xr - 1, 31, 31])]
            end
            # yrest
            xt.times do |xi|
              a = [pa[0] + xi * 32, pa[1] + yt * 32, pa[2] + zi * 32]
              r << [:yrx, a, shift_coords(a, [31, yr-1, 31])]
            end
            a = [pa[0] + xt * 32, pa[1] + yt * 32, pa[2] + zi * 32]
            r << [:yrxr, a, shift_coords(a, [xr-1, yr-1, 31])]
          end

          # zrest
          yt.times do |yi|
            xt.times do |xi|
              a = [pa[0] + xi * 32, pa[1] + yi * 32, pa[2] + zt * 32]
              r << [:zx, a, shift_coords(a, [31, 31, zr-1])]
            end
            # xrest
            a = [pa[0] + xt * 32, pa[1] + yi * 32, pa[2] + zt * 32]
            r << [:zxr, a, shift_coords(a, [xr-1, 31, zr-1])]
          end
          # yrest
          xt.times do |xi|
            a = [pa[0] + xi * 32, pa[1] + yt * 32, pa[2] + zt * 32]
            r << [:zyx, a, shift_coords(a, [31, yr-1, zr-1])]
          end
          a = [pa[0] + xt * 32, pa[1] + yt * 32, pa[2] + zt * 32]
          r << [:zyxr, a, shift_coords(a, [xr-1, yr-1, zr-1])]
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
