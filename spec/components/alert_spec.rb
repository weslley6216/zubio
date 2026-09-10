require "rails_helper"

RSpec.describe Components::Alert, type: :component do
  it "paints a confirmation on the success tone" do
    html = described_class.new(text: "Marca atualizada.", tone: :success).call

    expect(html).to include("bg-success-surface")
    expect(html).to include("border-success-line")
    expect(html).not_to include("bg-danger-surface")
  end

  it "paints a refusal on the danger tone" do
    html = described_class.new(text: "E-mail ou senha inválidos.", tone: :danger).call

    expect(html).to include("bg-danger-surface")
    expect(html).to include("border-danger-line")
    expect(html).not_to include("bg-success-surface")
  end

  it "refuses a tone with no palette behind it" do
    expect { described_class.new(text: "Salvo", tone: :warning).call }.to raise_error(KeyError)
  end
end
