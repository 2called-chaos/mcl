module Mcl
  class Classifier
    R_TIME = '(?:(?:[0-1][0-9])|(?:[2][0-3])|(?:[0-9])):(?:[0-5][0-9])(?::[0-5][0-9])?'
    R_UUID = '[A-Z0-9]{8}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{12}'
    R_IPV4 = '(?:(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))(?![\\d])'
    R_FLOAT = '(?:([+-]?\\d*\\.\\d+)(?![-+0-9\\.]))'

    attr_reader :app

    def initialize app
      @app = app
      @parser = []
      @preparser = []
      case app.config["mc_log_format"]
        when "short" then @pattern = /\[(#{R_TIME}) ()([^\]]+)\]: (.*)/
        else @pattern = /\[(#{R_TIME})\] \[([^\/]+)\/([^\]]+)\]: (.*)/
      end
    end

    # ---------

    def r_splitline line
      line.match(@pattern)
    end

    def register pattern, &block
      @parser << [pattern, block]
    end

    def register_pre pattern, &block
      @preparser << [pattern, block]
    end

    def register_command handler, *cmds, &b
      opts = cmds.extract_options!
      cmds = [*cmds].flatten
      acl_lvl = app.pman.lvlval(opts[:acl] || :admin)

      # register name
      app.command_names["!" << cmds.join(" !")] = opts[:desc]
      app.command_acls["!" << cmds.join(" !")] = acl_lvl

      # register handler
      cmds.each do |cmd|
        cmd = cmd.to_s

        # disabled commands
        if (app.config["disable_commands"] || []).include?(cmd)
          app.log.warn "[SETUP] Prevented command `#{cmd}' from registering (disabled by config)"
          next
        end

        app.command_bindings[cmd] = [handler, b, ->(user, ucmd, acl = nil, wildcard = false){
          cres = catch(:handler_exit) do
            handler.acl_verify(user, acl, wildcard) if acl
            b[user, ucmd, handler, OptionParser.new]
          end
          cres == :acl && wildcard ? false : cres
        }]
        app.devlog "[SETUP]   Registering command `#{cmd}'", scope: "command_register"
        [
          /\A<([^>]+)> \!(.+)\z/i,
          /\A\[([^\]]+)\] \!(.+)\z/i,
          /(.+) issued server command: \/\!(.+)/i,
        ].each do |pat|
          register(pat) do |res, r|
            if r[2] == "#{cmd}" || r[2].start_with?("#{cmd} ") || opts[:wildcard]
              user = r[1].to_s.gsub(/[§]./, "")
              ucmd = r[2].split(" ")[1..-1]
              app.command_bindings[cmd][2][user, opts[:wildcard] ? r : ucmd, opts[:acl], opts[:wildcard]]
            end
          end
        end
      end
    end

    def pattern &block
      block
    end

    def parser_match resource
      @parser.detect do |pattern, callback|
        if pattern.respond_to?(:call)
          m = pattern[resource]
        else
          m = resource.data.match(pattern)
        end
        m ? callback[resource, m] : false
      end
    end

    def preparser_match resource
      @preparser.detect do |pattern, callback|
        if pattern.respond_to?(:call)
          m = pattern[resource]
        else
          m = resource.data.match(pattern)
        end
        m ? callback[resource, m] : false
      end
    end

    def classify line
      Result.new(line).tap do |res|
        begin
          r = preparser_match(res)

          unless r
            if m = r_splitline(line)
              res.date = Time.parse("#{Time.current.to_date.to_s} #{m[1]}")
              res.thread = m[2].downcase
              res.channel = m[3].downcase
              res.data = m[4]
              res.classified = true

              r = parser_match(res)
              unless r # unknown
                res.classified = false
              end
            else
              # raise "no exception expected"
              # r = parser_match(res)
              # unless r # unknown
              #   res.data = line
              #   res.classified = true
              #   res.type = :exception
              #   res.append = true
              # end
            end
          end
        rescue
          app.log.debug $!.message
          $!.backtrace.each {|m| app.log.debug(m) }
          app.server.traw("@a", "[ERROR] #{$!.message}", color: "red")
          app.server.traw("@a", "        #{$!.backtrace[0].to_s.gsub(ROOT, "%")}", color: "red")
          res.date = Time.current
          res.data = $!.message
          res.type = :exception
          res.subtype = :mcl_exception
        end
      end
    end

    class Result
      [:classified, :append, :command].each {|m| define_method("#{m}?") { send(:"@#{m}") } }
      attr_accessor :line, :type, :subtype, :thread, :channel, :origin_type, :origin, :data, :command, :date, :append, :classified

      def initialize(line = nil)
        @line = line
        @classified = false
        @type = :unknown
      end

      def command
        !!@command
      end
    end
  end
end
