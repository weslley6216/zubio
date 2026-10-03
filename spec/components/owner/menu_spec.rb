require "rails_helper"

RSpec.describe Components::Owner::Menu, type: :component do
  let(:items) { [ [ "Configurações", "/owner/settings", false ] ] }

  def body(items)
    render_phlex(described_class.new(items: items))
  end

  GEAR_PATH = "circle cx=\"12\" cy=\"12\" r=\"3\"".freeze

  it "renders every item with a leading icon and divides them with a hairline" do
    html = body(items)

    expect(html).to include(GEAR_PATH)
    expect(html).to include("divide-y", "divide-line")
  end

  it "lights the current item in the light brand pair and points it with a chevron" do
    html = body([ [ "Configurações", "/owner/settings", true ] ])

    expect(html).to include(%(<a href="/owner/settings" aria-current="page" class="#{described_class::ITEM_CLASS} #{described_class::CURRENT_CLASS}">))
    expect(html).to include(described_class::CHEVRON_PATH)
  end

  it "leaves a resting item without the current treatment or a chevron" do
    html = body([ [ "Configurações", "/owner/settings", false ] ])

    expect(html).to include(described_class::RESTING_CLASS)
    expect(html).not_to include(%(aria-current="page"))
    expect(html).not_to include(described_class::CHEVRON_PATH)
  end

  it "wears the brand outline and the light fill when the menu is open" do
    html = body(items)

    expect(html).to include("group-open:bg-brand-soft")
    expect(html).to include("group-open:border-brand-600")
  end

  it "closes the list with sign out as an item below the theme switch, keeping the delete" do
    html = body(items)

    expect(html).to include(Components::ThemeToggle::LABEL)
    expect(html).to include(Components::Owner::Header::SIGN_OUT_LABEL)
    expect(html).to include(%(value="delete"))
    expect(html.index(Components::Owner::Header::SIGN_OUT_LABEL)).to be > html.index(Components::ThemeToggle::LABEL)

    sign_out_button = html[html.index("<form"), html.index(Components::Owner::Header::SIGN_OUT_LABEL) + Components::Owner::Header::SIGN_OUT_LABEL.length - html.index("<form")]
    expect(sign_out_button).to include(described_class::ITEM_CLASS)
    expect(sign_out_button).not_to include("border border-line")
  end
end
