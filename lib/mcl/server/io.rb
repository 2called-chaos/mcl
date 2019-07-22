module Mcl
  class Server
    module IO
      def properties reload = false
        @_properties ||= Properties.new(properties_path)
        @_properties.tap{|p| p.reload if reload }
      end

      def known_worlds
        Dir["#{root}/**/level.dat"].map{|f| File.dirname(f).gsub("#{root}/", "") }
      end

      def backup_world world = nil, &callback
        world ||= @world
        $mcl.async_call do
          begin
            rt = Benchmark.realtime do
              if @world == world
                $world_saved = false
                $mcl.sync { $mcl.server.invoke %{/save-off} }
                $mcl.sync { $mcl.server.invoke %{/save-all} }
                sleep 1 until $world_saved # wait for server to save data
              end
              world_chunks = world.split("/")
              world_cdir = world_chunks.pop
              world_infix = world_chunks.join("/")
              `cd "#{root}" && mkdir#{" -p" unless Mcl.windows?} "#{app.config["backup_infix"]}" && tar -cf "#{app.config["backup_infix"]}backup-#{fs_safe_name(world)}-#{Time.now.strftime("%Y-%m-%d_%H-%M")}.tar" #{%{-C "#{root}/#{world_infix}"}} "#{world_cdir}"`
            end
          ensure
            $mcl.sync { $mcl.server.invoke %{/save-on} } if @world == world
          end
          $mcl.sync { callback.try(:call, rt) }
        end
      end

      def decompress_backup destdir, tarfile, &callback
        id = uniqid
        rdest = "#{destdir}.restore-#{id}"
        $mcl.async_call do
          rt = Benchmark.realtime do
            `mkdir#{" -p" unless Mcl.windows?} "#{rdest}" && tar -xf "#{tarfile}" -C "#{rdest}" --strip-components=1`
          end
          $mcl.sync { callback.try(:call, rdest, rt) }
        end
      end

      def fs_safe_name str
        str.to_s.gsub("/", "~")
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
        end.sort_by{|i| i[2] }.reverse
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

      def world_copy old_world, new_world
        FileUtils.cp_r(world_root(old_world), world_root(new_world))
      end
    end
  end
end

