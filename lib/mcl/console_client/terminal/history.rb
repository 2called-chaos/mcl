module Mcl
  class ConsoleClient
    module Terminal
      module History
        def load_history
          if File.exist?(history_file)
            File.open(history_file).readlines.map(&:strip).each {|c| Readline::HISTORY << c }
            debug "loaded #{Readline::HISTORY.count} commands into history (from #{history_file})"
          else
            debug "no history file found"
          end
        end

        def save_history
          File.open(history_file, "w") do |f|
            f.write Readline::HISTORY.to_a.join("\n")
          end
          debug "saved #{Readline::HISTORY.length} commands from history to #{history_file}"
        end

        def history_file
          File.realpath(File.expand_path("~")) << "/.mcl-#{@instance}.hist"
        end

        def history_reject(buf)
          Readline::HISTORY.pop if /^\s*$/ =~ buf
          Readline::HISTORY.pop if Readline::HISTORY.length > 1 && Readline::HISTORY[Readline::HISTORY.length-2] == buf
        rescue IndexError
        end
      end
    end
  end
end
