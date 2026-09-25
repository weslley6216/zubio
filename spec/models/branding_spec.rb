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

    it "is invalid when brand_600 reaches 4.5:1 against neither a light nor a dark foreground" do
      branding = build(:branding, brand_600: "#7A7A7A")

      expect(branding).not_to be_valid
      expect(branding.errors[:brand_600]).to be_present
    end

    it "accepts a vivid brand_600 that fails against white but carries a dark foreground" do
      branding = build(:branding, brand_600: "#ff00bb")

      expect(Branding::ColorScale.new("#ff00bb").contrast_against_white).to be < Branding::ColorScale::MIN_CONTRAST
      expect(branding).to be_valid
    end

    it "is valid without a brand_secondary_600" do
      branding = build(:branding, brand_secondary_600: nil)

      expect(branding).to be_valid
    end

    it "is valid with a brand_secondary_600 that has sufficient contrast" do
      branding = build(:branding, :with_secondary)

      expect(branding).to be_valid
    end

    it "is invalid when brand_secondary_600 is not a 6-digit hex color" do
      branding = build(:branding, brand_secondary_600: "#fff")

      expect(branding).not_to be_valid
    end

    it "refuses a brand_secondary_600 without contrast with the same message as the brand color" do
      branding = build(:branding, brand_secondary_600: "#7A7A7A")

      expect(branding).not_to be_valid
      expect(branding.errors[:brand_secondary_600]).to eq([ Branding::CONTRAST_MESSAGE ])
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

    it "is invalid when a spoofed image/png header does not match the file's real (PDF) bytes" do
      branding = build(:branding)
      branding.logo.attach(
        io: StringIO.new("%PDF-1.4 fake pdf content"),
        filename: "logo.png",
        content_type: "image/png"
      )

      expect(branding).not_to be_valid
      expect(branding.logo.blob.content_type).to eq("application/pdf")
    end

    it "is invalid when the logo has an image extension but text bytes" do
      branding = build(:branding)
      branding.logo.attach(
        io: StringIO.new("not an image"),
        filename: "logo.png",
        content_type: "image/png"
      )

      expect(branding).not_to be_valid
      expect(branding.errors[:logo]).to eq([ Branding::INVALID_IMAGE_MESSAGE ])
    end

    it "is invalid when the logo is a truncated image the processor cannot decode" do
      branding = build(:branding)
      branding.logo.attach(
        io: StringIO.new(File.binread(Rails.root.join("spec/fixtures/files/logo.png"))[0, 40]),
        filename: "logo.png",
        content_type: "image/png"
      )

      expect(branding).not_to be_valid
      expect(branding.errors[:logo]).to eq([ Branding::INVALID_IMAGE_MESSAGE ])
    end

    it "accepts a real PNG logo" do
      branding = build(:branding, :with_logo)

      expect(branding).to be_valid
    end

    it "accepts a real PNG logo assigned by signed id, as a direct upload does" do
      blob = ActiveStorage::Blob.create_and_upload!(
        io: File.open(Rails.root.join("spec/fixtures/files/logo.png")),
        filename: "logo.png",
        content_type: "image/png"
      )
      branding = build(:branding)

      branding.logo = blob.signed_id

      expect(branding).to be_valid
    end

    it "does not re-check an already stored logo when another field changes" do
      branding = create(:branding, :with_logo)
      branding.reload

      branding.brand_600 = "#2C6CB0"

      expect(branding).to be_valid
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

  describe ".resolve_color" do
    it "takes the chosen swatch when the choice is a color" do
      expect(Branding.resolve_color("#2F6FED", "#000000")).to eq("#2F6FED")
    end

    it "takes the typed code when the choice is the custom sentinel" do
      expect(Branding.resolve_color(Branding::CUSTOM_COLOR_CHOICE, "#2F6FED")).to eq("#2F6FED")
    end

    it "resolves an empty choice to nothing, so an optional color clears instead of storing a blank" do
      expect(Branding.resolve_color("", nil)).to be_nil
    end
  end

  describe "#css_variables" do
    def role(css, name) = css[/--#{name}:(#\h{6});/, 1]

    def contrast(foreground, background)
      Branding::ColorScale.new(foreground).contrast_against(Branding::ColorScale.new(background))
    end

    def role_failures(css, prefix, theme)
      neutrals = Branding::NEUTRALS.fetch(theme).values
      ink = role(css, "#{prefix}-ink-#{theme}")
      mark = role(css, "#{prefix}-mark-#{theme}")
      soft = role(css, "#{prefix}-soft-#{theme}")
      soft_ink = role(css, "#{prefix}-soft-ink-#{theme}")

      [
        ("ink" if neutrals.any? { |neutral| contrast(ink, neutral) < Branding::ColorScale::MIN_CONTRAST }),
        ("mark" if neutrals.any? { |neutral| contrast(mark, neutral) < Branding::ColorScale::MIN_NON_TEXT_CONTRAST }),
        ("soft-ink" if contrast(soft_ink, soft) < Branding::ColorScale::MIN_CONTRAST)
      ].compact
    end

    it "includes the brand scale and the on-brand token" do
      branding = build(:branding, brand_600: "#4F46E5")

      expect(branding.css_variables).to include("--brand-600:#4F46E5;")
      expect(branding.css_variables).to include("--on-brand:")
    end

    it "carries a foreground for the dark accent step, not only for step 600" do
      branding = build(:branding, brand_600: "#4F46E5")
      dark_accent = Branding::ColorScale.new(branding.color_scale.tokens[Branding::DARK_ACCENT_STEP])

      expect(branding.css_variables).to include("--on-brand-400:#{dark_accent.foreground};")
    end

    it "picks opposite foregrounds for the two accent steps of a mid-luminance brand" do
      branding = build(:branding, brand_600: "#0B7658")

      expect(branding.css_variables).to include("--on-brand:#{Branding::ColorScale::WHITE};")
      expect(branding.css_variables).to include("--on-brand-400:#{Branding::ColorScale::DARK_NEUTRAL};")
    end

    it "falls back to the default color instead of raising when brand_600 is not a well-formed hex" do
      branding = build(:branding, brand_600: "not-a-hex")

      expect { branding.css_variables }.not_to raise_error
      expect(branding.css_variables).to include("--brand-600:#{Branding::DEFAULT_BRAND_600};")
    end

    it "falls back to the brand ramp for the secondary tokens when no secondary color is set" do
      branding = build(:branding, brand_600: "#4F46E5", brand_secondary_600: nil)

      expect(branding.css_variables).to include("--secondary-600:#4F46E5;")
      expect(branding.css_variables).to include("--on-secondary:#{branding.color_scale.foreground};")
    end

    it "gives every secondary token the value of its brand counterpart when no secondary color is set, so nothing already painted changes" do
      branding = build(:branding, brand_600: "#BE123C", brand_secondary_600: nil)

      renamed = branding.css_variables.scan(/--(?:on-)?secondary[\w-]*:[^;]+;/).map { |token| token.sub("secondary", "brand") }

      expect(renamed).not_to be_empty
      expect(renamed).to eq(branding.css_variables.scan(/--(?:on-)?brand[\w-]*:[^;]+;/))
    end

    it "keeps the two ramps apart when a secondary color is set" do
      branding = build(:branding, brand_600: "#BE123C", brand_secondary_600: "#1E60C4")

      expect(branding.css_variables).to include("--brand-600:#BE123C;")
      expect(branding.css_variables).to include("--secondary-600:#1E60C4;")
    end

    it "carries a foreground for the secondary dark accent step, as it already does for the brand" do
      branding = build(:branding, brand_600: "#4F46E5", brand_secondary_600: "#0B7658")
      dark_accent = Branding::ColorScale.new(Branding::ColorScale.new("#0B7658").tokens[Branding::DARK_ACCENT_STEP])

      expect(branding.css_variables).to include("--on-secondary-400:#{dark_accent.foreground};")
    end

    it "falls back to the brand ramp when brand_secondary_600 is not a well-formed hex" do
      branding = build(:branding, brand_600: "#4F46E5", brand_secondary_600: "not-a-hex")

      expect { branding.css_variables }.not_to raise_error
      expect(branding.css_variables).to include("--secondary-600:#4F46E5;")
    end

    it "gives every swatch, as brand and as secondary, a label and an underline that read on every neutral and a light pair that reads, in both themes" do
      failures = Branding::Palette.swatches.flat_map do |hex|
        css = build(:branding, brand_600: hex, brand_secondary_600: hex).css_variables

        %w[brand secondary].product(Branding::NEUTRALS.keys).flat_map do |prefix, theme|
          role_failures(css, prefix, theme).map { |failure| "#{hex} #{prefix} #{theme} #{failure}" }
        end
      end

      expect(Branding::Palette.swatches.size).to eq(24)
      expect(failures).to be_empty
    end

    it "catches a label that does not read on the neutrals" do
      css = build(:branding, brand_600: "#EAB308").css_variables.sub(/--brand-ink-light:#\h{6};/, "--brand-ink-light:#EAB308;")

      expect(role_failures(css, "brand", :light)).to include("ink")
    end

    it "labels a light yellow brand on a darker step of its ramp, because the chosen color fails on the neutrals" do
      branding = build(:branding, brand_600: "#EAB308")

      css = branding.css_variables

      expect(role(css, "brand-ink-light")).not_to eq("#EAB308")
      expect(role(css, "brand-ink-light")).to eq(branding.color_scale.tokens.fetch(900))
    end

    it "keeps the chosen color as the label when it already reads on every neutral" do
      css = build(:branding, brand_600: "#2C6CB0").css_variables

      expect(role(css, "brand-ink-light")).to eq("#2C6CB0")
    end

    it "underlines with the chosen secondary color itself when it reaches the non-text minimum on every neutral" do
      css = build(:branding, brand_600: "#2C6CB0", brand_secondary_600: "#E8493C").css_variables

      expect(role(css, "secondary-mark-light")).to eq("#E8493C")
      expect(role(css, "secondary-ink-light")).not_to eq("#E8493C")
    end

    it "takes the light pair from the end of the ramp that belongs to each theme" do
      branding = build(:branding, brand_600: "#2C6CB0")

      css = branding.css_variables

      expect(role(css, "brand-soft-light")).to eq(branding.color_scale.tokens.fetch(50))
      expect(role(css, "brand-soft-dark")).to eq(branding.color_scale.tokens.fetch(900))
    end

    it "draws the secondary underline and light pair from the brand ramp when no secondary color is set" do
      lone = build(:branding, brand_600: "#2C6CB0", brand_secondary_600: nil).css_variables
      paired = build(:branding, brand_600: "#2C6CB0", brand_secondary_600: "#E8493C").css_variables
      roles = %w[mark-light mark-dark soft-light soft-dark soft-ink-light soft-ink-dark]

      expect(roles.map { |name| role(lone, "secondary-#{name}") }).to eq(roles.map { |name| role(lone, "brand-#{name}") })
      expect(role(paired, "secondary-mark-light")).not_to eq(role(paired, "brand-mark-light"))
    end

    it "derives the same ramp through the class method that the instance uses" do
      scale = Branding::ColorScale.new("#4F46E5")

      expect(Branding.ramp_variables("brand", scale)).to include("--brand-600:#4F46E5;")
      expect(Branding.ramp_variables("brand", scale)).to include("--brand-ink-light:")
    end
  end

  describe "#stylesheet" do
    it "wraps the brand scale in a root rule a browser can apply on its own" do
      branding = build(:branding, brand_600: "#4F46E5")

      expect(branding.stylesheet).to start_with(":root{")
      expect(branding.stylesheet).to include("--brand-600:#4F46E5;")
      expect(branding.stylesheet).to end_with("}")
    end
  end

  describe "#stylesheet_digest" do
    it "repeats for the same brand and changes for a different one" do
      indigo = build(:branding, brand_600: "#4F46E5")
      twin = build(:branding, brand_600: "#4F46E5")
      crimson = build(:branding, brand_600: "#B42318")

      expect(indigo.stylesheet_digest).to eq(twin.stylesheet_digest)
      expect(indigo.stylesheet_digest).not_to eq(crimson.stylesheet_digest)
    end

    it "is short enough to travel in a URL" do
      expect(build(:branding).stylesheet_digest.length).to eq(StylesheetProducer::DIGEST_LENGTH)
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

  describe "#header_logo" do
    it "is nil when no logo is attached" do
      branding = create(:branding)

      expect(branding.header_logo).to be_nil
    end

    it "returns a variant limited to the header size when a logo is attached" do
      branding = create(:branding, :with_logo)

      expect(branding.header_logo.variation.transformations[:resize_to_limit]).to eq(Branding::HEADER_LOGO_LIMIT)
    end

    it "is nil when a rejected upload left an attachment whose blob was never persisted" do
      branding = build(:branding, :with_logo)

      expect(branding.header_logo).to be_nil
    end
  end
end
