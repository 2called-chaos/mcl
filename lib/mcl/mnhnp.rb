require "strscan"

module Mcl
  class Mnhnp # Minecraft NBT Hash Notation Parser
    def self.parse! str
      new(str).parse
    end

    AST = Struct.new(:value)
    attr_reader :value

    def initialize str
      @str = str.dup
    end

    def parse
      @input = StringScanner.new(@str)
      @value = parse_value.value
    ensure
      @input.eos? or error("Unexpected data")
    end

    def parse_value
      trim_space
      parse_object  or
      parse_array   or
      parse_string  or
      parse_number  or
      parse_keyword or
      error("Illegal NBT value")
    ensure
      trim_space
    end

    def parse_object
      if @input.scan(/\{\s*/)
        object     = Hash.new
        more_pairs = false
        while key = parse_string
          @input.scan(/\s*:\s*/) or error("Expecting object separator")
          object[key.value] = parse_value.value
          more_pairs = @input.scan(/\s*,\s*/) or break
        end
        error("Missing object pair") if more_pairs
        @input.scan(/\s*\}/) or error("Unclosed object")
        AST.new(object)
      else
        false
      end
    end

    def parse_array
      if @input.scan(/\[\s*/)
        array       = Array.new
        more_values = false
        while contents = parse_value rescue nil
          array << contents.value
          more_values = @input.scan(/\s*,\s*/) or break
        end
        error("Missing value") if more_values
        @input.scan(/\s*\]/) or error("Unclosed array")
        AST.new(array)
      else
        false
      end
    end

    def parse_string
      if @input.scan(/["']/)
        quote_type = @input.matched
        string = String.new
        while contents = parse_string_content(quote_type) || parse_string_escape(quote_type)
          string << contents.value
        end
        @input.scan(/#{quote_type}/) or error("Unclosed string")
        AST.new(string)
      elsif x = @input.scan(/[a-z]+/i)
        AST.new(x)
      else
        false
      end
    end

    def parse_string_content quote_type
      @input.scan(/[^\\#{quote_type}]+/) and AST.new(@input.matched)
    end

    def parse_string_escape quote_type
      if @input.scan(%r{\\[#{quote_type}\\/]})
        AST.new(@input.matched[-1])
      elsif @input.scan(/\\[bfnrt]/)
        AST.new(eval(%Q{#{quote_type}#{@input.matched}#{quote_type}}))
      elsif @input.scan(/\\u[0-9a-fA-F]{4}/)
        AST.new([Integer("0x#{@input.matched[2..-1]}")].pack("U"))
      else
        false
      end
    end

    def parse_number
      @input.scan(/-?(?:0|[1-9]\d*)(?:\.\d+)?(?:[eE][+-]?\d+)?(?:[bdfsL])?\b/) and
      AST.new(eval(@input.matched.gsub(/[bdfsL]\z/, "")))
    end

    def parse_keyword
      @input.scan(/\b(?:true|false|null)\b/) and
      AST.new(eval(@input.matched.sub("null", "nil")))
    end

    def trim_space
      @input.scan(/\s+/)
    end

    def error(message)
      if @input.eos?
        raise "Unexpected end of input."
      else
        raise "#{message}:  #{@input.peek(@input.string.length)}"
      end
    end
  end
end
