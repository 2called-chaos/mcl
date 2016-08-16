module Mcl
  class ConsoleServer
    module Colorize
      COLORMAP = {
        black: 30,
        red: 31,
        green: 32,
        yellow: 33,
        blue: 34,
        magenta: 35,
        cyan: 36,
        white: 37,
      }

      def colorize str, color = :yellow
        return str unless colorize?
        ccode = COLORMAP[color.to_sym] || raise(ArgumentError, "Unknown color #{color}!")
        "\e[#{ccode}m#{str}\e[0m"
      end
      alias_method :c, :colorize

      def colorize?
        @opts ? @opts[:colorize] : @colorize
      end
    end
  end
end
