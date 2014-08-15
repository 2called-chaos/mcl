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
        Dir["#{root}/**/level.dat"].map{|f| File.basename(File.dirname(f)) }
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
    end
  end
end

