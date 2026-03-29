class CreateApiTokenPermissions < ActiveRecord::Migration[8.0]
  def change
    create_table :api_token_permissions do |t|
      t.references :api_token, null: false, foreign_key: true
      t.references :permission, null: false, foreign_key: true

      t.timestamps
    end
    add_index :api_token_permissions, [:api_token_id, :permission_id], unique: true
  end
end
