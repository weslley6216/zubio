class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.references :tenant, null: false, foreign_key: true
      t.citext :email, null: false
      t.string :password_digest
      t.string :name, null: false
      t.string :role

      t.timestamps
    end

    add_index :users, [ :tenant_id, :email ], unique: true
  end
end
