module Mcl
  # sublime indents bugs if there is no line here -.-
  class Setting < ActiveRecord::Base
    # ===============
    # = Validations =
    # ===============
    validates :name, presence: true, uniqueness: { case_sensitive: false }

    scope :origin, ->(origin) { where(origin: origin) }

    def self.fetch name, default = nil
      get(name) || default
    end

    def self.get name
      Setting.find_by(name: name).try(:value)
    end

    def self.seed origin, name, value
      unless Setting.origin(origin).find_by(name: name)
        Setting.create!(origin: origin, name: name, value: value)
      end
      Setting.origin(origin).find_by(name: name)
    end
  end
end
