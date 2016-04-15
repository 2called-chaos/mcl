module Mcl
  Mcl.reloadable(:HMclFriday)
  ## Is it friday already?
  class HMclFriday < Handler
    def answers
      {
        monday: "I'm sorry!",
        thuesday: "One day and you are half way done ;)",
        wednesday: "Heads up, week is half way done!",
        thursday: "One day till friday!",
        friday: "Parteeeeeeey!!!",
        saturday: "You feeling okay?",
        sunday: "Sleep long, feel good.",
      }
    end

    def setup
      [:monday, :thuesday, :wednesday, :thursday, :friday, :saturday, :sunday].each do |day|
        register_command [:"#{day}", :"#{day}?", :"isit#{day}?"], desc: "Is it #{day} already?", acl: :guest do |player, args|
          if Time.now.send(:"#{day}?")
            traw(player, "Yes, it is #{day}! #{answers[day]}", color: "green")
          else
            traw(player, "Unfortunately not :(", color: "red")
          end
        end
      end
    end
  end
end
