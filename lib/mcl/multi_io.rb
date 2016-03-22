module Mcl
  class MultiIO
    attr_reader :targets

    def initialize *targets
      @targets = targets
      @closed = false
    end

    def add_target target
      @targets << target
    end

    def remove_target target
      @targets.delete(target)
    end

    def close
      @targets.each do |t|
        t.close unless t.instance_variable_get(:"@mcl_uncloseable")
      end
      @closed = true
    end

    [:write, :puts, :warn, :info, :error, :fatal, :add, :debug].each do |meth|
      define_method(meth) do |*args|
        if @closed
          ::Kernel.warn "IO stream closed: (#{meth}) #{args.inspect}"
        else
          @targets.each {|t| t.send(meth, *args) }
        end
      end
    end

    def method_missing meth, *args, &block
      @targets.each {|t| t.send(meth, *args, &block) }
    end
  end
end
