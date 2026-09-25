require "rails_helper"

RSpec.describe Components::Owner::BrandQuestion::Logo, type: :component do
  let(:tenant) { build(:tenant, name: "Barbearia do Zé") }

  def body(branding)
    described_class.new(tenant: tenant, branding: branding).call
  end

  it "asks only about the logo, with its own title and subtitle" do
    html = body(build(:branding, tenant: tenant))

    expect(html).to include(described_class::TITLE)
    expect(html).to include(described_class::SUBTITLE)
  end

  it "shows the initial and both the gallery and the camera action when there is no logo" do
    html = body(build(:branding, tenant: tenant))

    expect(html).to include(">B</span>")
    expect(html).to include("bg-brand-accent")
    expect(html).to include(described_class::GALLERY_LABEL)
    expect(html).to include(described_class::CAMERA_LABEL)
    expect(html).to include(%(capture="environment"))
  end

  it "points both inputs at the same field, restricted to the accepted types" do
    html = body(build(:branding, tenant: tenant))

    expect(html.scan(%(name="branding[logo]")).size).to eq(2)
    expect(html).to include(%(accept="#{Branding::LOGO_CONTENT_TYPES.join(',')}"))
  end

  it "reads the size limit from the constant, not a hardcoded number" do
    expect(body(build(:branding, tenant: tenant))).to include("#{Branding::LOGO_MAX_BYTES / 1.megabyte} MB")
  end

  it "offers no removal option when there is no logo" do
    expect(body(build(:branding, tenant: tenant))).not_to include(%(name="branding[remove_logo]"))
  end

  it "offers the removal option when a logo is attached" do
    branding = create(:branding, :with_logo, tenant: tenant)
    allow(branding).to receive(:header_logo).and_return(nil)

    expect(body(branding)).to include(%(name="branding[remove_logo]"))
  end

  it "wires direct upload and a signed-id field when asked to" do
    rendered = described_class.new(tenant: tenant, branding: build(:branding, tenant: tenant),
      direct_upload_url: "/rails/active_storage/direct_uploads").call

    expect(rendered).to include(%(data-logo-url-value="/rails/active_storage/direct_uploads"))
    expect(rendered).to include(%(data-logo-target="signedId"))
  end

  it "keeps the plain multipart field outside onboarding" do
    rendered = body(build(:branding, tenant: tenant))

    expect(rendered).to include(%(name="branding[logo]"))
    expect(rendered).not_to include("logo-url-value")
  end

  it "carries the size and type limits for client-side validation as data attributes" do
    rendered = Nokogiri::HTML5.fragment(
      described_class.new(tenant: tenant, branding: build(:branding, tenant: tenant),
        direct_upload_url: "/rails/active_storage/direct_uploads", onboarding: true).call
    )
    root = rendered.at_css("[data-controller='logo']")

    expect(root["data-logo-max-bytes-value"]).to eq(Branding::LOGO_MAX_BYTES.to_s)
    expect(root["data-logo-content-types-value"]).to eq(Branding::LOGO_CONTENT_TYPES.to_json)
  end

  it "states the format and size rule in the onboarding variant too" do
    html = described_class.new(tenant: tenant, branding: build(:branding, tenant: tenant), onboarding: true).call

    expect(html).to include("#{Branding::LOGO_MAX_BYTES / 1.megabyte} MB")
  end

  it "offers gallery and camera and explains the initial, without a removal box, in the onboarding variant" do
    html = described_class.new(tenant: tenant, branding: build(:branding, tenant: tenant), onboarding: true).call

    expect(html).to include(described_class::GALLERY_LABEL)
    expect(html).to include(described_class::CAMERA_LABEL)
    expect(html).to include(described_class::NO_LOGO_LABEL)
    expect(html).not_to include(%(name="branding[remove_logo]"))
  end

  it "keeps the removal box outside the onboarding variant when a logo is attached" do
    branding = create(:branding, :with_logo, tenant: tenant)
    allow(branding).to receive(:header_logo).and_return(nil)

    html = described_class.new(tenant: tenant, branding: branding, onboarding: true).call

    expect(html).not_to include(%(name="branding[remove_logo]"))
  end
end
