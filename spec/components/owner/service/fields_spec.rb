require "rails_helper"

RSpec.describe Components::Owner::Service::Fields, type: :component do
  def service = ActsAsTenant.with_tenant(Tenant.new) { Service.new }

  it "drops the description and the long hints in the onboarding variant" do
    html = described_class.new(service: service, onboarding: true).call

    expect(html).to include(described_class::NAME_LABEL)
    expect(html).not_to include(described_class::DESCRIPTION_LABEL)
    expect(html).not_to include("sob consulta")
  end

  it "brings name, duration and price in the catalog variant" do
    html = described_class.new(service: service).call

    expect(html).to include(described_class::NAME_LABEL)
    expect(html).to include(described_class::DESCRIPTION_LABEL)
    expect(html).to include("sob consulta")
  end

  it "drops the name attribute and marks draft targets in the onboarding variant, so the client reads it instead of the form submitting it" do
    html = described_class.new(service: service, onboarding: true).call

    expect(html).not_to include(%(name="service[name]"))
    expect(html).to include(%(data-onboarding-target="serviceName"))
    expect(html).to include(%(data-onboarding-target="serviceDuration"))
    expect(html).to include(%(data-onboarding-target="servicePrice"))
  end

  it "keeps the name attribute in the catalog variant" do
    expect(described_class.new(service: service).call).to include(%(name="service[name]"))
  end

  it "lays duration and price side by side in the onboarding variant, like the canvas card" do
    document = Nokogiri::HTML5.fragment(described_class.new(service: service, onboarding: true).call)

    row = document.at_css(%([data-onboarding-target="serviceDuration"])).ancestors("[data-fields-row]").first
    expect(row).not_to be_nil
    expect(row.at_css(%([data-onboarding-target="servicePrice"]))).not_to be_nil
  end

  it "stacks duration and price in the catalog variant" do
    document = Nokogiri::HTML5.fragment(described_class.new(service: service).call)

    expect(document.at_css("[data-fields-row]")).to be_nil
  end
end
