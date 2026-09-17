FactoryBot.define do
  factory :tenant do
    sequence(:subdomain) { |index| "establishment-#{index}" }
    name { "Test Establishment" }
    status { "active" }
    onboarding_step { :done }

    trait :onboarding do
      name { nil }
      onboarding_step { :welcome }
    end

    trait :at_colors do
      onboarding
      onboarding_step { :colors }
    end

    trait :at_name do
      onboarding
      onboarding_step { :name }
    end

    trait :at_logo do
      onboarding
      onboarding_step { :logo }
    end

    trait :at_services do
      onboarding
      onboarding_step { :services }
    end

    trait :at_working_hours do
      onboarding
      onboarding_step { :working_hours }
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
