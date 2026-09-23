require "rails_helper"

RSpec.describe Components::Owner::ShareLink, type: :component do
  def body = described_class.new(host: "barbearia-do-ze.zubio.com.br").call

  it "shows the address and links to WhatsApp with the address encoded" do
    html = body

    expect(html).to include("barbearia-do-ze.zubio.com.br")
    expect(html).to include("wa.me")
  end

  it "puts WhatsApp before the copy action, WhatsApp filled and copy outlined" do
    document = Nokogiri::HTML5.fragment(body)
    actions = document.css("[data-share-actions] > *")

    expect(actions.first["class"]).to include("bg-brand-600")
    expect(actions.last["class"]).to include("border")
    expect(actions.last["class"]).not_to include("bg-brand-600")
  end
end
