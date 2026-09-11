require "rails_helper"

RSpec.describe StylesheetProducer do
  def producers = [ Branding.platform_default, Landing::ShowcaseBrand, Branding::Palette ]

  it "gives every sheet the stylesheets controller serves a digest short enough to travel in a URL" do
    digests = producers.map(&:stylesheet_digest)

    expect(digests).to all(have_attributes(length: described_class::DIGEST_LENGTH))
  end

  it "derives the digest from the content, so two different sheets never answer the same version" do
    expect(Landing::ShowcaseBrand.stylesheet).not_to eq(Branding::Palette.stylesheet)
    expect(Landing::ShowcaseBrand.stylesheet_digest).not_to eq(Branding::Palette.stylesheet_digest)
  end
end
