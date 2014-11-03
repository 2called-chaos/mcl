module Mcl
  class ConsoleClient
    module Discovery
      def discover_transport reconnect = false
        if File.exist?(discovery_file)
          rdf = File.read(discovery_file).strip.split("=")
          ["_t_connect_#{rdf.shift}", *rdf]
        else
          m = "Couldn't locate sockinfo file, instance `#{@instance}' offline? (#{discovery_file})"
          reconnect ? raise(m) : abort(m, 1)
        end
      end

      def discovery_file
        "#{ROOT}/tmp/#{@instance}.sockinfo"
      end
    end
  end
end
