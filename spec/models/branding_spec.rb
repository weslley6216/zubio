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

    it "no longer weighs the contrast of a support color that paints nothing" do
      branding = build(:branding, brand_secondary_600: "#7A7A7A")

      expect(branding).to be_valid
    end

    it "is valid without a background" do
      branding = build(:branding, brand_background: nil)

      expect(branding).to be_valid
    end

    it "is valid with a background its accent stands out on" do
      branding = build(:branding, :with_background)

      expect(branding).to be_valid
    end

    it "is invalid when the background is not a 6-digit hex color" do
      branding = build(:branding, brand_background: "#fff")

      expect(branding).not_to be_valid
    end

    it "is invalid when the background carries a CSS injection payload" do
      branding = build(:branding, brand_background: "#16324A;}body{")

      expect(branding).not_to be_valid
    end

    it "refuses a background no text reads on" do
      branding = build(:branding, brand_background: "#7A7A7A", brand_600: "#000000")

      expect(branding).not_to be_valid
      expect(branding.errors[:brand_background]).to eq([ Branding::CONTRAST_MESSAGE ])
    end

    it "refuses an accent lost on the background with the stands-out message" do
      branding = build(:branding, brand_background: "#16324A", brand_600: "#1E3A55")

      expect(branding).not_to be_valid
      expect(branding.errors[:brand_600]).to eq([ Branding::STANDS_OUT_MESSAGE ])
    end

    it "refuses a light accent with no background, since it would sit on the neutral" do
      branding = build(:branding, brand_600: "#F2B33D")

      expect(branding).not_to be_valid
    end

    it "accepts the same light accent over a dark background" do
      branding = build(:branding, brand_600: "#F2B33D", brand_background: "#1F4D3A")

      expect(branding).to be_valid
    end

    it "keeps a stored light accent valid when only another field changes" do
      branding = create(:branding)
      ActsAsTenant.with_tenant(branding.tenant) { branding.update_column(:brand_600, "#EAB308") }
      branding.reload

      branding.brand_secondary_600 = "#1E60C4"

      expect(branding).to be_valid
    end

    it "still refuses the stored light accent when the owner chooses it again" do
      branding = create(:branding)

      branding.brand_600 = "#EAB308"

      expect(branding).not_to be_valid
      expect(branding.errors[:brand_600]).to eq([ Branding::STANDS_OUT_MESSAGE ])
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

    it "is invalid when a direct upload signed id points to text bytes declared as PNG" do
      blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new("not an image"),
        filename: "logo.png",
        content_type: "image/png",
        identify: false
      )
      branding = build(:branding)

      branding.logo = blob.signed_id

      expect(branding).not_to be_valid
      expect(branding.errors[:logo]).to eq([ Branding::INVALID_IMAGE_MESSAGE ])
    end

    it "does not re-check an already stored logo when another field changes" do
      branding = create(:branding, :with_logo)
      branding.reload

      branding.brand_600 = "#2C6CB0"

      expect(branding).to be_valid
    end

    it "is invalid, with the oversized-dimensions message, when the logo exceeds the maximum pixel size" do
      branding = build(:branding)
      branding.logo.attach(
        io: StringIO.new(Vips::Image.black(20000, 20000).pngsave_buffer),
        filename: "huge.png",
        content_type: "image/png"
      )

      expect(branding).not_to be_valid
      expect(branding.errors[:logo]).to eq([ Branding::OVERSIZED_IMAGE_MESSAGE ])
    end

    it "is invalid when only the width exceeds the maximum pixel size" do
      branding = build(:branding)
      branding.logo.attach(
        io: StringIO.new(Vips::Image.black(Branding::LOGO_MAX_PIXELS + 1, 1).pngsave_buffer),
        filename: "wide.png",
        content_type: "image/png"
      )

      expect(branding).not_to be_valid
      expect(branding.errors[:logo]).to eq([ Branding::OVERSIZED_IMAGE_MESSAGE ])
    end

    it "is invalid when only the height exceeds the maximum pixel size" do
      branding = build(:branding)
      branding.logo.attach(
        io: StringIO.new(Vips::Image.black(1, Branding::LOGO_MAX_PIXELS + 1).pngsave_buffer),
        filename: "tall.png",
        content_type: "image/png"
      )

      expect(branding).not_to be_valid
      expect(branding.errors[:logo]).to eq([ Branding::OVERSIZED_IMAGE_MESSAGE ])
    end

    it "does not decode past the header when the logo is over the pixel ceiling" do
      branding = build(:branding, :with_logo)
      image = Vips::Image.black(1, 1)
      allow(image).to receive(:width).and_return(20000)
      allow(image).to receive(:height).and_return(20000)
      allow(Vips::Image).to receive(:new_from_buffer).and_return(image)
      expect(image).not_to receive(:avg)

      expect(branding).not_to be_valid
      expect(branding.errors[:logo]).to eq([ Branding::OVERSIZED_IMAGE_MESSAGE ])
    end

    it "decodes a logo at the pixel ceiling to confirm it is a real image" do
      branding = build(:branding, :with_logo)
      image = Vips::Image.black(1, 1)
      allow(image).to receive(:width).and_return(4096)
      allow(image).to receive(:height).and_return(4096)
      allow(Vips::Image).to receive(:new_from_buffer).and_return(image)
      expect(image).to receive(:avg).and_call_original

      expect(branding).to be_valid
    end

    it "accepts a logo at the maximum pixel size" do
      branding = build(:branding)
      branding.logo.attach(
        io: StringIO.new(Vips::Image.black(4096, 4096).pngsave_buffer),
        filename: "edge.png",
        content_type: "image/png"
      )

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

  describe "#theme" do
    it "builds the theme from the stored background and accent" do
      branding = build(:branding, :with_background)

      expect(branding.theme.tokens["card"]).to eq("#e7f0f8")
    end

    it "falls back to the neutral background when the stored one is not a well-formed hex" do
      branding = build(:branding, brand_background: "not-a-hex")

      expect(branding.theme.background).to eq("#f8fafb")
      expect { branding.css_variables }.not_to raise_error
    end
  end

  describe "#css_variables" do
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

    it "gives every swatch, as brand, a label and an underline that read on every neutral and a light pair that reads, in both themes" do
      stylesheets = Branding::Palette.swatches.map { |hex| build(:branding, brand_600: hex).css_variables }

      expect(Branding::Palette.swatches.size).to eq(24)
      expect(stylesheets).to all(have_legible_roles("brand"))
    end

    it "catches a label that does not read on the neutrals" do
      css = build(:branding, brand_600: "#EAB308").css_variables.sub(/--brand-ink-light:#\h{6};/, "--brand-ink-light:#EAB308;")

      expect(css).not_to have_legible_roles("brand")
    end

    it "labels a light yellow brand on a darker step of its ramp, because the chosen color fails on the neutrals" do
      branding = build(:branding, brand_600: "#EAB308")

      css = branding.css_variables

      expect(css[/--brand-ink-light:(#\h{6});/, 1]).not_to eq("#EAB308")
      expect(css[/--brand-ink-light:(#\h{6});/, 1]).to eq(branding.color_scale.tokens.fetch(900))
    end

    it "keeps the chosen color as the label when it already reads on every neutral" do
      css = build(:branding, brand_600: "#2C6CB0").css_variables

      expect(css[/--brand-ink-light:(#\h{6});/, 1]).to eq("#2C6CB0")
    end

    it "takes the light pair from the end of the ramp that belongs to each theme" do
      branding = build(:branding, brand_600: "#2C6CB0")

      css = branding.css_variables

      expect(css[/--brand-soft-light:(#\h{6});/, 1]).to eq(branding.color_scale.tokens.fetch(50))
      expect(css[/--brand-soft-dark:(#\h{6});/, 1]).to eq(branding.color_scale.tokens.fetch(900))
    end

    it "derives the same ramp through the class method that the instance uses" do
      scale = Branding::ColorScale.new("#4F46E5")

      expect(Branding.ramp_variables("brand", scale)).to include("--brand-600:#4F46E5;")
      expect(Branding.ramp_variables("brand", scale)).to include("--brand-ink-light:")
    end

    it "carries every theme token of the establishment" do
      branding = build(:branding, :with_background)

      expect(branding.css_variables).to include(branding.theme.css_variables)
      expect(branding.css_variables).to include("--brand-600:#F0617A;")
    end

    it "derives nothing from a stored support color" do
      branding = build(:branding, brand_600: "#2C6CB0", brand_secondary_600: "#E8493C")

      expect(branding.css_variables).not_to include("--secondary-")
      expect(branding.css_variables.downcase).not_to include("e8493c")
      expect(branding.css_variables).to include("--brand-mark-light:")
    end
  end

  describe "#light_ink" do
    it "keeps a brand dark enough to read on the light surfaces" do
      branding = build(:branding, brand_600: "#B5123E")

      expect(branding.light_ink).to eq("#B5123E")
    end

    it "darkens a light brand until it reads on the light surfaces" do
      branding = build(:branding, brand_600: "#F2C94C")

      ink = branding.light_ink

      expect(ink).not_to eq("#F2C94C")
      expect(Branding::ColorScale.new(ink).contrast_against(Branding::ColorScale.new("#ffffff"))).to be >= Branding::ColorScale::MIN_CONTRAST
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

    it "changes when only the background changes" do
      navy = build(:branding, brand_600: "#F0617A", brand_background: "#16324A")
      green = build(:branding, brand_600: "#F0617A", brand_background: "#1F4D3A")

      expect(navy.stylesheet_digest).not_to eq(green.stylesheet_digest)
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

  describe "#social_image_variant" do
    it "is nil when no logo is attached" do
      branding = create(:branding)

      expect(branding.social_image_variant).to be_nil
    end

    it "fills a 512 square png from the logo for the link preview" do
      branding = create(:branding, :with_logo)

      expect(branding.social_image_variant.variation.transformations[:resize_to_fill]).to eq([ Branding::SOCIAL_IMAGE_SIZE, Branding::SOCIAL_IMAGE_SIZE ])
    end
  end

  describe "#header_logo" do
    it "is nil when no logo is attached" do
      branding = create(:branding)

      expect(branding.header_logo).to be_nil
    end

    it "fills a 128 square png from the logo for the emblem" do
      branding = create(:branding, :with_logo)

      expect(branding.header_logo.variation.transformations[:resize_to_fill]).to eq([ Branding::EMBLEM_LOGO_SIZE, Branding::EMBLEM_LOGO_SIZE ])
    end

    it "is nil when a rejected upload left an attachment whose blob was never persisted" do
      branding = build(:branding, :with_logo)

      expect(branding.header_logo).to be_nil
    end
  end

  describe "#invite_icon" do
    it "is nil when no logo is attached" do
      branding = create(:branding)

      expect(branding.invite_icon).to be_nil
    end

    it "fills a 192 square png, reusing the manifest's 192 'any' icon instead of cutting a second crop" do
      branding = create(:branding, :with_logo)
      manifest_icon = branding.icon_variants.find { |icon| icon[:sizes] == "192x192" && icon[:purpose] == "any" }[:variant]

      expect(branding.invite_icon.variation.transformations[:resize_to_fill]).to eq([ Branding::INVITE_ICON_SIZE, Branding::INVITE_ICON_SIZE ])
      expect(branding.invite_icon.variation.key).to eq(manifest_icon.variation.key)
    end

    it "is nil when a rejected upload left an attachment whose blob was never persisted" do
      branding = build(:branding, :with_logo)

      expect(branding.invite_icon).to be_nil
    end
  end
end
