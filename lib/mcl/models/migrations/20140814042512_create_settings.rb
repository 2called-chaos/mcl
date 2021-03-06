class CreateSettings < ActiveRecord::Migration[5.1]
  def change
    create_table :settings do |t|
      t.string :origin, default: "core"
      t.string :name
      t.string :value
      t.timestamps
    end

    add_index :settings, :origin
    add_index :settings, :name
  end
end
