module Mcl
  Mcl.reloadable(:HMclWhois)
  ## Whois (get player information)
  # !whois <player>
  class HMclWhois < Handler
    def setup
      register_whois(:mod)
    end

    def register_whois acl_level
      register_command :whois, desc: "shows you exclusive NSA data about a player", acl: acl_level do |player, args|
        target = args.first || player
        $mcl.server.invoke book(player, "Report for #{target}", nsa_report(target), author: "NSA")
      end
    end

    module Helper
      def nsa_report target
        tmem = prec(target)
        [nsarp_playtime(tmem), nsarp_ip(tmem), nsarp_misc(tmem)]
      end

      def nsarp_playtime tmem
        [].tap do |r|
          r << %Q{{text: "#{tmem.nickname}", color: "red", underlined: true}}

          # online
          r << %Q{{text: "\\nOnline: ", color: "dark_blue"}}
          if tmem.online?
            r << %Q{{text: "Yes", color: "dark_green"}}
          else
            r << %Q{{text: "No", color: "dark_red"}}
          end

          # permission
          perm = pman.lvlname(tmem.permission)
          r << %Q{{text: "\\nPermission: ", color: "dark_blue"}}
          r << %Q{{text: "#{perm}", color: "dark_aqua"}}

          # connects
          r << %Q{{text: "\\nConnects: ", color: "dark_blue"}}
          r << %Q{{text: "#{tmem[:data][:connects]}", color: "dark_aqua"}}

          # playtime
          r << %Q{{text: "\\nPlaytime: ", color: "dark_blue"}}
          r << %Q{{text: "#{tmem.fplaytime}", color: "dark_aqua"}}

          # first connect
          if tmem.first_connect
            r << %Q{{text: "\\nFirst connect:\\n", color: "dark_blue"}}
            r << %Q{{text: "#{tmem.first_connect.strftime("%F %T")} (#{Player.fseconds(Time.current - tmem.first_connect)})", color: "dark_aqua"}}
          end

          # last connect
          if tmem.last_connect
            r << %Q{{text: "\\nLast connect:\\n", color: "dark_blue"}}
            r << %Q{{text: "#{tmem.last_connect.strftime("%F %T")} (#{Player.fseconds(Time.current - tmem.last_connect)})", color: "dark_aqua"}}
          end
        end.join("\n")
      end

      def nsarp_ip tmem
        ipd = ip_data(tmem) || {}
        [].tap do |r|
          if ipd["ip"]
            r << %Q{{text: "IP: ", color: "dark_blue"}}
            r << %Q{{text: "#{ipd["ip"]}", color: "dark_aqua"}}
          end

          if ipd["hostname"]
            r << %Q{{text: "\\nHostname:\\n", color: "dark_blue"}}
            r << %Q{{text: "#{ipd["hostname"]}", color: "dark_aqua"}}
          end

          if ipd["country"]
            r << %Q{{text: "\\nCountry: ", color: "dark_blue"}}
            r << %Q{{text: "#{ipd["country"]}", color: "dark_aqua"}}
          end

          if ipd["city"]
            r << %Q{{text: "\\nCity: ", color: "dark_blue"}}
            r << %Q{{text: "#{ipd["city"]}", color: "dark_aqua"}}
          end

          if ipd["org"]
            r << %Q{{text: "\\nProvider: ", color: "dark_blue"}}
            r << %Q{{text: "#{ipd["org"]}", color: "dark_aqua"}}
          end

          r << %Q{{text: "\\n» ip info", color: "dark_purple", underlined: true, hoverEvent:{action:"show_text",value:"Click to open"},clickEvent:{action:"open_url", value:"http://ipinfo.io/#{ipd["ip"]}"}}}
        end.join("\n")
      end

      def nsarp_misc tmem
        [].tap do |r|
          # uuid
          r << %Q{{text: "UUID:\\n", color: "dark_blue"}}
          r << %Q{{text: "#{tmem.uuid || "???"}\\n\\n", color: "dark_aqua"}}
          r << %Q{{text: "\\n» kill player\\n", color: "dark_purple", underlined: true, hoverEvent:{action:"show_text",value:"Click to kill player"},clickEvent:{action:"run_command", value:"!raw /kill #{tmem.nickname}"}}}
          r << %Q{{text: "\\n» kick player\\n", color: "dark_purple", underlined: true, hoverEvent:{action:"show_text",value:"Click to kick player"},clickEvent:{action:"run_command", value:"!raw /kick #{tmem.nickname}"}}}
          r << %Q{{text: "\\n» ban player\\n", color: "dark_red", underlined: true, hoverEvent:{action:"show_text",value:"Click to ban player"},clickEvent:{action:"run_command", value:"!raw /ban #{tmem.nickname}"}}}
        end.join("\n")
      end

      def ip_data tmem
        return nil unless tmem.ip
        # response = Net::HTTP.get_response("ipinfo.io","/#{tmem.ip}/json")
        response = Net::HTTP.get_response("ipinfo.io","/78.94.159.28/json")
        JSON.parse(response.body)
      end
    end
    include Helper
  end
end
