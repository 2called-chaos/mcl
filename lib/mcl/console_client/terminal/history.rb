module Mcl
  class ConsoleClient
    module Terminal
      module History
        HIST_KEEP = 10_000

        def load_history
          if File.exist?(history_file)
            File.open(history_file).readlines.map(&:strip).each {|c| Readline::HISTORY << c }
            debug "loaded #{Readline::HISTORY.count} commands into history (from #{history_file})"
          else
            debug "no history file found"
          end
        end

        def save_history
          if Readline::HISTORY.length == 0
            debug "skipped saving empty history to #{history_file}"
          else
            File.open(history_file(true), "w") do |f|
              f.write Readline::HISTORY.to_a.last(HIST_KEEP).join("\n")
            end
            diff = Readline::HISTORY.length - HIST_KEEP
            debug "saved #{[Readline::HISTORY.length, HIST_KEEP].min} commands from history to #{history_file}" << (diff > 0 ? " (truncated first #{diff})" : "")
          end
        end

        def history_file ensure_dir = false
          home = File.realpath(File.expand_path("~"))
          "#{home}/.mcl/hist/#{@instance}.hist".tap do |path|
            FileUtils.mkdir_p(File.dirname(path)) if ensure_dir
          end
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
