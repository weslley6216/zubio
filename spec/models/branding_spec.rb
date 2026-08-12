require "rails_helper"

RSpec.describe Branding, type: :model do
  describe "validations" do
    it "is valid with a well-formed hex brand_600 with sufficient contrast" do
      branding = build(:branding, brand_600: "#4F46E5")

      expect(branding).to be_valid
    end

    it "is invalid without a brand_600" do
      branding = build(:branding, brand_600: nil)

      expect(branding).not_to be_valid
    end

    it "is invalid when brand_600 is not a 6-digit hex color" do
      branding = build(:branding, brand_600: "#fff")

      expect(branding).not_to be_valid
    end

    it "is invalid when brand_600 carries a CSS injection payload" do
      branding = build(:branding, brand_600: "#4F46E5; } body { display: none } .x {")

      expect(branding).not_to be_valid
    end

    it "is invalid when brand_600 does not reach 4.5:1 contrast against white" do
      branding = build(:branding, brand_600: "#EEEEEE")

      expect(branding).not_to be_valid
    end

    it "is invalid when logo content type is not png, jpeg or webp" do
      branding = build(:branding)
      branding.logo.attach(
        io: StringIO.new("%PDF-1.4 fake pdf content"),
        filename: "logo.pdf",
        content_type: "application/pdf"
      )

      expect(branding).not_to be_valid
    end

    it "is invalid when logo exceeds the maximum upload size" do
      branding = build(:branding)
      branding.logo.attach(
        io: StringIO.new("a" * (Branding::LOGO_MAX_BYTES + 1)),
        filename: "logo.png",
        content_type: "image/png"
      )

      expect(branding).not_to be_valid
    end
  end

  describe ".platform_default" do
    it "returns an unpersisted branding with the platform's default color" do
      branding = Branding.platform_default

      expect(branding).not_to be_persisted
      expect(branding.brand_600).to eq(Branding::DEFAULT_BRAND_600)
    end

    it "has a default color that satisfies the brand_600 format and contrast validation" do
      branding = Branding.platform_default
      branding.valid?

      expect(branding.errors[:brand_600]).to be_empty
    end
  end

  describe "#css_variables" do
    it "includes the brand scale and the on-brand token" do
      branding = build(:branding, brand_600: "#4F46E5")

      expect(branding.css_variables).to include("--brand-600:#4F46E5;")
      expect(branding.css_variables).to include("--on-brand:")
    end
  end

  describe "tenant association" do
    it "is accessible from its tenant" do
      tenant = create(:tenant)
      branding = create(:branding, tenant: tenant)

      expect(tenant.branding).to eq(branding)
    end
  end

  describe "tenant isolation" do
    it "does not include brandings from another tenant" do
      tenant_a = create(:tenant)
      tenant_b = create(:tenant)
      create(:branding, tenant: tenant_a)

      result = ActsAsTenant.with_tenant(tenant_b) { Branding.all }

      expect(result).to be_empty
    end

    it "includes the branding from its own tenant" do
      tenant = create(:tenant)
      branding = create(:branding, tenant: tenant)

      result = ActsAsTenant.with_tenant(tenant) { Branding.all }

      expect(result).to include(branding)
    end
  end

  describe "#icon_variants" do
    it "is empty when no logo is attached" do
      branding = create(:branding)

      expect(branding.icon_variants).to eq([])
    end

    it "returns a 192 and 512 'any' variant plus a 512 'maskable' variant when a logo is attached" do
      branding = create(:branding, :with_logo)

      sizes_and_purposes = branding.icon_variants.map { |icon| [ icon[:sizes], icon[:purpose] ] }

      expect(sizes_and_purposes).to contain_exactly(
        [ "192x192", "any" ],
        [ "512x512", "any" ],
        [ "512x512", "maskable" ]
      )
    end
  end
end
