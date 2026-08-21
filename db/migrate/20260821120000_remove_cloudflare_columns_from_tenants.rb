class RemoveCloudflareColumnsFromTenants < ActiveRecord::Migration[8.1]
  def change
    remove_column :tenants, :custom_domain_cloudflare_id, :string
    remove_column :tenants, :custom_domain_verification_txt_name, :string
    remove_column :tenants, :custom_domain_verification_txt_value, :string
  end
end
