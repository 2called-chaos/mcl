module Mcl
  Mcl.reloadable(:HMMclMisc)
  class HMMclMisc < Handler
    def setup
      # player position detection
      register_parser(/\A\[([^:]+): Successfully found the block at ([\d\.,\-]+),(?:\s)?([\d\.,\-]+),(?:\s)?([\d\.,\-]+?)(?:\.)?\]\z/i) do |res, r|
        pmemo(r[1])[:detected_pos] = [r[2].to_i, r[3].to_i-1, r[4].to_i]
      end

      # player position detection (1.13)
      register_parser(/\ATeleported ([^\s]+) to ([\d\.,\-]+),(?:\s)?([\d\.,\-]+),(?:\s)?([\d\.,\-]+?)(?:\.)?\z/i) do |res, r|
        pmemo(r[1])[:detected_pos] = [r[2].to_i, r[3].to_i, r[4].to_i]
      end
    end
  end
end
