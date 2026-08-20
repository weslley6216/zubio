class Tenant
  class CheckCustomDomainVerificationJob < ApplicationJob
    def perform(tenant_id)
      tenant = Tenant.find(tenant_id)

      ActsAsTenant.with_tenant(tenant) { tenant.check_custom_domain_verification! }
    end
  end
end
