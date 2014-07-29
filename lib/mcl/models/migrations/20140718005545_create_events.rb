class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.string :thread
      t.string :channel
      t.string :origin_type, default: "unknown"
      t.string :type
      t.string :subtype
      t.text :origin
      t.text :data, limit: 4294967295
      t.boolean :command, default: false
      t.boolean :processed, default: false

      t.datetime :date
      t.timestamps
    end

    add_index :events, :thread
    add_index :events, :channel
    add_index :events, :origin_type
    add_index :events, :type
    add_index :events, :subtype
    add_index :events, :command
    add_index :events, :processed
  end
end
