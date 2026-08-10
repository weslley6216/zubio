class CreateTenants < ActiveRecord::Migration[8.1]
  def change
    enable_extension "citext"

    create_table :tenants do |t|
      t.citext :subdomain, null: false
      t.string :name, null: false
      t.string :status, null: false, default: "active"

      t.timestamps
    end

    add_index :tenants, :subdomain, unique: true
  end
end
