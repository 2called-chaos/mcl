module Mcl
  class Classifier
    R_TIME = '(?:(?:[0-1][0-9])|(?:[2][0-3])|(?:[0-9])):(?:[0-5][0-9])(?::[0-5][0-9])?'
    R_UUID = '[A-Z0-9]{8}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{12}'

    attr_reader :app

    def initialize app
      @app = app
      @parser = []
      @preparser = []
    end

    # ---------

    def r_splitline line
      line.match(/\[(#{R_TIME})\] \[([^\/]+)\/([^\]]+)\]: (.*)/)
    end

    def register pattern, &block
      @parser << [pattern, block]
    end

    def register_pre pattern, &block
      @preparser << [pattern, block]
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
