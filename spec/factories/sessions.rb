FactoryBot.define do
  factory :session do
    initialize_with { ActsAsTenant.with_tenant(tenant) { new(tenant: tenant) } }
    to_create { |session| ActsAsTenant.with_tenant(session.tenant) { session.save! } }

    tenant
    user { association :user, tenant: tenant }
    user_agent { "RSpec" }
    ip_address { "127.0.0.1" }
  end
end
