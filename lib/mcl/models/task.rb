module Mcl
  class Task < ActiveRecord::Base
    scope :overdue, -> { order(run_at: :desc).where("run_at < ?", Time.current) }
  end
end
