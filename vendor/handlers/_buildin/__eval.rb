module Mcl
  Mcl.reloadable(:HMclEval)
  class HMclEval < Handler
    def setup
      register_eval
    end

    def register_eval
      register_command :eval, desc: "evals MCL code from pastebin ID", acl: :root do |player, args|
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
