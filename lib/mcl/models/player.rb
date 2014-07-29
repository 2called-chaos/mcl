module Mcl
  # sublime indents bugs if there is no line here -.-
  class Player < ActiveRecord::Base
    serialize :data, Hash

    # ===============
    # = Validations =
    # ===============
    validates :nickname, presence: true
    validates :permission, numericality: { only_integer: true }


  end
end
