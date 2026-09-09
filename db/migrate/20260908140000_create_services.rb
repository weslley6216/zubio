class CreateServices < ActiveRecord::Migration[8.1]
  def change
    create_table :services do |t|
      t.references :tenant, null: false, foreign_key: true
      t.citext :name, null: false
      t.text :description
      t.integer :duration_minutes, null: false
      t.integer :price_cents, null: false
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :services, [ :tenant_id, :name ], unique: true
  end
end
