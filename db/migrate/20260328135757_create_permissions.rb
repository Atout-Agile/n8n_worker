class CreatePermissions < ActiveRecord::Migration[8.0]
  def change
    create_table :permissions do |t|
      t.string :name, null: false
      t.string :description, null: false, default: ""
      t.boolean :deprecated, null: false, default: false

      t.timestamps
    end
    add_index :permissions, :name, unique: true
  end
end
