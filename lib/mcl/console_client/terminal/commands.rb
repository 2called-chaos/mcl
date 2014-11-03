module Mcl
  class ConsoleClient
    module Terminal
      module Commands
        def _tc_pry args, str
          _hist_was = Readline::HISTORY.to_a
          Readline::HISTORY.pop until Readline::HISTORY.empty?

          # type "exit" or "help" or start prying!
          binding.pry
        ensure
          Readline::HISTORY.pop until Readline::HISTORY.empty?
          _hist_was.each{|s| Readline::HISTORY << s }
        end

        def _tc_snoop args, str
          if args[0]
            @opts[:snoop] = strbool(args[0])
            print_line c("Protocol snooping is now ", :cyan) << (@opts[:snoop] ? c("enabled", :green) : c("disabled", :red))
          else
            print_line c("# ?snoop [on/off]", :magenta)
            print_line c("Protocol snooping is currently ", :cyan) << (@opts[:snoop] ? c("enabled", :green) : c("disabled", :red))
          end
        end

        def _tc_debug args, str
          if args[0]
            @opts[:debug] = strbool(args[0])
            print_line c("Debugging output is now ", :cyan) << (@opts[:debug] ? c("enabled", :green) : c("disabled", :red))
          else
            print_line c("# ?debug [on/off]", :magenta)
            print_line c("Debug output is currently ", :cyan) << (@opts[:debug] ? c("enabled", :green) : c("disabled", :red))
          end
        end

        def _tc_ps1 args, str
          if args[0]
            if args[0] == "help"
              sync do
                _print_line c("You can use the following variables", :yellow)
                _print_line c("  %{instance}   ", :cyan) << c("    name of the instance connected to", :yellow)
                _print_line c("  %{instance_nd}", :cyan) << c("    name of the instance connected to, blank for default instance", :yellow)
                _print_line ""
                color_help
              end
            else
              aval = "#{args.join(" ")}"
              aval = "" if aval == '""'
              @ps1 = ->(_){ aval }
              print_line c("Your PS1 was updated!", :green)
            end
          else
            ps1 = instance_eval(&@ps1)
            print_line c("# ?ps1 [ps1-expression]", :magenta)
            print_line c("Type `?ps1 help' for ps1-expression help.", :yellow)
            print_line c("Your current PS1 is ", :yellow) << (ps1.present? ? c(ps1, :green) : c("empty", :red))
          end
        end

        def _tc_prompt args, str
          if args[0]
            if args[0] == "help"
              sync { color_help }
            else
              aval = "#{args.join(" ")}"
              aval = "" if aval == '""'
              @prompt = ->(_){ aval }
              print_line c("Your prompt was updated!", :green)
            end
          else
            prompt = instance_eval(&@prompt)
            print_line c("# ?prompt [prompt-expression]", :magenta)
            print_line c("Type `?prompt help' for prompt-expression help.", :yellow)
            print_line c("Your current prompt is ", :yellow) << (prompt.present? ? c(prompt, :green) : c("empty", :red))
          end
        end

        def _tc_screen_size args, str
          print_line c("Your current screen size is ", :yellow) << c(Readline.get_screen_size.join("x"), :green) << c(" characters", :yellow)
        end

        # when "?mode"
        # when "?transport"
        # when "?keepalive"
        # when "?colors"

        protected

        def color_help
          _print_line c("You can use the following color variables (text will be colored until %{reset} or end of line):", :yellow)
          _print_line c("  %{black}      ", :cyan) << c("    this text is black", :black)
          _print_line c("  %{red}        ", :cyan) << c("    this text is red", :red)
          _print_line c("  %{green}      ", :cyan) << c("    this text is green", :green)
          _print_line c("  %{yellow}     ", :cyan) << c("    this text is yellow", :yellow)
          _print_line c("  %{blue}       ", :cyan) << c("    this text is blue", :blue)
          _print_line c("  %{magenta}    ", :cyan) << c("    this text is magenta", :magenta)
          _print_line c("  %{cyan}       ", :cyan) << c("    this text is cyan", :cyan)
          _print_line c("  %{white}      ", :cyan) << c("    this text is white", :white)
          _print_line c("  %{reset}      ", :cyan) << "    \e[0mthis text is reset"
        end
      end
    end
  end
end
