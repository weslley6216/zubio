FactoryBot.define do
  factory :user do
    tenant
    sequence(:email) { |n| "user-#{n}@example.com" }
    name { "Test User" }
  end
end
