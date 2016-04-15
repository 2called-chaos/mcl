module Mcl
  Mcl.reloadable(:HMclFriday)
  ## Is it friday already?
  class HMclFriday < Handler
    def setup
      [:monday, :thuesday, :wednesday, :thirsday, :friday, :saturday, :sunday].each do |day|
        register_command [:"#{day}", :"#{day}?", :"isit#{day}?"], desc: "Is it #{day} already?", acl: :guest do |player, args|
          if Time.now.friday?
            traw(player, "Yes, it is #{day}! Parteeeeeeey!!!", color: "green")
          else
            traw(player, "Unfortunately not :(", color: "red")
          end
        end
      end
    end
  end
end
