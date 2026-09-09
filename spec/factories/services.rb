FactoryBot.define do
  factory :service do
    tenant
    sequence(:name) { |index| "Service #{index}" }
    duration_minutes { 45 }
    price_cents { 9_000 }
  end
end
