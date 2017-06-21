class CreatePlayers < ActiveRecord::Migration[5.1]
  def change
    create_table :players do |t|
      t.string :uuid
      t.string :nickname
      t.string :ip
      t.text :data, limit: 4294967295
      t.integer :permission, default: 0
      t.boolean :online, default: false

      t.datetime :first_connect
      t.datetime :last_connect
      t.datetime :last_disconnect
      t.timestamps
    end

    add_index :players, :uuid
    add_index :players, :nickname
    add_index :players, :online
    add_index :players, :last_connect
  end
end
