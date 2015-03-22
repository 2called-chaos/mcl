module Mcl
  class ConsoleClient
    module Terminal
      module Environment
        def env_file instance, ensure_dir = false
          home = File.realpath(File.expand_path("~"))
          "#{home}/.mcl/env/#{instance}.dat".tap do |path|
            FileUtils.mkdir_p(File.dirname(path)) if ensure_dir
          end
        end

        def save_env instance, data
          File.open(env_file(instance, true), "wb") do |f|
            f.write(data)
          end
        end

        def load_env instance
          if File.exist?(env_file(instance))
            File.read(env_file(instance))
          else
            {}
          end
        rescue
          return false
        end

        def encode_env data
          JSON.generate(data)
        end

        def decode_env data
          JSON.parse(data)
        end
      end
    end
  end
end
