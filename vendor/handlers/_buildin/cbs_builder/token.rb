module Mcl
  class HMclCBSBuilder
    class Token
      attr_accessor :default, :token_opts

      def initialize tdata, opts = {}
        @data = tdata.strip
        @token_opts = opts.each_with_object({}) {|(n, v), h| h[n.to_s] = Option.new(n.to_s, "default" => v) }
      end

      def fork opts = {}
        self.class.new(@data, opts)
      end

      def variables?
        @data =~ /%[^\s]+%/i
      end

      def command_block?
        @data.start_with?("<") && @data.end_with?(">")
      end

      def setblock?
        @data.start_with?("[") && @data.end_with?("]")
      end

      def command?
        @data.start_with?("{") && @data.end_with?("}")
      end

      def literal
        return [:"<", :">"] if command_block?
        return [:"[", :"]"] if setblock?
        return [:"{", :"}"] if command?
      end

      def literal?
        !!literal
      end

      def modifiers
        if @modifiers.nil?
          @modifiers = begin
            if command_block?
              str = @data.dup[1..-2].split("")
              mods = []
              while s = str.shift
                break unless ["+", "~", "!", "-", "\\", ">", "<", "^", "v"].include?(s)
                mods << s
              end
              mods.any? ? mods : false
            else
              false
            end
          end
        end
        @modifiers
      end

      def payload
        if literal?
          @data[(1+(modifiers ? modifiers.length : 0))..-2].strip
        else
          @data
        end
      end

      def coord_opts coord
        {
          "x" => Option.new("x", "default" => coord[0]),
          "y" => Option.new("y", "default" => coord[1]),
          "z" => Option.new("z", "default" => coord[2]),
        }
      end

      def compile coord, opts = {}
        res = payload.dup
        token_opts.each {|_, opt| opt.apply!(res) }
        opts.each {|_, opt| opt.apply!(res) }
        coord_opts(coord).each {|_, opt| opt.apply!(res) }

        if command_block?
          _command_block coord, res
        elsif setblock?
          _setblock coord, res
        elsif command?
          _command coord, res
        else
          res
        end
      end

      def _command_block coord, payload
        cbopts = { meta: 0 }
        data_tag = "{}"
        modifiers.each do |mod|
          case mod
            when "+" then #
            when "~" then #
            when "!" then #
            when "-" then #
            when "\\" then #
            when ">" then #
            when "<" then #
            when "^" then #
            when "v" then #
            else raise("unknown modifier #{mod} in `#{@data}'")
          end
        end if modifiers

        %{ /setblock #{coord.join(" ")} minecraft:command_block #{cbopts[:meta]} replace #{data_tag} }.strip
      end

      def _setblock coord, payload
        %{ /setblock #{coord.join(" ")} #{payload} }.strip
      end

      def _command coord, payload
        %{ #{payload.strip[0] == "/" ? payload : "/#{payload}"} }.strip
      end
    end
  end
end
