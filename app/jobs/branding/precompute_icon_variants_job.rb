class Branding
  class PrecomputeIconVariantsJob < ApplicationJob
    def perform(tenant_id)
      tenant = Tenant.find(tenant_id)

      ActsAsTenant.with_tenant(tenant) do
        tenant.branding&.icon_variants&.each { |entry| entry[:variant].processed }
      end
    end
  end
end
