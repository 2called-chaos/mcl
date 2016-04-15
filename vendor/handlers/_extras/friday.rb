module Mcl
  Mcl.reloadable(:HMclFriday)
  ## Is it friday already?
  class HMclFriday < Handler
    def setup
      register_command [:friday, :friday?, :isitfriday?], desc: "Is it friday already?", acl: :guest do |player, args|
        if Time.now.friday?
          traw(player, "Yes, it is friday! Parteeeeeeey!!!", color: "green")
        else
          traw(player, "Unfortunately not :(", color: "red")
        end
      end
    end
  end
end
