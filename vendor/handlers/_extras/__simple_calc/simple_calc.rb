module Mcl
  Mcl.reloadable(:HMclSimpleCalc)
  ## Simple calculator
  # != <expression>
  class HMclSimpleCalc < Handler
    def setup
      register_equal
    end

    def register_equal
      register_command :calc, :"=", desc: "evaluates mathematical expressions", acl: :root do |player, args|
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
