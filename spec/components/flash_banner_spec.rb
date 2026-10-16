require "rails_helper"

RSpec.describe Components::FlashBanner, type: :component do
  it "renders each present flash message inside the given container" do
    html = render_phlex(described_class.new(container_class: "my-wrap"), flash: { alert: "Deu ruim", notice: "Tudo certo" })

    container = Nokogiri::HTML5.fragment(html).at_css(".my-wrap")
    expect(container["role"]).to eq("status")
    expect(container.css("[data-alert]").map(&:text)).to eq([ "Tudo certo", "Deu ruim" ])
  end

  it "renders nothing when there is no flash" do
    html = render_phlex(described_class.new(container_class: "my-wrap"))

    expect(html.strip).to be_empty
  end
end
