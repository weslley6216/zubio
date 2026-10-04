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

  it "hides the field labels visually but keeps them as accessible names in the onboarding variant" do
    document = Nokogiri::HTML5.fragment(described_class.new(service: service, onboarding: true).call)
    name_label = document.at_css(%(label[for="service_name"]))

    expect(name_label["class"]).to include("sr-only")
    expect(name_label.text).to eq(described_class::NAME_LABEL)
  end

  it "shows the canvas placeholders on the onboarding fields" do
    document = Nokogiri::HTML5.fragment(described_class.new(service: service, onboarding: true).call)

    expect(document.at_css("#service_name")["placeholder"]).to eq(described_class::NAME_PLACEHOLDER)
    expect(document.at_css("#service_duration_minutes")["placeholder"]).to eq(described_class::DURATION_PLACEHOLDER)
    expect(document.at_css("#service_price")["placeholder"]).to eq(described_class::PRICE_PLACEHOLDER)
  end

  it "sizes the onboarding fields to 48px with a 10px radius" do
    document = Nokogiri::HTML5.fragment(described_class.new(service: service, onboarding: true).call)

    expect(document.at_css("#service_name")["class"]).to include("h-12")
    expect(document.at_css("#service_name")["class"]).to include("rounded-[10px]")
  end

  it "keeps visible labels and no placeholders in the catalog variant" do
    document = Nokogiri::HTML5.fragment(described_class.new(service: service).call)
    name_label = document.at_css(%(label[for="service_name"]))

    expect(name_label["class"]).not_to include("sr-only")
    expect(document.at_css("#service_name")["placeholder"]).to be_nil
  end

  it "brings the show-price toggle checked by default in the catalog variant" do
    html = described_class.new(service: service).call

    expect(html).to include(described_class::SHOW_PRICE_LABEL)
    expect(html).to include(%(name="service[show_price]"))
    expect(html).to include(%(type="checkbox" name="service[show_price]" value="1" checked))
  end

  it "leaves the toggle unchecked for a service whose price is hidden" do
    hidden = ActsAsTenant.with_tenant(Tenant.new) { Service.new(show_price: false) }

    html = described_class.new(service: hidden).call

    expect(html).not_to include(%(value="1" checked))
  end

  it "drops the show-price toggle in the onboarding variant" do
    html = described_class.new(service: service, onboarding: true).call

    expect(html).not_to include(described_class::SHOW_PRICE_LABEL)
    expect(html).not_to include(%(name="service[show_price]"))
  end
end
