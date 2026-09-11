require "rails_helper"

RSpec.describe Landing::ShowcaseBrand do
  describe ".all" do
    it "exposes every showcase brand in a stable order" do
      expect(described_class.all.map(&:key)).to eq(%w[salao estetica barbearia clinica])
    end

    it "gives every brand two services with a price and a duration" do
      described_class.all.each do |showcase_brand|
        expect(showcase_brand.services.size).to eq(2)
        expect(showcase_brand.services.map(&:price)).to all(start_with("R$"))
        expect(showcase_brand.services.map(&:duration)).to all(include("min"))
      end
    end

    it "hands out a catalog no caller can mutate" do
      expect { described_class.all << described_class.all.first }.to raise_error(FrozenError)
      expect(described_class.all.size).to eq(4)
    end

    it "gives every brand a host under the platform domain" do
      expect(described_class.all.map(&:host)).to all(end_with(".zubio.com.br"))
    end
  end

  describe "color quality" do
    it "holds only colors the platform would accept from a real establishment" do
      described_class.all.each do |showcase_brand|
        contrast = Branding::ColorScale.new(showcase_brand.brand_600).contrast_against_white

        expect(contrast).to be >= Branding::ColorScale::MIN_CONTRAST
      end
    end
  end

  describe ".stylesheet" do
    it "scopes every ramp under the demo namespace" do
      rules = described_class.stylesheet

      expect(rules).to include(%([data-demo-brand="barbearia"]{))
      expect(rules).to include("--demo-600:#96590B;")
    end

    it "never emits the tenant brand namespace" do
      expect(described_class.stylesheet).not_to include("--brand-")
    end

    it "paints each swatch from the stylesheet instead of a style attribute" do
      rules = described_class.stylesheet

      expect(rules).to include(%([data-demo-swatch="salao"]{background:#5A3FE0}))
      expect(rules).to include(%([data-demo-swatch="clinica"]{background:#1E60C4}))
    end

    it "reveals only the variant matching the selected brand" do
      rules = described_class.stylesheet

      expect(rules).to include(%([data-demo-brand="clinica"] [data-demo-for="clinica"]{display:inline}))
    end

    it "carries a ramp for every brand in the catalog" do
      rules = described_class.stylesheet

      expect(described_class.all.map(&:key)).to all(satisfy { |key| rules.include?(%([data-demo-brand="#{key}"]{)) })
    end
  end

  describe ".stylesheet_digest" do
    it "never collides with the digest of an establishment's own sheet" do
      expect(described_class.stylesheet_digest.length).to eq(StylesheetProducer::DIGEST_LENGTH)
      expect(described_class.stylesheet_digest).not_to eq(Branding.platform_default.stylesheet_digest)
    end
  end
end
