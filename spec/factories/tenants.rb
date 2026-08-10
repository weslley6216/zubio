FactoryBot.define do
  factory :tenant do
    sequence(:subdomain) { |n| "establishment-#{n}" }
    name { "Test Establishment" }
    status { "active" }
  end
end
