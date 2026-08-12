FactoryBot.define do
  factory :branding do
    tenant
    brand_600 { "#4F46E5" }

    trait :with_logo do
      after(:build) do |branding|
        branding.logo.attach(
          io: File.open(Rails.root.join("spec/fixtures/files/logo.png")),
          filename: "logo.png",
          content_type: "image/png"
        )
      end
    end
  end
end
