module Mcl
  require "dentaku"

  Mcl.reloadable(:HMclSimpleCalc)
  ## Simple calculator
  # != <expression>
  class HMclSimpleCalc < Handler
    def setup
      register_equal :guest
    end

    def register_equal acl_level
      register_command :calc, :"=", desc: "evaluates mathematical expressions", acl: acl_level do |player, args|
        if args.any?
          begin
            expression = args.join(" ")
            calc = Dentaku::Calculator.new
            result = calc.evaluate(expression)
            traw(player, "[calc] #{expression} = #{result}", color: "yellow")
          rescue Exception
            traw(player, "[calc] #{$!.message}", color: "red")
          end
        else
          traw(player, "[calc] != <expression>", color: "red")
        end
      end
    end
  end
end
