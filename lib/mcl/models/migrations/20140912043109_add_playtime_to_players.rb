class AddPlaytimeToPlayers < ActiveRecord::Migration[5.1]
  class Player < ActiveRecord::Base # Stub
    serialize :data, Hash
  end

  def change
    add_column :players, :playtime, :integer, default: 0
    Player.find_each do |p|
      p.playtime = p.data[:playtime]
      p.data.delete(:playtime)
      p.save!
    end
  end
end
