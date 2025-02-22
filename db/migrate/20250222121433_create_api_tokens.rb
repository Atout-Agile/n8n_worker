class CreateApiTokens < ActiveRecord::Migration[8.0]
  def change
    create_table :api_tokens do |t|
      t.string :name
      t.string :token_digest
      t.datetime :last_used_at
      t.datetime :expires_at

      t.timestamps
    end
  end
end
