module Mcl
  class Server
    module Getters
      %w[booting running stopping stopped].each do |s|
        define_method("#{s}?") { status == s.to_sym }
      end

      def port
        properties["server-port"] || 25565
      end

      def query_port
        properties["query.port"] || 25565
      end

      def rcon_port
        properties["rcon.port"] || 25575
      end

      def server_ip
        properties["server-ip"].presence || '127.0.0.1'
      end

      def root
        app.config["root"].gsub("\\", "/")
      end

      def logfile_path
        "#{root}/logs/latest.log"
      end

      def properties_path
        "#{root}/server.properties"
      end
    end
  end
end
