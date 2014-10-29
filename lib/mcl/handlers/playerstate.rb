module Mcl
  Mcl.reloadable(:HMMclPlayerstate)
  class HMMclPlayerstate < Handler
    def setup
      # [03:53:00] [User Authenticator #1/INFO]: UUID of player 2called_chaos is 93cc6d87-776e-459f-b40a-530a5670c07c
      register_parser(/UUID of player ([^\s]+) is (#{Classifier::R_UUID})/i) do |res, r|
        $mcl.pman.update_uuid(r[1], r[2])
      end

      # connect
      # [19:15:29] [Server thread/INFO]: toastyyyx[/84.62.171.204:49797] logged in with entity id 4390588 at (-120.69999998807907, 46.0, 239.23091316042147)
      register_parser(/([^\s]+)\[\/(#{Classifier::R_IPV4}):(\d+)\] logged in with entity id (\d+) at \((?:\[[^\]]+\]\s)?#{Classifier::R_FLOAT}, #{Classifier::R_FLOAT}, #{Classifier::R_FLOAT}\)/i) do |res, r|
        $mcl.pman.login_user r[1], ip: r[2], x: r[5].to_f, y: r[6].to_f, z: r[7].to_f
      end

      # disconnect
      # [19:18:46] [Server thread/INFO]: toastyyyx lost connection: TextComponent{text='Disconnected', siblings=[], style=Style{hasParent=false, color=null, bold=null, italic=null, underlined=null, obfuscated=null, clickEvent=null, hoverEvent=null, insertion=null}}
      register_parser(/^([^\{\}\s]+) lost connection: (.*)/i) do |res, r|
        $mcl.pman.logout_user r[1], reason: r[2].match(/text='(.*)'/i).try(:second) || r[2]
      end
    end
  end
end
