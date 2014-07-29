module Mcl
  # sublime indents bugs if there is no line here -.-
  class Event < ActiveRecord::Base
    # ==========
    # = Scopes =
    # ==========
    scope :ordered, -> { reorder(date: :asc) }
    scope :processed, -> { ordered.where(processed: true) }
    scope :unprocessed, -> { ordered.where(processed: false) }
    scope :commands, -> { ordered.where(command: true) }
    scope :non_commands, -> { ordered.where(command: false) }

    # ===============
    # = Validations =
    # ===============
    validates :thread, :channel, presence: true

    def self.build_from_classification res
      klass = "#{res.type.to_s.camelize}Event".constantize rescue nil
      klass ||= UnknownEvent
      klass.new do |e|
        [:thread, :channel, :origin_type, :subtype, :origin, :data, :command, :date].each do |val|
          e.send("#{val}=", res.send(val))
        end
      end
    end
  end
end
