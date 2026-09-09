FactoryBot.define do
  factory :professional do
    tenant
    sequence(:display_name) { |index| "Professional #{index}" }
    user { association :user, tenant: tenant }

    trait :without_user do
      user { nil }
    end
  end
end
