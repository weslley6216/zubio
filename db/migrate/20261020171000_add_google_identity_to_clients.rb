class AddGoogleIdentityToClients < ActiveRecord::Migration[8.1]
  def change
    add_column :clients, :email, :string
    add_column :clients, :google_uid, :string
    add_column :clients, :account_linked_at, :datetime
    add_column :clients, :handoff_generation, :integer, default: 0, null: false

    add_index :clients, [ :tenant_id, :google_uid ], unique: true, where: "google_uid IS NOT NULL",
      name: "index_clients_on_tenant_id_and_google_uid"
  end
end
