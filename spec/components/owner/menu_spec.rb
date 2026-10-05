require "rails_helper"

RSpec.describe Components::Owner::Menu, type: :component do
  it "renders every item with a leading icon and divides them with a hairline" do
    html = render_phlex(described_class.new(items: [ [ "Configurações", "/owner/settings", false ] ]))

    expect(html).to include(%(circle cx="12" cy="12" r="3"))
    expect(html).to include("divide-y", "divide-line")
  end

  it "lights the current item in the light brand pair and points it with a chevron" do
    html = render_phlex(described_class.new(items: [ [ "Configurações", "/owner/settings", true ] ]))

    expect(html).to include(%(<a href="/owner/settings" aria-current="page" class="#{described_class::ITEM_CLASS} #{described_class::CURRENT_CLASS}">))
    expect(html).to include(described_class::CHEVRON_PATH)
  end

  it "leaves a resting item without the current treatment or a chevron" do
    html = render_phlex(described_class.new(items: [ [ "Configurações", "/owner/settings", false ] ]))

    expect(html).to include(described_class::RESTING_CLASS)
    expect(html).not_to include(%(aria-current="page"))
    expect(html).not_to include(described_class::CHEVRON_PATH)
  end

  it "wears the brand outline and the light fill when the menu is open" do
    html = render_phlex(described_class.new(items: [ [ "Configurações", "/owner/settings", false ] ]))

    expect(html).to include("group-open:bg-brand-soft")
    expect(html).to include("group-open:border-brand-600")
  end

  it "closes the list with sign out as an item below the theme switch, keeping the delete" do
    html = render_phlex(described_class.new(items: [ [ "Configurações", "/owner/settings", false ] ]))

    sign_out_button = Nokogiri::HTML5.fragment(html).at_css("form button")
    expect(html.index(Components::Owner::Header::SIGN_OUT_LABEL)).to be > html.index(Components::ThemeToggle::LABEL)
    expect(Nokogiri::HTML5.fragment(html).at_css("form input[name='_method']")["value"]).to eq("delete")
    expect(sign_out_button.text).to eq(Components::Owner::Header::SIGN_OUT_LABEL)
    expect(sign_out_button["class"]).to include(described_class::ITEM_CLASS)
    expect(sign_out_button["class"]).not_to include("border-line")
  end
end
