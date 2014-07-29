module Mcl
  class Classifier
    attr_reader :app
    include Parsing

    def initialize app
      @app = app
      @parser = []
      @preparser = []
      internal_parser
    end

    def internal_parser
      a_uauth
      a_clientstate
      a_boot
      a_chat
    end

    def a_uauth
      pat = pattern do |res|
        res.thread.start_with?("user authenticator")
      end
      register(pat) do |res|
        m = data.match(/UUID of player ([^\s]+) is (#{R_UUID})/)
        res.thread = "user authenticator"
        res.type = :uauth
        res.origin_type = :player
        res.origin = m[1]
        res.data = m[2]
      end
    end

    def a_clientstate
      # connect
      # [19:15:29] [Server thread/INFO]: toastyyyx[/84.62.171.204:49797] logged in with entity id 4390588 at (-120.69999998807907, 46.0, 239.23091316042147)
      pat = pattern do |res|
        res.thread == "server thread" &&
        res.channel == "info" &&
        !res.data.start_with?("<") &&
        res.data.include?("logged in with entity id")
      end
      register(pat) do |res|
        m = data.match(/UUID of player ([^\s]+) is (#{R_UUID})/)
        res.type = :clientstate
        res.origin_type = :connect
        res.origin = m[1]
        res.data = m[2]
      end

      # join
      # [19:15:29] [Server thread/INFO]: toastyyyx joined the game
      pat = pattern do |res|
        res.thread == "server thread" &&
        res.channel == "info" &&
        !res.data.start_with?("<") &&
        res.data.end_with?("joined the game")
      end
      register(pat) do |res|
        m = data.match(/UUID of player ([^\s]+) is (#{R_UUID})/)
        res.type = :clientstate
        res.origin_type = :join
        res.origin = m[1]
        res.data = m[2]
      end

      # disconnect
      # [19:18:46] [Server thread/INFO]: toastyyyx lost connection: TextComponent{text='Disconnected', siblings=[], style=Style{hasParent=false, color=null, bold=null, italic=null, underlined=null, obfuscated=null, clickEvent=null, hoverEvent=null, insertion=null}}
      pat = pattern do |res|
        res.thread == "server thread" &&
        res.channel == "info" &&
        !res.data.start_with?("<") &&
        res.data.end_with?("joined the game")
      end
      register(pat) do |res|
        m = data.match(/UUID of player ([^\s]+) is (#{R_UUID})/)
        res.type = :clientstate
        res.origin_type = :disconnect
        res.origin = m[1]
        res.data = m[2]
      end

      # leave
      # [19:18:46] [Server thread/INFO]: toastyyyx left the game
      pat = pattern do |res|
        res.thread == "server thread" &&
        res.channel == "info" &&
        !res.data.start_with?("<") &&
        res.data.end_with?("left the game")
      end
      register(pat) do |res|
        m = data.match(/UUID of player ([^\s]+) is (#{R_UUID})/)
        res.type = :clientstate
        res.origin_type = :leave
        res.origin = m[1]
        res.data = m[2]
      end
    end

    def a_boot

    end

    def a_chat

    end
  end
end
