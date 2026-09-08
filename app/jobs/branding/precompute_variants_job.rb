class Branding
  class PrecomputeVariantsJob < ApplicationJob
    def perform(tenant_id)
      tenant = Tenant.find(tenant_id)

      ActsAsTenant.with_tenant(tenant) do
        branding = tenant.branding
        branding&.icon_variants&.each { |entry| entry[:variant].processed }
        branding&.header_logo&.processed
      end
    end
  end
end
