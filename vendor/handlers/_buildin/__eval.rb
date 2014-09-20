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
#
# In order to activate this plugin you need to rename
# the file so that it does NOT start with two or more
# underscores. You also have to enable the plugin below
# but if you want to use this command you will figure
# it out, I'm sure ;-)
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
        if args.any?
          begin
            raise "eval is not enabled"
            pasteid = args[0].to_s.strip
            async do
              # fetch
              begin
                content = Net::HTTP.get(URI("http://pastebin.com/raw.php?i=#{pasteid}"))
              rescue Exception
                traw(player, "[eval] #{$!.message}", color: "red")
              end

              # eval
              $mcl.sync do
                begin
                  eval content
                rescue Exception
                  traw(player, "[eval] #{$!.message}", color: "red")
                end
              end
            end
          rescue Exception
            traw(player, "[eval] #{$!.message}", color: "red")
          end
        else
          traw(player, "[eval] !eval <pastebin_id>", color: "red")
        end
      end
    end
  end
end
