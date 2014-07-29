module Mcl
  class Server
    module IO
      def properties reload = false
        @_properties = nil if reload
        @_properties ||= begin
          if File.exist?(properties_path)
            {}.tap do |result|
              File.open(properties_path).each_line do |line|
                next if line.strip.start_with?("#")
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
  end
end

