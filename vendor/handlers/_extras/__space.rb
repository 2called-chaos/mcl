module Mcl
  Mcl.reloadable(:DiskSpace)
  class DiskSpace < Handler
    def setup
      register_ds
    end

    def register_ds
      register_command :ds, desc: "Disk space usage", acl: :guest do |player, args|
        tellm(player, "calculating...")

        async_safe do
          world_path = server.world_root(server.world)
          du = `du -bs #{Shellwords.shellescape(world_path)}`.chomp.split(" ").first.to_i
          df = `df --output=avail #{Shellwords.shellescape(world_path)}`.chomp.split("\n").last.to_i * 1024

          tellm(player, l(server.world, :aqua))
          tellm(player, l(" size: ", :gold), l(server.human_bytes(du), :yellow))

          freecolor = :green
          freecolor = :yellow if df < 200 * 1024 * 1024 * 1024
          freecolor = :red if df < 100 * 1024 * 1024 * 1024
          tellm(player, l(" free: ", :gold), l(server.human_bytes(df), freecolor))
        end
      end
    end

    def tellm p, *msg
      trawt(p, "DiskSpace", *msg)
    end

    def ll input
      case input
        when Hash then input
        when Array then input.map{|i| l(i) }
        when String then l(input)
        else raise(ArgumentError, "unknown input type #{input.class}")
      end
    end

    def l str, color_or_opts = nil, opts = {}
      if color_or_opts.is_a?(Hash)
        opts = color_or_opts
      else
        opts[:color] = color_or_opts
      end
      {}.tap do |r|
        r[:text] = str
        r[:color] = opts[:color] if opts[:color]
        r[:obfuscated] = !!opts[:obfuscated]
        if hover = opts.delete(:hover)
          r[:hoverEvent] = { action: "show_text", value: ll(hover) }
        end
        if cmd = opts.delete(:command)
          r[:clickEvent] = { action: "run_command", value: cmd }
        end
        if cmd = opts.delete(:scommand)
          r[:clickEvent] = { action: "suggest_command", value: cmd }
        end
        if url = opts.delete(:url)
          r[:clickEvent] = { action: "open_url", value: url }
        end
      end
    end
  end
end
