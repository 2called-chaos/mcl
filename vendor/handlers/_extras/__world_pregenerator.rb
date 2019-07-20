module Mcl
  Mcl.reloadable(:HMclWorldPregenerator)
  ## Pregenerates world to given radius by teleporting a player around
  # !pregen start [autostop_at_radius] [-z]
  #   -z  start from 0/0 instead of your current position
  # !pregen doit [radius_offset]
  # !pregen delay [new_delay]
  # !pregen stop [at_radius]
  class HMclWorldPregenerator < Handler
    def setup
      register_pregen(:admin)
    end

    def register_pregen acl_level
      register_command [:pregen], desc: "pregenerates world data by teleporting player around", acl: acl_level do |player, args|
        pram = memory(player)
        case args[0]
        when "doit"
          if pram[:trx] && pram[:trx][:prepared]
            boffset = "#{args[1]}".to_i
            pram[:trx][:prepared] = false
            pram[:trx][:running] = true
            pram[:trx][:started_at] = Time.now
            pos = pram[:trx][:original_position]
            pos = [0, 150, 0] if pram[:trx][:start_from_zero]
            server.invoke %{/title #{player} times 10 120 60}
            server.invoke %{/title #{player} title [{"text":"Pregenerating...", "color": "green"}]}
            server.invoke %{/title #{player} subtitle [{"text":"a", "color": "green", "obfuscated": true},{"text":" initializing ", "color": "gray", "obfuscated": false},{"text":"a", "color": "green", "obfuscated": true}]}
            server.invoke %{/gamemode spectator #{player}}
            server.invoke %{/gamerule spectatorsGenerateChunks true}
            server.invoke %{/tp #{player} #{pos[0]} #{150} #{pos[2]}}

            if h = app.get_handlers(HMclPotionEffects).first
              h.player_effect player, player, :night_vision, seconds = 6000, amplifier = 255, particles = false
            end

            async do
              begin
                a = { b: boffset, x: boffset, z: boffset }
                seq = [
                  [:b, :+],
                  [:x, :+],
                  [:z, :+],
                  [:x, :-],
                  [:z, :-],
                  [:x, :+],
                ]
                app.graceful(&sdproc)

                x = catch(:stop_pregen) do
                  loop do
                    delay = pram[:trx][:delay]
                    maxb = pram[:trx][:max_radius]

                    sync do
                      if pram[:trx][:abort] || !prec(player).online?
                        if pram[:trx][:abort]
                          pram[:trx][:abort] = false
                          tellm(player, l("Generation aborted after #{Player.fseconds(Time.now - pram[:trx][:started_at])}!", :green))
                          server.invoke %{/title #{player} reset}
                          server.invoke %{/title #{player} title [{"text":"Pregenerating...", "color": "green"}]}
                          server.invoke %{/title #{player} subtitle [{"text":"ABORTED", "color": "red"}]}
                        end
                        throw :stop_pregen, :done
                      end

                      case seq[0]
                      when [:b, :+]
                        a[:b] += 1
                        seq.unshift seq.pop
                        delay = 0

                        if pram[:trx][:max_radius] && pram[:trx][:max_radius] < a[:b]
                          pram[:trx][:abort] = false
                          tellm(player, l("Generation finished in #{Player.fseconds(Time.now - pram[:trx][:started_at])}!", :green))
                          server.invoke %{/title #{player} reset}
                          server.invoke %{/title #{player} title [{"text":"Pregenerating...", "color": "green"}]}
                          server.invoke %{/title #{player} subtitle [{"text":"FINISHED", "color": "green"}]}
                          throw :stop_pregen, :done
                        end

                        server.invoke %{/title #{player} reset}
                        server.invoke %{/title #{player} title [{"text":"Pregenerating...", "color": "green"}]}
                        server.invoke %{/title #{player} subtitle [{"text":"radius #{a[:b]}#{"/#{maxb}" if maxb}", "color": "aqua"}]}
                      when [:x, :+]
                        if a[:x] < a[:b]
                          a[:x] += 1
                        else
                          seq.unshift seq.pop
                          delay = 0
                        end
                      when [:z, :+]
                        if a[:z] < a[:b]
                          a[:z] += 1
                        else
                          seq.unshift seq.pop
                          delay = 0
                        end
                      when [:x, :-]
                        if a[:x] > -a[:b]
                          a[:x] -= 1
                        else
                          seq.unshift seq.pop
                          delay = 0
                        end
                      when [:z, :-]
                        if a[:z] > -a[:b]
                          a[:z] -= 1
                        else
                          seq.unshift seq.pop
                          delay = 0
                        end
                      end

                      if delay > 0
                        tellm(player, l("r:#{a[:b]}#{"/#{maxb}" if maxb} x:#{a[:x]} z:#{a[:z]} s:#{seq[0]}", :aqua))

                        if pram[:trx][:devviz]
                          server.invoke %{/tp #{player} #{pos[0] + a[:x]} #{150} #{pos[2] + a[:z]}}
                          server.invoke %{/execute as #{player} at @s run setblock #{pos[0] + a[:x]} #{148} #{pos[2] + a[:z]} dirt}
                        else
                          server.invoke %{/tp #{player} #{pos[0] + a[:x] * 100} #{150} #{pos[2] + a[:z] * 100}}
                        end
                      end
                    end
                    sleep delay
                  end
                end

                app.graceful(sdproc) # delete

                if x == :done
                  server.invoke %{/tp #{player} #{pram[:trx][:original_position].join(" ")}}

                  if h = app.get_handlers(HMclPotionEffects).first
                    h.player_effect player, player, :clear
                  end
                end
              rescue Errno::EPIPE, IOError
                app.log.error "[WorldPregenerator] Server gone? Stopped."
              ensure
                sync do
                  pram[:trx][:running] = false
                end
              end
            end
          else
            tellm(player, l("Not prepared! (run '!pregen start' first)", :red))
          end
        when "start"
          if pram[:trx] && pram[:trx][:running]
            tellm(player, l("Already running!", :red))
            app.log.error pram.inspect
          else
            detect_player_position(player) do |pos|
              if pos
                pram[:trx] = { x: 0, y: 0 , r: 0 }
                pram[:trx][:prepared] = true
                pram[:trx][:original_position] = pos
                pram[:trx][:start_from_zero] = args.delete("-z")
                pram[:trx][:devviz] = args.delete("--dev")
                pram[:trx][:delay] = pram[:trx][:devviz] ? 1 : 10
                pram[:trx][:max_radius] = args[1].to_i if args[1].presence
                pos = [0, 150, 0] if pram[:trx][:start_from_zero]

                tellm(player, l("INSTRUCTIONS:", :gold))
                tellm(player, l("  - Set your view distance to ", :aqua), l("8-chunks", :light_purple), l("!", :aqua))
                tellm(player, l("  - Your gamemode will be changed to spectator!", :aqua))
                tellm(player, l("  - We start generating at ", :aqua), l(pos.join("x"), :light_purple), l("!", :aqua))
                if pram[:trx][:max_radius]
                  tellm(player, l("  - We stop at radius ", :aqua), l("#{pram[:trx][:max_radius]}", :light_purple), l("!", :aqua))
                else
                  tellm(player, l("  - We will ", :aqua), l("NOT", :red), l(" stop automatically!", :aqua))
                end
                tellm(player, l(" => ", :aqua), l("Start NOW!", :green, hover: "Stop with !pregen stop [atradius]", command: "!pregen doit"))
              else
                tellm(player, l("Couldn't determine your position :/ Is your head in water?", :red))
              end
            end
          end
        when "stop"
          if pram[:trx] && pram[:trx][:running]
            if args[1] && args[1].to_i != 0
              pram[:trx][:max_radius] = args[1].to_i
              tellm(player, l("Aborting after reaching radius #{pram[:trx][:max_radius]}...", :gold))
            else
              pram[:trx][:abort] = true
              tellm(player, l("Aborting...", :gold))
            end
          else
            tellm(player, l("Not running!", :red))
          end
        when "delay"
          if pram[:trx]
            if args[1] && args[1].to_f != 0
              pram[:trx][:delay] = args[1].to_f
              tellm(player, l("Teleport every #{pram[:trx][:delay]} seconds...", :gold))
            else
              tellm(player, l("Teleport delay is #{pram[:trx][:delay]} seconds...", :gold))
            end
          else
            tellm(player, l("Not prepared! (run '!pregen start' first)", :red))
          end
        else
          tellm(player, l("!pregen start|stop [autostop_at_radius] [-z]", color: "red"))
          tellm(player, l("  -z  start from 0/0 instead of your current position", color: "aqua"))
          tellm(player, l("  radius is given in teleports/grid not ingame blocks", color: "yellow"))
          tellm(player, l("!pregen delay [seconds]", color: "green"))
          tellm(player, l("  change delay between teleports (def: 10)", color: "yellow"))
        end
      end
    end

    module Helper
      def memory player
        pmemo(player, :world_pregenerator)
      end

      def tellm p, *msg
        trawm(p, title("PreGen"), *msg)
      end

      def ll input
        case input
          when Hash then input
          when Array then input.map{|i| l(i) }
          when String then l(input)
          else raise(ArgumentError, "unknown input type #{input.class}")
        end
      end

      def l str, color_or_opts = nil, opts = {}
        if color_or_opts.is_a?(Hash)
          opts = color_or_opts
        else
          opts[:color] = color_or_opts
        end
        {}.tap do |r|
          r[:text] = str
          r[:color] = opts[:color] if opts[:color]
          if hover = opts.delete(:hover)
            r[:hoverEvent] = { action: "show_text", value: ll(hover) }
          end
          if cmd = opts.delete(:command)
            r[:clickEvent] = { action: "run_command", value: cmd }
          end
          if url = opts.delete(:url)
            r[:clickEvent] = { action: "open_url", value: url }
          end
        end
      end
    end
    include Helper
  end
end
