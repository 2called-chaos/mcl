class CreateLagtrackLogs < ActiveRecord::Migration[5.1]
  def change
    create_table :lagtrack_logs do |t|
      t.string :world
      t.integer :delay
      t.integer :skipped_ticks
      t.datetime :tracked_at

      t.timestamps
    end

    add_index :lagtrack_logs, :world
    add_index :lagtrack_logs, :tracked_at
    add_index :lagtrack_logs, :delay
    add_index :lagtrack_logs, :skipped_ticks
  end
end
