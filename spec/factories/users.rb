FactoryBot.define do
  factory :user do
    tenant
    sequence(:email) { |index| "user-#{index}@example.com" }
    name { "Test User" }
    password { "s3cr3t123" }
    role { "owner" }

    trait :owner do
      role { "owner" }
    end

    trait :professional do
      role { "professional" }
    end
  end
end
