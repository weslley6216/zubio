require "rails_helper"

RSpec.describe Components::SocialMeta, type: :component do
  it "announces the title, description, type, address and image for Open Graph, plus the Twitter summary card" do
    fragment = Nokogiri::HTML5.fragment(
      described_class.new(
        title: "Estúdio Aurora",
        description: "Agende seu horário online — Estúdio Aurora.",
        url: "https://estudio-aurora.zubio.com.br/",
        image_url: "https://estudio-aurora.zubio.com.br/rails/active_storage/logo.png"
      ).call
    )

    expect(fragment.at_css('meta[property="og:title"]')["content"]).to eq("Estúdio Aurora")
    expect(fragment.at_css('meta[property="og:description"]')["content"]).to eq("Agende seu horário online — Estúdio Aurora.")
    expect(fragment.at_css('meta[property="og:type"]')["content"]).to eq("website")
    expect(fragment.at_css('meta[property="og:url"]')["content"]).to eq("https://estudio-aurora.zubio.com.br/")
    expect(fragment.at_css('meta[property="og:image"]')["content"]).to eq("https://estudio-aurora.zubio.com.br/rails/active_storage/logo.png")
    expect(fragment.at_css('meta[name="twitter:card"]')["content"]).to eq("summary")
  end

  it "omits the image when none is given but still announces the rest" do
    fragment = Nokogiri::HTML5.fragment(
      described_class.new(
        title: "Estúdio Aurora",
        description: "Agende seu horário online — Estúdio Aurora.",
        url: "https://estudio-aurora.zubio.com.br/"
      ).call
    )

    expect(fragment.at_css('meta[property="og:image"]')).to be_nil
    expect(fragment.at_css('meta[property="og:title"]')).not_to be_nil
  end

  it "escapes a name with characters that would break the meta attribute" do
    fragment = Nokogiri::HTML5.fragment(
      described_class.new(
        title: %(Aurora "Glow" & Co),
        description: "x",
        url: "https://x/"
      ).call
    )

    expect(fragment.at_css('meta[property="og:title"]')["content"]).to eq(%(Aurora "Glow" & Co))
  end
end
