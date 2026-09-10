FactoryBot.define do
  factory :professional do
    initialize_with { ActsAsTenant.with_tenant(tenant) { new(tenant: tenant) } }
    to_create { |professional| ActsAsTenant.with_tenant(professional.tenant) { professional.save! } }

    tenant
    sequence(:display_name) { |index| "Professional #{index}" }
    user { association :user, tenant: tenant }

    trait :without_user do
      user { nil }
    end
  end
end
