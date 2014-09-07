class CreateTasks < ActiveRecord::Migration
  def change
    create_table :tasks do |t|
      t.string :name
      t.text :handler, limit: 4294967295
      t.datetime :run_at
      t.timestamps
    end

    add_index :tasks, :name
  end
end
