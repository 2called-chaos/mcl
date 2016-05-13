module Mcl
  Mcl.reloadable(:HMclCBSBuilder)
  ## CommandBlockScript builder
  # This allows you to write simple blueprints for command block related stuff (that's what it is intended for at least)
  # and let them build into your world. (e.g. write the stuff in your editor and magicly put it into the game)
  #
  # !cbs load <url> [-s] [-g mode]
  # !cbs info
  # !cbs opt [option] [value]
  # !cbs air <t/f>
  # !cbs pos <x> <y> <z>
  # !cbs pc <xyz-XYZ>
  # !cbs ipos [indicator] [o|c]
  # !cbs reset
  # !cbs status
  # !cbs cancel
  # !cbs build [clear]
  # !cbs one [<url> <x> <y> <z> [-acglops]]
  # !cbs sign <x> <y> <z> [-i]
  class HMclCBSBuilder < Handler
    def setup
      register_cbs(:builder)
    end

    def register_cbs acl_level
      register_command :cbs, desc: "CBS Builder (more info with !cbs)", acl: acl_level do |player, args|
        case args[0]
        when "load", "info", "opt", "air", "pos", "pc", "ipos", "reset", "status", "cancel", "build", "one", "sign"
          send("com_#{args[0]}", player, args[1..-1])
        else
          tellm(player, {text: "load <url> [-s] [-g mode]", color: "gold"}, {text: " load a remote CBS script", color: "reset"})
          tellm(player, {text: "one [<url> <x> <y> <z> [-acglops]]", color: "gold"}, {text: " all in one command", color: "reset"})
          tellm(player, {text: "sign <x> <y> <z> [-i]", color: "gold"}, {text: " set all-in-one sign (-i alters sign text)", color: "reset"})
          tellm(player, {text: "info", color: "gold"}, {text: " show details about current script", color: "reset"})
          tellm(player, {text: "opt <option> [value|-]", color: "gold"}, {text: " show/set/unset script options", color: "reset"})
          tellm(player, {text: "air <t/f>", color: "gold"}, {text: " copy air yes or no (default: true)", color: "reset"})
          tellm(player, {text: "pos <x> <y> <z>", color: "gold"}, {text: " set build start position", color: "reset"})
          tellm(player, {text: "pc <xyz-XYZ>", color: "gold"}, {text: " define position corner", color: "reset"})
          tellm(player, {text: "ipos [indicator] [o|c]", color: "gold"}, {text: " indicate build area", color: "reset"})
          tellm(player, {text: "reset", color: "gold"}, {text: " clear your current build settings", color: "reset"})
          tellm(player, {text: "status", color: "gold"}, {text: " show info about the current build settings", color: "reset"})
          tellm(player, {text: "cancel", color: "gold"}, {text: " cancel a build process", color: "reset"})
          tellm(player, {text: "build [clear]", color: "gold"}, {text: " parse blueprint and build it", color: "reset"})
        end
      end
    end


    module Commands
      def com_load player, args, &callback
        strict = args.delete("-s")
        bp, url = current_blueprint(player), args.shift
        force_gm = args.shift if args.delete("-g")


        if bp && bp.building
          tellm(player, {text: "Build in progress!", color: "red"})
        elsif !url
          tellm(player, {text: "!cbs load <url>", color: "red"})
        else
          begin
            t = async do
              sleep 2
              Thread.handle_interrupt(Exception => :never) {
                tellm(player, {text: "Loading, hang on tight...", color: "gray"})
              }
            end
            load_blueprint(url, strict, force_gm) do |blueprint, ex|
              t.kill
              begin
                raise ex if ex
                blueprint.add_option("player", player, true)
                memory(player)[:current_blueprint] = printer = spawn_printer(player, blueprint)
                tellm(player,
                  {text: "Loaded blueprint ", color: "green"},
                  {text: "#{blueprint.name.truncate(20)} #{blueprint.version}".strip, color: "aqua"},
                  {text: " (#{blueprint.dimensions.join("x")} = #{blueprint.volume})", color: "gray"},
                  {text: "!", color: "yellow"}
                )
                if callback
                  callback.call(printer, blueprint)
                else
                  tellm(player,
                    {text: "Run ", color: "yellow"},
                    {
                      text: "!cbs info", color: "gold",
                      hoverEvent: {action: "show_text", value: {text: "show details"}},
                      clickEvent: {action: "run_command", value: "!cbs info"}
                    },
                    {text: " to show more detailed information.", color: "yellow"}
                  )
                end
              rescue StandardError => ex
                tellm(player, {text: "Error loading schematic!", color: "red"})
                tellm(player, {text: "#{ex.class}: #{ex.message}", color: "red"})
                tellm(player, {text: "    #{ex.backtrace[0].to_s.gsub(ROOT, "%")}", color: "red"})
              end
            end
          rescue StandardError => ex
            tellm(player, {text: "Error loading schematic!", color: "red"})
            tellm(player, {text: "#{ex.class}: #{ex.message}", color: "red"})
            tellm(player, {text: "    #{ex.backtrace[0].to_s.gsub(ROOT, "%")}", color: "red"})
          end
        end
      end

      def com_info player, args
        unless require_blueprint(player)
          bp = current_blueprint(player)
          if bp._.author_name
            ao = bp._.author_url ? {
              hoverEvent: {action: "show_text", value: {text: "clickme"}},
              clickEvent: {action: "open_url", value: bp._.author_url},
              underlined: true
            } : {}
            tellm(player, {text: "Author: ", color: "gold"}, ao.merge(text: bp._.author_name, color: "yellow"))
          end

          tellm(player, {text: "Name: ", color: "gold"}, {text: bp._.name, color: "yellow"})
          tellm(player, {text: "Version: ", color: "gold"}, {text: bp._.version, color: "yellow"}) if bp._.version
          tellm(player, {text: "Desc: ", color: "gold"}, {text: bp._.description, color: "yellow"}) if bp._.description
          tellm(player, {text: "Dimensions: ", color: "gold"}, {text: bp._.dimensions.join("x"), color: "yellow"}, {text: " = #{bp._.volume} blocks", color: "gray"})

          gmargs = [{text: "Grid mode: ", color: "gold"}, {text: bp._.data["grid_mode"], color: "yellow"}]
          gmargs << {text: " (forced to #{bp._.forced_grid_mode})", color: "red"} if bp._.forced_grid_mode
          tellm(player, *gmargs)

          tell_options(player, bp._.options)
        end
      end

      def com_air player, args
        unless require_blueprint(player)
          pram = memory(player)
          pram[:current_blueprint].air = strbool(args[0]) if args[0]
          tellm(player, {text: "Air blocks will be ", color: "yellow"}, (pram[:current_blueprint].air ? {text: "COPIED", color: "green"} : {text: "IGNORED", color: "red"}))
        end
      end

      def com_reset player, args
        pram = memory(player)
        return if pram[:current_blueprint] && require_blueprint(player)
        memory(player).delete(:current_blueprint)
        tellm(player, {text: "Build settings cleared!", color: "green"})
      end

      def com_pos player, args, &callback
        unless require_blueprint(player)
          if args.count == 3 || (args.count == 1 && args.first == "~")
            detect_relative_coordinate(player, args) do |npos|
              current_blueprint(player).pos = npos
              line_pos(player)
              callback.try(:call)
            end
          elsif args.count > 0
            tellm(player, {text: "!cbs pos <x> <y> <z>", color: "red"})
            callback.try(:call)
          else
            pos = current_blueprint(player).pos
            line_pos(player)
            callback.try(:call)
          end
        end
      end

      def com_pc player, args
        unless require_blueprint(player)
          if args.count > 0 && args.first =~ /\A([xyz]{1,3})\z/i
            pram = memory(player)
            args.first.split("").each do |c|
              begin
                pram[:current_blueprint].pc[c.swapcase] = c
              rescue
              end
            end
            line_pos(player)
          else
            tellm(player, {text: "!cbs pc <xyz-XYZ>", color: "red"})
            tellm(player, {text: "e.g. !cbs pc xYz", color: "red"})
            line_pos(player)
          end
        end
      end

      def com_ipos player, args
        unless require_blueprint(player, false)
          bp = current_blueprint(player)

          if p1 = bp.start_pos
            p2 = bp.end_pos
            case args[1]
              when "o", "outline" then tellm(player, {text: "sorry, not yet implemented :(", color: "red"})
              when "c", "corners" then selection_vertices(p1, p2).values.uniq.each{|coord| indicate_coord(p, coord, args[0]) }
              else indicate_coord(player, p1, args[0]) ; indicate_coord(player, p2, args[0])
            end
          else
            tellm(player, {text: "Insertion point required!", color: "red"})
          end
        end
      end

      def com_cancel player, args
        unless require_blueprint(player, false)
          bp = current_blueprint(player)
          if bp.building?
            tellm(player, {text: "Canceling build...", color: "gold"})
            bp.cancel { tellm(player, {text: "Build canceled!", color: "green"}) }
          else
            tellm(player, {text: "No build active!", color: "yellow"})
          end
        end
      end

      def com_status player, args
        unless require_blueprint(player, false)
          bp = current_blueprint(player)
          tellm(player, {text: "Dimensions: ", color: "gold"}, {text: bp._.dimensions.join("x"), color: "yellow"}, {text: " = #{bp._.volume} blocks", color: "gray"})

          tellm(player, {text: "Air: ", color: "yellow"}, (bp.air? ? {text: "COPY", color: "green"} : {text: "IGNORE", color: "red"}))
          if bp.pos
            tellm(player,
              {text: "Ins.Point: ", color: "yellow"},
              {text: bp.pos.join(" "), color: "aqua"},
              {text: " (", color: "yellow"},
              {text: bp.start_pos.join(" "), color: "dark_aqua"},
              {text: " => ", color: "yellow"},
              {text: bp.end_pos.join(" "), color: "dark_aqua"},
              {text: ")", color: "yellow"}
            )
          else
            tellm(player, {text: "Ins.Point: ", color: "yellow"}, {text: "unset", color: "gray", italic: true})
          end
          size = bp._.volume
          proc = bp.stats[:blocks_processed]
          perc = ((proc / size.to_f) * 100).round(2)
          if bp.canceled?
            status = {text: "CANCELED: ", color: "red"}
          elsif bp.stopped?
            status = {text: "DONE: ", color: "green"}
          elsif bp.building?
            status = {text: "BUILDING: ", color: "green"}
          else
            status = {text: "IDLING: ", color: "gray"}
          end
          tellm(player,
            status,
            {text: proc, color: "yellow"},
            spacer,
            {text: size, color: "gold"},
            {text: " (#{perc}%)", color: "reset"}
          )
        end
      end

      def com_build player, args
        unless require_blueprint(player)
          bp = current_blueprint(player)

          if !bp.start_pos
            tellm(player, {text: "Insertion point required!", color: "red"})
          else
            if args[0] == "clear"
              # clear area
              coord_32k_units(bp.start_pos, bp.end_pos) do |p1, p2|
                $mcl.server.invoke %{/fill #{p1.join(" ")} #{p2.join(" ")} air}
              end
              tellm(player, {text: "Build area cleared!", color: "yellow"})
            else
              bp.print(self)
            end
          end
        end
      end

      def com_opt player, args
        unless require_blueprint(player)
          bp = current_blueprint(player)
          if o = args[0]
            if opt = bp._.options[o]
              if v = args[1..-1].join(" ")
                if v == "-"
                  opt.unset
                else
                  opt.value = v
                end
              end
              tell_options(player, { o => opt }, false)
            else
              tellm(player, {text: "There is no such option!", color: "red"})
            end
          else
            tell_options(player, bp._.options, "Available options:")
          end
        end
      end

      def com_one player, args
        if args.any?
          noair, clear, gm, pc, strict, build, bopts = false, false, false, false, false, true, {}
          opt = OptionParser.new
          opt.on("-a") { noair = true }
          opt.on("-c") { clear = true }
          opt.on("-l") { build = false }
          opt.on("-s") { strict = false }
          opt.on("-g gm", String) {|v| gm = v }
          opt.on("-p xyz", String) {|v| pc = v }
          opt.on("-o n=v", String) {|v|
            c = v.split("=")
            k = c.shift
            bopts[k] = c.join("=")
          }
          args = coord_save_optparse!(opt, Shellwords.shellsplit(args.join(" ")))
          url = args.shift
          x, y, z = args.shift, args.shift, args.shift

          if url
            if x && y && z
              largs = [url]
              largs << "-s" if strict
              largs << "-g #{gm}" if gm
              com_load(player, largs) do |p, b|
                com_pos(player, [x, y, z]) do
                  com_pc(player, [pc]) if pc
                  com_air(player, ["f"]) if noair
                  bopts.each {|n, v| com_opt(player, [n, v]) }
                  com_build(player, ["clear"]) if clear
                  com_build(player, []) if build
                end
              end
            else
              tellm(player, {text: "Position missing, abort!", color: "red"})
            end
          else
            tellm(player, {text: "URL missing, abort!", color: "red"})
          end
        else
          tellm(player, {text: "!cbs one [<url> <x> <y> <z> [-acglops]]", color: "gold"})
          tellm(player, {text: "  -a", color: "aqua"}, {text: " don't copy air (!cbs air false)", color: "reset"})
          tellm(player, {text: "  -c", color: "aqua"}, {text: " clear area before build (!cbs build clear)", color: "reset"})
          tellm(player, {text: "  -g gm", color: "aqua"}, {text: " force grid mode", color: "reset"})
          tellm(player, {text: "  -l", color: "aqua"}, {text: " load only (doesn't build, does (-c)lear)", color: "reset"})
          tellm(player, {text: "  -p xyz", color: "aqua"}, {text: " define xyz corner (!cbs pc)", color: "reset"})
          tellm(player, {text: "  -o \"name=value\"", color: "aqua"}, {text: " set options (!cbs opt)", color: "reset"})
          tellm(player, {text: "  -s", color: "aqua"}, {text: " load with strict mode", color: "reset"})
          if bp = current_blueprint(player)
            tellm(player, {text: "Command for your settings:", color: "yellow"})
            valid, command = one_command(bp)
            if valid && command.length <= 100
              tellm(player, {text: command, color: "green"})
            elsif valid
              tellm(player, {text: command, color: "gold", hoverEvent: {action: "show_text", value: "command is too long for chat/sign (shorten URL?))"}})
            else
              tellm(player, {text: command, color: "red", hoverEvent: {action: "show_text", value: "invalid: missing position"}})
            end
          else
            tellm(player, {text: "If you have a blueprint loaded and run `one' without", color: "yellow"})
            tellm(player, {text: "arguments it will show you the command for your settings.", color: "yellow"})
          end
        end
      end

      def com_sign player, args
        unless require_blueprint(player)
          bp = current_blueprint(player)
          valid, command = one_command(bp)
          infosign = args.delete("-i")

          if (args.count == 1 && args.first == "~") || args.count == 3
            if valid && command.length <= 100
              detect_relative_coordinate(player, args) do |npos|
                tellm(player, {text: "Attempted to update sign at ", color: "yellow"}, {text: "#{npos.join(" ")}", color: "aqua"})
                txt = {}
                if infosign
                  txt[bp._.src ? "Text2" : "Text3"] = {text: "#{bp._.name}", color: "blue"}.to_json.gsub('"', '\"')
                  txt["Text3"] = {text: bp._.src.to_s.gsub(/http(s)?:\/\//, ""), color: "dark_gray"}.to_json.gsub('"', '\"') if bp._.src
                end
                txt["Text4"] = {text: "» click 2 update «", color: "dark_red", clickEvent: {action: "run_command", value: "/say #{command}"}}.to_json.gsub('"', '\\"')
                $mcl.server.invoke %{
                  /blockdata #{npos.join(" ")} {#{txt.map{|k,v| %{#{k}:"#{v}"} }.join(",")}}
                }.gsub("\n", "").squeeze(" ")
              end
            elsif valid
              tellm(player, {text: "Abort, one-command is too long!", color: "red"})
              tellm(player, {text: "#{command.length} exceeds 100 limit by #{command.length - 100} characters", color: "gray"})
              tellm(player, {text: "Shorten URL or fork script to reduce options!", color: "red"})
            else
              tellm(player, {text: "Insertion point required!", color: "red"})
            end
          else
            tellm(player, {text: "!cbs sign <x> <y> <z> [-i]", color: "red"}, {text: " (-i write info to sign)", color: "reset"})
          end
        end
      end
    end
    include Commands

    module Helper
      def memory player
        pmemo(player, :cbs_builder)
      end

      def current_blueprint player
        memory(player)[:current_blueprint]
      end

      def spacer
        { text: " / ", color: "reset" }
      end

      def tellm player, *msg
        trawt(player, "CBS", *msg)
      end

      def one_command bp
        valid = true
        cmd = [].tap do |c|
          c << "!cbs one"
          c << "#{bp._.src}"
          if bp.pos
            c << "#{bp.pos.join(" ")}"
          else
            valid = false
          end
          c << "-a" unless bp.air?
          c << "-s" if bp._.strict
          c << "-g #{bp._.forced_grid_mode}" if bp._.forced_grid_mode
          c << "-p #{bp.pc}" unless bp.pc == "xyz"

          # options
          bp._.options.each do |name, opt|
            next if opt.system? || !opt.value?
            c << (opt.value.to_s =~ /\A[a-z0-9_\-]+\z/i ? %{-o #{opt.name}\\=#{opt.value}} : %{-o #{Shellwords.shellescape("#{opt.name}=#{opt.value}")}})
          end
        end.join(" ")
        [valid, cmd]
      end

      def tell_options player, optu, banner = "Options:"
        optc = optu.reject{|_, o| o.system? }
        if optc.any?
          tellm(player, {text: banner, color: "gold"}) if banner.is_a?(String)
          tellm(player, banner) if banner.is_a?(Hash)
          tellm(player, *banner) if banner.is_a?(Array)

          optc.each do |name, opt|
            mo = [
              {text: "  (#{opt.allowed}) ", color: "gray"},
              {
                text: "#{name} ", color: "aqua",
                clickEvent: { action: "suggest_command", value: "!cbs opt #{name}" },
                hoverEvent: { action: "show_text", value: "change option #{name}" },
              },
            ]
            mo << {text: "#{opt.help} ", color: "yellow"} if opt.help
            if opt.value?
              mo << {text: "#{opt.value}", color: "dark_green"}
              mo << {text: " (default: ", color: "gray"}
              if opt.default
                mo << {
                  text: "#{opt.default}", color: "gray",
                  clickEvent: { action: "suggest_command", value: "!cbs opt #{name} -" },
                  hoverEvent: { action: "show_text", value: "revert #{name} to default" },
                }
              else
                mo << {text: "NULL", color: "dark_gray", italic: true}
              end
              mo << {text: ")", color: "gray"}
            else
              if opt.default
                mo << {text: "#{opt.default}", color: "gray"}
              else
                mo << {text: "NULL", color: "dark_gray", italic: true}
              end
            end
            tellm(player, *mo)
          end
        end
      end

      def line_pos player
        bp = current_blueprint(player)
        tellm(player,
          {text: "Insertion point ", color: "yellow"},
          (bp.pos ? {text: bp.pos.join(" "), color: "green"} : {text: "unset", color: "gray", italic: true}),
          {text: " (", color: "yellow"},
          {text: bp.pc, color: "aqua"},
          {text: ")", color: "yellow"}
        )
        tellm(player,
          {text: "Build area ", color: "yellow"},
          {text: "#{bp.start_pos.join(" ")}", color: "aqua"},
          {text: " => ", color: "yellow"},
          {text: "#{bp.end_pos.join(" ")}", color: "aqua"}
        )
      end

      def require_blueprint player, req_nobuild = true
        bp = current_blueprint(player)
        if bp
          if req_nobuild && bp.building
            tellm(player,
              {text: "Build in progress (stop with ", color: "red"},
              {
                text: "!cbs cancel",
                color: "aqua",
                underlined: true,
                clickEvent: {action: "suggest_command", value: "!cbs cancel"}
              },
              {text: ")", color: "red"}
            )
            return true
          else
            return false
          end
        else
          tellm(player, {text: "No blueprint loaded yet!", color: "red"})
          return true
        end
      end

      def load_blueprint url, strict = false, force_gm = false, &callback
        raise ArgumentError, "callback block required" unless callback
        async do
          catch :stop_execution do
            # fetch
            begin
              if url.start_with?("ex:")
                content = File.read("#{File.dirname(__FILE__)}/_examples/#{url[3..-1].gsub(/[^a-z0-9_\-]/i, "")}.yml")
              else
                content = HTTParty.get(url)
              end
            rescue StandardError => ex
              sync { callback.call(false, ex) }
              throw :stop_execution
            end

            # load
            begin
              blueprint = Blueprint.new(content, url, strict, force_gm)
            rescue StandardError => ex
              sync { callback.call(content, ex) }
              throw :stop_execution
            end

            sync { callback.call(blueprint) }
          end
        end
      end

      def spawn_printer player, blueprint
        Printer.new(blueprint).tap do |p|
          p.on_compile_start do
            $mcl.sync { tellm(player, {text: "Assembling blueprint...", color: "yellow"}) }
          end
          p.on_compile_end do |rt|
            $mcl.sync do
              tellm(player,
                {text: "Blueprint data assembled in ", color: "yellow"},
                {text: "#{rt.round(1)}s", color: "aqua"},
                {text: "!", color: "yellow"}
              )
            end
          end
          p.on_compile_error do |rt, ex|
            $mcl.sync do
              tellm(player,
                {text: "Blueprint assembly failed after ", color: "red"},
                {text: "#{rt.round(2)}s", color: "aqua"},
                {text: "!", color: "red"}
              )
              tellm(player, {text: "#{ex.class}: #{ex.message}", color: "red"})
              tellm(player, {text: "    #{ex.backtrace[0].to_s.gsub(ROOT, "%")}", color: "red"})
            end
          end

          p.on_build_start do
            $mcl.sync do
              tellm(player,
                {text: "Build started (stop with ", color: "yellow"},
                {
                  text: "!cbs cancel",
                  color: "aqua",
                  underlined: true,
                  clickEvent: {action: "suggest_command", value: "!cbs cancel"}
                },
                {text: " or show ", color: "yellow"},
                {
                  text: "!cbs status",
                  color: "aqua",
                  underlined: true,
                  clickEvent: {action: "suggest_command", value: "!cbs status"}
                },
                {text: ")", color: "yellow"}
              )
            end
          end
          p.on_build_end do |rt|
            $mcl.sync do
              tellm(player,
                {text: "#{p.stats[:blocks_placed]} ", color: "aqua"},
                {text: "placed, ", color: "yellow"},
                {text: "#{p.stats[:blocks_ignored]} ", color: "aqua"},
                {text: "ignored.", color: "yellow"}
              )
              tellm(player,
                {text: "Build finished after ", color: "green"},
                {text: "#{rt.round(2)}s ", color: "aqua"},
                {text: "(", color: "green"},
                {text: "#{(p.stats[:blocks_placed] / rt).round(0)} ", color: "aqua"},
                {text: "blocks/s)!", color: "green"}
              )
            end
          end
          p.on_build_error do |rt, ql, ex|
            $mcl.sync do
              tellm(player,
                {text: "#{p.stats[:blocks_placed]} ", color: "aqua"},
                {text: "placed, ", color: "yellow"},
                {text: "#{p.stats[:blocks_ignored]} ", color: "aqua"},
                {text: "ignored, ", color: "yellow"},
                {text: "#{ql} ", color: "aqua"},
                {text: "cancelled.", color: "yellow"}
              )
              tellm(player,
                {text: "Build failed after ", color: "red"},
                {text: "#{rt.round(2)}s", color: "aqua"},
                {text: " (", color: "red"},
                {text: "#{(p.stats[:blocks_placed] / rt).round(0)}", color: "aqua"},
                {text: " blocks/s)!", color: "red"}
              )
              tellm(player, {text: "#{ex.class}: #{ex.message}", color: "red"})
              tellm(player, {text: "    #{ex.backtrace[0].to_s.gsub(ROOT, "%")}", color: "red"})
            end
          end
        end
      end
    end
    include Helper
  end
end
