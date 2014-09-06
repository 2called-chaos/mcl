module Mcl
  # sublime indents bugs if there is no line here -.-
  class Player < ActiveRecord::Base
    def self.fseconds secs
      t_minute = 60
      t_hour = t_minute * 60
      t_day = t_hour * 24
      t_week = t_day * 7
      "".tap do |r|
        if secs >= t_week
          r << "#{secs / t_week}d "
          secs = secs % t_week
        end

        if secs >= t_day || !r.blank?
          r << "#{secs / t_day}d "
          secs = secs % t_day
        end

        if secs >= t_hour || !r.blank?
          r << "#{secs / t_hour}d "
          secs = secs % t_hour
        end

        if secs >= t_minute || !r.blank?
          r << "#{secs / t_minute}d "
          secs = secs % t_minute
        end

        r << "#{secs}s"
      end.strip
    end

    # ------

    serialize :data, Hash
    scope :online, -> { where(online: true) }
    scope :offline, -> { where(online: false) }

    # ===============
    # = Validations =
    # ===============
    validates :nickname, presence: true
    validates :permission, numericality: { only_integer: true }

    def ram scope = nil
      $mcl.ram[:players][nickname] ||= {}
      $mcl.ram[:players][nickname][scope] ||= {} if scope
    end
  end
end
