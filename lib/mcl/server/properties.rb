module Mcl
  class Server
    class Properties
      attr_reader :file, :data
      include Enumerable

      def initialize file
        @file = file
        reload
      end

      def reload
        @data = {}
        return unless File.exist?(@file)
        File.open(@file).each_line do |line|
          if line.strip.start_with?("#")
            @data[line.strip] = :comment
          else
            chunks = line.split("=")
            key    = chunks.shift
            v      = chunks.join("=").strip.presence

            # convert to proper types
            v = v.to_i if v =~ /\A[0-9]+\Z/ # integer
            v = true if v == "true"
            v = false if v == "false"

            @data[key] = v
          end
        end
        @data
      end

      def save
        out = @data.each_with_object([]) do |(k, v), o|
          if v == :comment
            o << k
          elsif k.present?
            o << "#{k}=#{v}"
          end
        end

        actfile = File.symlink?(@file) ? File.readlink(@file) : @file

        File.unlink("#{actfile}.backup") if File.exist?("#{actfile}.backup")
        FileUtils.cp(actfile, "#{actfile}.backup") if File.exist?(actfile)
        File.open("#{actfile}.tmp", "wb") {|f| f.puts *out }
        File.unlink(actfile) if File.exist?(actfile)
        FileUtils.mv("#{actfile}.tmp", actfile)
        reload
      end

      def key? *a
        @data.key?(*a)
      end

      def [] k
        @data[k]
      end

      def update hsh = {}
        reload
        hsh = hsh.data if hsh.is_a?(Properties)
        hsh.each {|k, v| @data[k] = v }
        save
      end

      def each &block
        @data.each(&block)
      end
    end
  end
end
