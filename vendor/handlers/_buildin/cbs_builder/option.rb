module Mcl
  class HMclCBSBuilder
    class Option
      attr_accessor :name, :default, :allowed, :help

      def initialize name, data
        @name = name
        @system = !!data["system"]
        @default = data["default"]
        @allowed = data["allowed"] || "string"
        @help = data["help"]
      end

      def value
        @value || default
      end

      def value?
        !!@value
      end

      def system?
        @system
      end

      def unset
        @value = nil
      end

      def value= val
        case @allowed
          when NilClass, "string" then nil
          when "integer"
            raise "`#{val}' is not an integer" unless val.to_s =~ /\A(\-)?([0-9]+)\z/
          else
            raise "unknown allow filter `#{@allowed}'"
        end
        @value = val
      end

      def apply str
        str.gsub("%#{name}%", "#{value}")
      end

      def apply! str
        str.gsub!("%#{name}%", "#{value}")
      end
    end
  end
end
