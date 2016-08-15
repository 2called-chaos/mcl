module Mcl
  class ConsoleClient
    module ClientOptions
      def load_client_options
        if File.exist?(co_file)
          co_decode File.read(co_file)
        else
          {}
        end
      rescue
        return {}
      end

      def save_client_options cfg
        File.open(co_file(true), "wb") do |f|
          f.write(co_encode cfg)
        end
      rescue
        return false
      end

      private

      def co_file ensure_dir = false
        home = File.realpath(File.expand_path("~"))
        "#{home}/.mcl/client_config".tap do |path|
          FileUtils.mkdir_p(File.dirname(path)) if ensure_dir
        end
      end

      def co_encode data
        JSON.generate(data)
      end

      def co_decode data
        JSON.parse(data)
      end
    end
  end
end
