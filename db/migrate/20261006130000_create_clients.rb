class CreateClients < ActiveRecord::Migration[8.1]
  def change
    create_table :clients do |t|
      t.string :name, null: false
      t.string :phone, null: false
      t.references :tenant, null: false, foreign_key: true, index: false

      t.timestamps
    end

    add_index :clients, [ :tenant_id, :phone ], unique: true

    add_reference :appointments, :client, null: false, foreign_key: true, index: false
  end
end
