module Mcl
  class LagtrackLog < ActiveRecord::Base
    scope :for_world, ->(world) { where(world: world) }
  end
end
