module Mcl
  class Server
    module IO
      def properties reload = false
        @_properties = nil if reload
        @_properties ||= begin
          if File.exist?(properties_path)
            {}.tap do |result|
              File.open(properties_path).each_line do |line|
                if line.strip.start_with?("#")
                  result[line.strip] = :comment
                else
                  chunks = line.split("=")
                  key    = chunks.shift
                  v      = chunks.join("=").strip.presence

                  # convert to proper types
                  v = v.to_i if v =~ /\A[0-9]+\Z/ # integer
                  v = true if v == "true"
                  v = false if v == "false"

                  result[key] = v
                end
              end
            end
          end
        end
      end

      def known_worlds
        Dir["#{root}/**/level.dat"].map{|f| File.dirname(f).gsub("#{root}/", "") }
      end

      def backup_world world = nil, &callback
        world ||= @world
        $mcl.async_call do
          if @world == world
            $mcl.sync { $mcl.server.invoke %{/save-all} }
            sleep 3 # wait for server to save data
          end
          `cd "#{root}" && mkdir -p #{app.config["backup_infix"]} && tar -cf #{app.config["backup_infix"]}backup-#{fs_safe_name(world)}-$(date +"%Y-%m-%d_%H-%M").tar #{world}`
          $mcl.sync { callback.try(:call) }
        end
      end

      def fs_safe_name str
        str.to_s.gsub("/", "~")
      end

      def update_property key, value
        cprops = properties(true)
        cprops[key.to_s] = value

        out = cprops.each_with_object([]) do |(k, v), o|
          if v == :comment
            o << k
          elsif k.present?
            o << "#{k}=#{v}"
          end
        end
        File.unlink("#{properties_path}.backup") if File.exist?("#{properties_path}.backup")
        FileUtils.cp(properties_path, "#{properties_path}.backup")
        File.open(properties_path, "w") {|f| f.puts *out }

        # reload properties
        properties(true)
      end

      def dirsize dir = nil
        total_size = 0
        Find.find(dir || self.root) do |path|
          next if FileTest.directory?(path)
          total_size += FileTest.size(path)
        end
        total_size
      end

      def world_size world = nil
        dirsize(world_root(world))
      end

      def world_root world = nil
        "#{root}/#{world || @world}"
      end

      def backups world = "*", with_size = false
        Dir["#{root}/#{app.config["backup_infix"]}backup-#{fs_safe_name(world)}-????-??-??_??-??.tar"].map do |dir|
          fn = File.basename(dir)
          c = fn[0..-5].split("-")[-4..-1].join("-").split("_")
          date = Time.parse("#{c[0]} #{c[1].gsub("-", ":")}:00")
          [dir, fn, date, with_size && File.size(dir)]
        end.sort_by{|i| i[3] }.reverse
      end

      def world_hash world = nil
        Digest::SHA2.hexdigest(world || @world)
      end

      def world_destroy world, destroy_backups = false
        $mcl.log.info "Deleting world `#{world}'"
        FileUtils.rm_rf(world_root(world))
        world_destroy_backups(world) if destroy_backups
      end

      def world_destroy_backups world = nil
        backups(world || @world).each do |b|
          $mcl.log.info "Deleting world backup `#{world}'"
          File.unlink(b[0])
        end
      end
    end
  end
end

