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

      def relative_facing original, relative
        case original
        when :east
          case relative
            when :back  then :west
            when :right then :south
            when :left  then :north
            when :up    then :up
            when :down  then :down
          end
        when :south
          case relative
            when :back  then :north
            when :right then :west
            when :left  then :east
            when :up    then :up
            when :down  then :down
          end
        when :up
          case relative
            when :back  then :down
            when :right then :west
            when :left  then :east
            when :up    then :south
            when :down  then :north
          end
        when :down
          case relative
            when :back  then :up
            when :right then :west
            when :left  then :east
            when :up    then :south
            when :down  then :north
          end
        end
      end

      def compile coord, direction, opts = {}
        res = payload.dup
        token_opts.each {|_, opt| opt.apply!(res) }
        opts.each {|_, opt| opt.apply!(res) }
        coord_opts(coord).each {|_, opt| opt.apply!(res) }

        [:command_block, :setblock, :command].detect do |m|
          return __send__(:"_#{m}", coord, direction, res) if __send__(:"#{m}?")
        end || res
      end

      def _command_block coord, direction, payload
        cbopts = { block: "command_block", direction: direction, conditional: false, always_active: false }
        modifiers.each do |mod|
          case mod
            when "+" then cbopts[:block] = "chain_command_block"
            when "~" then cbopts[:block] = "repeating_command_block"
            when "!" then cbopts[:conditional] = true
            when "-" then cbopts[:always_active] = true
            when "\\" then cbopts[:direction] = relative_facing(direction, :back)
            when ">" then cbopts[:direction] = relative_facing(direction, :right)
            when "<" then cbopts[:direction] = relative_facing(direction, :left)
            when "^" then cbopts[:direction] = relative_facing(direction, :up)
            when "v" then cbopts[:direction] = relative_facing(direction, :down)
            else raise("unknown modifier #{mod} in `#{@data}'")
          end
        end if modifiers

        # compile data value
        bin = cbopts[:conditional] ? "1" : "0"
        case direction
          when :down then  bin << 0.to_s(2).rjust(3, "0")
          when :up then    bin << 1.to_s(2).rjust(3, "0")
          when :north then bin << 2.to_s(2).rjust(3, "0")
          when :south then bin << 3.to_s(2).rjust(3, "0")
          when :west then  bin << 4.to_s(2).rjust(3, "0")
          when :east then  bin << 5.to_s(2).rjust(3, "0")
        end

        # data tags
        data_tag = []
        chunks = payload.split("///")
        ctags = chunks.pop if chunks.length > 1
        ctags = false if !ctags || ctags == "-"

        # command
        data_tag << %{Command:"#{chunks.join("///").gsub('"', '\\"')}"}
        data_tag << %{auto:1} if cbopts[:always_active]
        datatag = data_tag.join(",")
        datatag << "#{"," if datatag.length > 0}#{ctags}" if ctags

        %{ /setblock #{coord.join(" ")} minecraft:#{cbopts[:block]} #{bin.to_i(2)} replace {#{datatag}} }.strip
      end

      def _setblock coord, direction, payload
        %{ /setblock #{coord.join(" ")} #{payload} }.strip
      end

      def _command coord, direction, payload
        %{ #{payload.strip[0] == "/" ? payload : "/#{payload}"} }.strip
      end
    end
  end
end
