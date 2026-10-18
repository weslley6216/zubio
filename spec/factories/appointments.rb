FactoryBot.define do
  factory :appointment do
    initialize_with { ActsAsTenant.with_tenant(tenant) { new(tenant: tenant) } }
    to_create { |appointment| ActsAsTenant.with_tenant(appointment.tenant) { appointment.save! } }

    tenant
    professional { association :professional, tenant: tenant }
    service { association :service, tenant: tenant }
    client { association :client, tenant: tenant }
    starts_at { 1.week.from_now.change(hour: 9, min: 0, sec: 0) }

    trait :cancelled do
      status { "cancelled" }
    end

    trait :completed do
      status { "completed" }
    end

    trait :no_show do
      status { "no_show" }
    end

    trait :past do
      starts_at { 2.days.ago.change(hour: 9, min: 0, sec: 0) }
    end
  end
end
