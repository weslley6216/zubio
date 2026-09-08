require "rails_helper"

RSpec.describe Components::Signup::SubdomainStatus, type: :component do
  it "names the host when the address is free" do
    html = described_class.new(status: :available, host: "estudio-aurora.zubio.com.br").call

    expect(html).to include("estudio-aurora.zubio.com.br está disponível.")
    expect(html).to include("text-success")
  end

  it "refuses a failure it cannot name instead of calling it available" do
    html = described_class.new(status: :unknown, host: "estudio-aurora.zubio.com.br").call

    expect(html).to include("Este subdomínio não pode ser usado.")
    expect(html).to include("text-danger")
  end
end
