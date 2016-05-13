module Mcl
  class HMclCBSBuilder
    class Blueprint
      MAX_SPEC = Gem::Version.new("1.0")
      attr_reader :data, :options, :tokens, :hooks, :grid, :src, :strict, :forced_grid_mode

      def initialize yamlstr, url = false, strict = false, force_gm = false
        @src = url
        @strict = strict
        @data = _parse_data(yamlstr, @strict)
        @forced_grid_mode = force_gm
        @options = _parse_options(@data["options"])
        @hooks = _parse_hooks(@data["hooks"])
        @tokens = _parse_tokens(@data["tokens"])
        @grid = _parse_grid(@data["grid"], grid_mode, @tokens)
        add_option("grid_mode", grid_mode, true)
        volume # precalc
      end

      %w[name version description author_name author_url].each do |field|
        define_method(field) { @data[field] }
      end

      def grid_mode
        forced_grid_mode || @data["grid_mode"]
      end

      def dimensions
        @_dimensions ||= begin
          layers = @grid.length
          unless grid_mode.end_with?("c")
            mrow = @grid.map{|r| r.length }.max
            mcol = @grid.map{|r| r.map{|c| c.length }.max  }.max
          end

          case grid_mode
            when "x" then [mrow, layers, mcol]
            when "y" then [layers, mrow, mcol]
            when "z" then [mcol, layers, mrow]
            when "xc" then [layers, 1, 1]
            when "yc" then [1, layers, 1]
            when "zc" then [1, 1, layers]
          end
        end
      end

      def volume
        @_volume ||= dimensions.inject(:*)
      end

      def add_option name, default, system = false
        raise "cannot add option `#{name}' because it is already defined as #{@options[name].inspect}" if @options[name]
        @options[name.to_s] = Option.new(name.to_s, "default" => default, "system" => system)
      end

      def _parse_data yamlstr, strict = false
        data = YAML.load(yamlstr)
        raise "malformed data" unless data

        # spec version
        if data["spec_version"]
          data["spec_version"] = data["spec_version"].to_s
          if Gem::Version.new(data["spec_version"]) > MAX_SPEC
            raise "blueprint data outdated (#{data["spec_version"]} < #{MAX_SPEC}), please upgrade the CBS builder addon!"
          end
        else
          raise "No key `spec_version' specified but it is required!"
        end

        # name
        raise "No key `name' specified but it is required!" if data["name"].blank?

        # grid_mode
        gmode = forced_grid_mode || data["grid_mode"]
        raise "No key `grid_mode' specified but it is required!" if gmode.blank?
        valid_modes = _grid_modes(data["spec_version"])
        raise "Invalid `grid_mode' specified `#{gmode}' not in `#{valid_modes.join(", ")}'!" if !valid_modes.include?(gmode)

        # grid
        raise "No key `grid' specified but it is required!" if data["grid"].blank?

        if strict
          # valid keys
          valid_keys = _valid_keys(data["spec_version"])
          invalid_keys = data.keys.select{|k| !valid_keys.include?(k) }
          raise "Invalid keys provided: [#{invalid_keys.join(", ")}]" if invalid_keys.any?

          # double keys
          double_keys = data.keys.select{|k| data.keys.count(k) > 1 }
          raise "Duplicate keys provided: [#{double_keys.join(", ")}]" if double_keys.any?
        end

        data
      rescue StandardError => ex
        raise "Failed to load blueprint, is the syntax correct? (#{ex.message})"
      end

      def _valid_keys spec_version
        case spec_version
          when "1.0" then %w[spec_version name author_name author_url description options
            hooks grid_mode grid tokens]
          else raise("SpecVersionError #{spec_version.inspect} keys not supported")
        end
      end

      def _grid_modes spec_version
        case spec_version
          when "1.0" then %w[x y z xc yc zc]
          else raise("SpecVersionError #{spec_version.inspect} grid modes not supported")
        end
      end

      def _parse_options option_data
        {}.tap do |options|
          option_data.each do |name, data|
            options[name] = Option.new(name, data)
          end if option_data
        end
      end

      def _compact_multirow input
        input.split("\n").reject{|l| l.strip.start_with?("#") }.join(" ").squeeze(" ")
      end

      def _parse_hooks hooks_data
        { "load" => [], "before" => [], "after" => [] }.tap do |hooks|
          hooks_data.each do |type, commands|
            if %w[load before after].include?(type)
              commands.each do |cmd|
                hooks[type] << Token.new("{#{_compact_multirow(cmd)}}") if cmd.present?
              end if commands.respond_to?(:each)
            else
              raise "unknown hook type `#{type}', allowed keys are load, before and after"
            end
          end if hooks_data
        end
      end

      def _parse_tokens token_data
        {}.tap do |tokens|
          token_data.each do |name, value|
            tokens[name] = Token.new(_compact_multirow(value)) if value.present?
          end if token_data
        end
      end

      def _parse_grid grid_data, grid_mode, tokens
        [].tap do |grid|
          grid_data.each do |page|
            if grid_mode.end_with?("c")
              _parse_row(_compact_multirow(page), tokens, true).each {|t| grid << t }
            else
              grid << [].tap {|layer|
                lines = page.split("\n").map(&:strip).reject(&:blank?)
                lines.each do |line|
                  next if line.start_with?("#")
                  if line == "-"
                    layer << Token.new(line)
                    next
                  end

                  layer << _parse_row(line, tokens)
                end
              }
            end
          end
        end
      end

      def _parse_row row_data, tokens, single_token = false
        lends = {"<" => ">", "[" => "]", "{" => "}"}
        literal_start = /\A([0-9]+)?((<|\[|\{)(?:.*))\z/
        literal_full = /\A([0-9]+)?((<|\[|\{)(?:.*)(?:>|\]|\}))\z/
        token_full = /\A([0-9]+)?([^0-9]{1}[^\s]*)\z/i

        [].tap do |row|
          if single_token
            if m = row_data.match(literal_full)
              count, token, literal = m[1], m[2], m[3]
              (count.presence ? count.to_i : 1).times {|i| row << Token.new(token, i: i) }
            elsif m = row_data.match(token_full)
              count, token = m[1], m[2]
              (count.presence ? count.to_i : 1).times {|i|
                tk = tokens[token]
                raise "undefined token `#{token}' in `#{row_data}'" unless tk
                row << (tk.variables? ? tk.fork(i: i) : tk)
              }
            else
              raise "Unknown parse error `#{row_data}'"
            end
          else
            rbuf = row_data.split(/\s+/)
            until rbuf.empty?
              item = rbuf.shift
              if m = item.match(literal_start)
                count, token, literal = m[1], m[2], m[3]
                had_space = token !~ /\A#{Regexp.escape(literal)}[#{Regexp.escape("+~!-^v><\\")}]+/i
                literalend = lends[literal]
                while token.end_with?("\\#{literalend}") || !(had_space && token.end_with?(literalend))
                  if rbuf.empty?
                    raise "unclosed literal #{literal} in `#{row_data}'"
                  end
                  token << " " << rbuf.shift
                  had_space = true
                end
                token.gsub!("\\#{literalend}", "#{literalend}")
                (count.presence ? count.to_i : 1).times {|i| row << Token.new(token, i: i) }
              elsif m = item.match(token_full)
                count, token = m[1], m[2]
                (count.presence ? count.to_i : 1).times {|i|
                  tk = tokens[token]
                  raise "undefined token `#{token}' in `#{row_data}'" unless tk
                  row << (tk.variables? ? tk.fork(i: i) : tk)
                }
              else
                raise "Unknown parse error `#{item}'"
              end
            end
          end
        end
      end

      def compile_hooks type, start_pos = false, end_pos = false
        @hooks[type.to_s].map do |hook|
          case type.to_s
          when "load"
            hook.compile([0, 0, 0], grid_mode, options)
          when "before", "after"
            if start_pos || end_pos
              nopts = options.dup
              if start_pos
                nopts["sx"] = Option.new("sx", "default" => start_pos[0])
                nopts["sy"] = Option.new("sy", "default" => start_pos[1])
                nopts["sz"] = Option.new("sz", "default" => start_pos[2])
              end
              if end_pos
                nopts["ex"] = Option.new("ex", "default" => start_pos[0])
                nopts["ey"] = Option.new("ey", "default" => start_pos[1])
                nopts["ez"] = Option.new("ez", "default" => start_pos[2])
              end
            else
              nopts = options
            end
            hook.compile([0, 0, 0], grid_mode, nopts)
          else
            raise "unknown hook type `#{type}', allowed keys are load, before and after"
          end
        end
      end

      def compile start_pos
        [].tap do |container|
          case mode = grid_mode
          when "x"
            x, y, z = start_pos
            grid.each_with_index do |layer, yd|
              layer.each_with_index do |line, xd|
                line.each_with_index do |token, zd|
                  container << token.compile([x + xd, y + yd, z + zd], mode, options)
                end
              end
            end
          when "y"
            x, y, z = start_pos
            grid.each_with_index do |layer, xd|
              layer.reverse.each_with_index do |line, yd|
                line.each_with_index do |token, zd|
                  container << token.compile([x + xd, y + yd, z + zd], mode, options)
                end
              end
            end
          when "z"
            x, y, z = start_pos
            grid.each_with_index do |layer, yd|
              layer.each_with_index do |line, zd|
                line.each_with_index do |token, xd|
                  container << token.compile([x + xd, y + yd, z + zd], mode, options)
                end
              end
            end
          when "xc", "yc", "zc"
            pos = { "x" => start_pos[0], "y" => start_pos[1], "z" => start_pos[2] }
            grid.each do |token|
              container << token.compile(pos.values, mode, options)
              pos[mode[0]] += 1
            end
          end
        end
      end
    end
  end
end
