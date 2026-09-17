FactoryBot.define do
  factory :working_hour do
    initialize_with { ActsAsTenant.with_tenant(tenant) { new(tenant: tenant) } }
    to_create { |working_hour| ActsAsTenant.with_tenant(working_hour.tenant) { working_hour.save! } }

    tenant
    professional { association :professional, tenant: tenant }
    weekday { 1 }
    opens_at { "09:00" }
    closes_at { "18:00" }
  end
end
