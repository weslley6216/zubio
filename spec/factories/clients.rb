FactoryBot.define do
  factory :client do
    initialize_with { ActsAsTenant.with_tenant(tenant) { new(tenant: tenant) } }
    to_create { |client| ActsAsTenant.with_tenant(client.tenant) { client.save! } }

    tenant
    name { "Test Client" }
    sequence(:phone) { |index| "119#{format('%08d', index)}" }
  end
end
