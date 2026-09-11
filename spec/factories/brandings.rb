FactoryBot.define do
  factory :branding do
    initialize_with { ActsAsTenant.with_tenant(tenant) { new(tenant: tenant) } }
    to_create { |branding| ActsAsTenant.with_tenant(branding.tenant) { branding.save! } }

    tenant
    brand_600 { "#4F46E5" }

    trait :with_secondary do
      brand_secondary_600 { "#1E60C4" }
    end

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
