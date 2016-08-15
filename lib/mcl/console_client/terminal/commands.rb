module Mcl
  class ConsoleClient
    module Terminal
      module Commands
        def _tc_help args, str
          sync do
            _print_line c("The following terminal commands are available:", :magenta)
            _print_line c("  #{TCOM_PREF}help                        ", :cyan) << c("shows this help", :yellow)
            _print_line c("  #{TCOM_PREF}exit                        ", :cyan) << c("closes connection and console", :yellow)
            _print_line c("  #{TCOM_PREF}reconnect                   ", :cyan) << c("reconnect to the console server", :yellow)
            _print_line c("  #{TCOM_PREF}snoop [on/off]              ", :cyan) << c("shows or controls protocol snoop", :yellow)
            _print_line c("  #{TCOM_PREF}debug [on/off]              ", :cyan) << c("shows or controls debug output", :yellow)
            _print_line c("  #{TCOM_PREF}ps1 [help|ps1-expr]         ", :cyan) << c("shows or updates your ps1", :yellow)
            _print_line c("  #{TCOM_PREF}prompt [help|prompt-expr]   ", :cyan) << c("shows or updates your prompt", :yellow)
            _print_line c("  #{TCOM_PREF}screen_size                 ", :cyan) << c("shows your current screen size", :yellow)
            _print_line c("  #{TCOM_PREF}transport                   ", :cyan) << c("shows you transport details", :yellow)
            _print_line c("  #{TCOM_PREF}mode                        ", :cyan) << c("shows or changes terminal editing mode", :yellow)
            _print_line c("  #{TCOM_PREF}pry                         ", :cyan) << c("opens a pry session (locally, may fuck up readline/history)", :yellow)
          end
        end

        def _tc_pry args, str
          _hist_was = Readline::HISTORY.to_a
          Readline::HISTORY.pop until Readline::HISTORY.empty?

          # type "exit" or "help" or start prying!
          binding.pry
        ensure
          Readline::HISTORY.pop until Readline::HISTORY.empty?
          _hist_was.each{|s| Readline::HISTORY << s }
        end

        def _tc_exit args, str
          $cc_client_exiting = true
          Thread.main.exit
        end
        alias_method :_tc_quit, :_tc_exit

        def _tc_reconnect args, str
          transport_disconnect
        end
        alias_method :_tc_retry, :_tc_reconnect

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
              @opts[:ps1] = aval
              terminal_reset
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
              @opts[:prompt] = aval
              terminal_reset
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

        def _tc_transport args, str
          sync do
            _print_line c("          Transport: ", :yellow) << c("#{@socket.class} (#{@socket.peeraddr.try(:join, " – ")})", :cyan)
            _print_line c("          Connected: ", :yellow) << c("#{_t_socket_stats[:connected]}", :cyan)
            _print_line c("      Messages send: ", :yellow) << c("#{_t_socket_stats[:msend]}", :cyan)
            _print_line c("  Messages received: ", :yellow) << c("#{_t_socket_stats[:mreceived]}", :cyan)
          end
        end

        def _tc_mode args, str
          if args[0].try(:downcase) == "vi"
            Readline.vi_editing_mode
            print_line c("Terminal is now in VI editing mode!", :green)
          elsif args[0].try(:downcase) == "emacs"
            Readline.emacs_editing_mode
            print_line c("(i) ", :cyan) << c("Terminal is now in emacs editing mode!", :green)
          else
            vi_status = Readline.vi_editing_mode? rescue "unsupported"
            emacs_status = Readline.emacs_editing_mode? rescue "unsupported"
            vi = vi_status && vi_status != "unsupported"
            emacs = emacs_status && emacs_status != "unsupported"
            s, u = c("SUPPORTED", :green), c("UNSUPPORTED", :red)
            print_line c(" Current mode: #{c(vi ? "VI" : emacs ? "emacs" : "raw", :cyan)}")
            print_line c("   VI support: #{vi_status == "unsupported" ? u : s}")
            print_line c("emacs support: #{emacs_status == "unsupported" ? u : s}")
            print_line c("-----")
            print_line c("Switch between modes with ") << c("#{TCOM_PREF}mode [vi|emacs]")
          end
        end

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
