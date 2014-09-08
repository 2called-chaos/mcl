#########################################################
###  WARNING / WARNING / WARNING / WARNING / WARNING  ###
#########################################################
# This plugin is disabled by default because it can harm
# your server! If you enable this plugin, players with
# MCL root permissions may execute this command and by
# doing this, executing remote ruby code on this machine.
#
# A malicious use of this command may read, modify or
# destroy any file the user - which is running MCL - has
# access to. Use this plugin only when you need it!
#########################################################

module Mcl
  Mcl.reloadable(:HMclEval)
  ## Eval (executes remote code)
  # !eval <pastebin ID>
  class HMclEval < Handler
    def setup
      register_eval
    end

    def register_eval
      register_command :eval, desc: "evals MCL code from pastebin.com ID", acl: :root do |player, args|
        acl_verify(player)
        begin
          pasteid = args[0].to_s.strip
          content = Net::HTTP.get(URI("http://pastebin.com/raw.php?i=#{pasteid}"))
          eval content
        rescue Exception
          traw(player, "[eval] #{$!.message}", color: "red")
        end
      end
    end
  end
end
