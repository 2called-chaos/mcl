module Mcl
  class Handler
    include API
    include Helper
    include BookVerter
    include Geometry
    include Shortcuts

    attr_reader :app


    # -------

    def initialize app
      @app = app
      setup
    end

    def self.descendants
      @descendants ||= []
    end

    # Descendant tracking for inherited classes.
    def self.inherited(descendant)
      descendants << descendant
    end

    def strbool v
      v = true if ["true", "t", "1", "y", "yes", "on"].include?(v)
      v = false if ["false", "f", "0", "n", "no", "off"].include?(v)
      v
    end
  end
end
