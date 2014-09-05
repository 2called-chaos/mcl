class StringExpandRange
  def self.expand str
    new(str).expand
  end

  def initialize str
    @str    = str.dup
    @list   = [""]
    @chunks = @str.split(/(\[[^\]]+\])/i).reject(&:blank?)
  end

  def append str
    @list.each{|s| s << str }
  end

  def add str
    @list << str
  end

  def multiply_with list
    @list.replace(@list.product(list).map(&:join))
  end

  def expand
    @chunks.each do |chunk|
      if chunk.start_with?("[") && chunk.end_with?("]")
        # expression, expand it and multiply with list
        multiply_with expand_expression(chunk[1..-2])
      else
        # normal part, append it to all list entries
        append(chunk)
      end
    end

    @list.sort
  end

  def expand_expression expression
    reg = [[],[]]

    expression.split(",").map(&:strip).reject(&:blank?).each do |part|
      # negate?
      index = 0
      if part.start_with?("^")
        index = 1
        part = part[1..-1]
      end

      # range or element
      if m = part.match(/([^-]+)\-([^-]+)/i)
        reg[index].concat (m[1]..m[2]).to_a
      else
        reg[index] << part
      end
    end

    reg[0] - reg[1]
  end
end
