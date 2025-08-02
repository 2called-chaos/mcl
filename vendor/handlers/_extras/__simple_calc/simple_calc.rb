module Mcl
  require "dentaku"

  Mcl.reloadable(:HMclSimpleCalc)
  ## Simple calculator
  # != clear
  # != list
  # != variable = <expression>
  # != <expression>
  class HMclSimpleCalc < Handler
    def setup
      register_equal :guest
    end

    def register_equal acl_level
      register_command :calc, :"=", desc: "evaluates mathematical expressions", acl: acl_level do |player, args|
        if args.join == "clear"
          memory(player).tap{|v|
            tellm(player, {text: "Cleared ", color: "yellow"}, {text: "#{v[:variables].length}", color: "aqua"}, {text: " variables!", color: "yellow"})
          }[:variables] = {}
        elsif args.join == "list"
          variables = (memory(player)[:variables] ||= {})
          if variables.any?
            variables.each do |name, value|
              tellm(player, { text: "#{name}", color: "yellow" }, { text: " = ", color: "aqua" }, { text: "#{value}", color: "gold" })
            end
          else
            tellm(player, {text: "You have no variables set!", color: "yellow"})
          end
        elsif m = args.join.match(/\A([a-z0-9\-_]+)=(.*)\z/i)
          variables = (memory(player)[:variables] ||= {})
          variables[m[1]] = m[2]
          tellm(player, {text: "Set variable ", color: "aqua"}, { text: "#{m[1]}", color: "yellow" }, { text: " = ", color: "aqua" }, { text: "#{m[2]}", color: "gold" })
        elsif args.any?
          begin
            calc = Dentaku::Calculator.new
            variables = (memory(player)[:variables] ||= {})
            expression = args.join(" ")
            result = calc.evaluate!(expression, variables)
            tellm(player, { text: "#{expression}", color: "yellow" }, { text: " = ", color: "green" }, { text: "#{result}", color: "gold" })
          rescue Exception
            tellm(player, { text: "#{$!.message}", color: "red" })
          end
        else
          tellm(player,
            { text: "We use ", color: "yellow" },
            { text: "dentaku ", color: "gold" },
            { text: "for calculations ", color: "yellow" },
            {
              text: "(clickme)",
              underlined: true,
              italic: true,
              color: "aqua",
              hoverEvent: { action: "show_text", value: "open documentation" },
              clickEvent: { action: "open_url", value: "https://github.com/rubysolo/dentaku" }
            }
          )
          tellm(player, {text: "!= list|clear", color: "gold"}, { text: " list/clear all variables" })
          tellm(player, {text: "!= variable = expression", color: "gold"}, { text: " set variable (expression can be omitted to unset variable)" })
          tellm(player, {text: "!= <expression>", color: "gold"}, { text: " calculate expression" })
        end
      end
    end

    module Helper
      def memory player
        pmemo(player, :simple_calculator)
      end

      def tellm player, *msg
        trawt(player, "calc", *msg)
      end
    end
    include Helper
  end
end
