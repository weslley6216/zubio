require "rails_helper"

RSpec.describe Components::Owner::FormCard, type: :component do
  it "names the card after its heading and states what the form is for" do
    html = described_class.new(title: "Brand", subtitle: "How clients see your link.").call { |card| card.plain("fields") }

    expect(html).to include(%(<section aria-labelledby="#{described_class::HEADING_ID}"))
    expect(html).to include(%(<h1 id="#{described_class::HEADING_ID}" class="#{described_class::TITLE_CLASS}">Brand</h1>))
    expect(html).to include(%(<p class="#{described_class::SUBTITLE_CLASS}">How clients see your link.</p>))
  end

  it "puts what the caller renders inside the card, below the heading" do
    html = described_class.new(title: "Brand", subtitle: "How clients see your link.").call { |card| card.plain("fields") }

    expect(html.index("fields")).to be > html.index("How clients see your link.")
    expect(html).to end_with("fields</section></main>")
  end
end
