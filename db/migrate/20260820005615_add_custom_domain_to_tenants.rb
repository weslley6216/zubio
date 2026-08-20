class AddCustomDomainToTenants < ActiveRecord::Migration[8.1]
  def change
    add_column :tenants, :custom_domain, :citext
    add_column :tenants, :custom_domain_cloudflare_id, :string
    add_column :tenants, :custom_domain_verification_txt_name, :string
    add_column :tenants, :custom_domain_verification_txt_value, :string
    add_column :tenants, :custom_domain_verified_at, :datetime
    add_index :tenants, :custom_domain, unique: true
  end
end
