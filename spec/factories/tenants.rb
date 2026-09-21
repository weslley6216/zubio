FactoryBot.define do
  factory :tenant do
    sequence(:subdomain) { |index| "establishment-#{index}" }
    name { "Test Establishment" }
    status { "active" }
    onboarding_completed_at { Time.current }

    trait :onboarding do
      name { nil }
      onboarding_completed_at { nil }
    end

    trait :with_pending_custom_domain do
      custom_domain { "barbeariadoze.com.br" }
    end

    trait :with_verified_custom_domain do
      with_pending_custom_domain
      custom_domain_verified_at { Time.current }
    end
  end
end
