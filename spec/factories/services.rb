FactoryBot.define do
  factory :service do
    initialize_with { ActsAsTenant.with_tenant(tenant) { new(tenant: tenant) } }
    to_create { |service| ActsAsTenant.with_tenant(service.tenant) { service.save! } }

    tenant
    sequence(:name) { |index| "Service #{index}" }
    duration_minutes { 45 }
    price_cents { 9_000 }
  end
end
