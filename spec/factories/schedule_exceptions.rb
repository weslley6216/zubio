FactoryBot.define do
  factory :schedule_exception do
    initialize_with { ActsAsTenant.with_tenant(tenant) { new(tenant: tenant) } }
    to_create { |schedule_exception| ActsAsTenant.with_tenant(schedule_exception.tenant) { schedule_exception.save! } }

    tenant
    professional { association :professional, tenant: tenant }
    occurs_on { Date.current.next_week(:monday) }
    closed { true }

    trait :with_alternate_hours do
      closed { false }
      opens_at { "09:00" }
      closes_at { "12:00" }
    end
  end
end
