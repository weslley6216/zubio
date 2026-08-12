FactoryBot.define do
  factory :user do
    tenant
    sequence(:email) { |n| "user-#{n}@example.com" }
    name { "Test User" }
    password { "s3cr3t123" }
    role { "owner" }

    trait :owner do
      role { "owner" }
    end

    trait :admin do
      role { "admin" }
    end

    trait :professional do
      role { "professional" }
    end
  end
end
