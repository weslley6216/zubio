require "rails_helper"

RSpec.describe Components::Owner::ShareLink, type: :component do
  it "shows the bare host but copies the full address" do
    document = Nokogiri::HTML5.fragment(described_class.new(host: "barbearia-do-ze.zubio.com.br", name: "Barbearia do Zé").call)

    expect(document.at_css("[data-share-address]").text).to eq("barbearia-do-ze.zubio.com.br")
    expect(document.at_css("[data-controller='clipboard']")["data-clipboard-text-value"]).to eq("https://barbearia-do-ze.zubio.com.br")
  end

  it "puts WhatsApp before the copy action, WhatsApp filled and copy outlined" do
    document = Nokogiri::HTML5.fragment(described_class.new(host: "barbearia-do-ze.zubio.com.br", name: "Barbearia do Zé").call)

    actions = document.css("[data-share-actions] > *")
    expect(actions.first["class"]).to include("bg-brand-600")
    expect(actions.last["class"]).to include("border")
    expect(actions.last["class"]).not_to include("bg-brand-600")
  end

  it "writes an enriched WhatsApp message with the establishment name and address" do
    document = Nokogiri::HTML5.fragment(described_class.new(host: "barbearia-do-ze.zubio.com.br", name: "Barbearia do Zé").call)

    message = CGI.unescape(document.at_css("a[href*='wa.me']")["href"].split("text=").last)
    expect(message).to include("Oi! Agende seu horário na Barbearia do Zé")
    expect(message).to include("https://barbearia-do-ze.zubio.com.br")
  end

  it "carries the copied-confirmation label and a copy-label target" do
    document = Nokogiri::HTML5.fragment(described_class.new(host: "barbearia-do-ze.zubio.com.br", name: "Barbearia do Zé").call)

    copy_button = document.css("[data-share-actions] > *").last
    expect(document.at_css("[data-controller='clipboard']")["data-clipboard-copied-value"]).to eq("Copiado!")
    expect(copy_button.at_css("[data-clipboard-target='label']").text).to eq("Copiar")
    expect(copy_button.at_css("svg")).not_to be_nil
  end

  it "renders the uppercase label and the helper when given" do
    document = Nokogiri::HTML5.fragment(
      described_class.new(
        host: "barbearia-do-ze.zubio.com.br",
        name: "Barbearia do Zé",
        label: "Seu link",
        helper: "Mande esse endereço para suas clientes."
      ).call
    )

    expect(document.text).to include("Seu link")
    expect(document.text).to include("Mande esse endereço para suas clientes.")
  end

  it "omits the label and helper when not given" do
    document = Nokogiri::HTML5.fragment(described_class.new(host: "barbearia-do-ze.zubio.com.br", name: "Barbearia do Zé").call)

    expect(document.text).to include("barbearia-do-ze.zubio.com.br")
    expect(document.text).not_to include("Seu link")
    expect(document.text).not_to include("Mande esse endereço")
  end

  it "dresses the card in theme tokens" do
    document = Nokogiri::HTML5.fragment(described_class.new(host: "barbearia-do-ze.zubio.com.br", name: "Barbearia do Zé").call)

    expect(document.at_css("[data-controller='clipboard']")["class"]).to include("bg-surface", "border-line")
    expect(document.at_css("[data-share-address]")["class"]).to include("bg-surface-2", "text-ink")
  end
end
