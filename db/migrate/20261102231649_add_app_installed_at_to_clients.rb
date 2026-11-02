class AddAppInstalledAtToClients < ActiveRecord::Migration[8.1]
  def change
    add_column :clients, :app_installed_at, :datetime
  end
end
