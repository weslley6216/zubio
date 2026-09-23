require "rails_helper"

RSpec.describe Components::Owner::WorkingHours::Fields, type: :component do
  def body = described_class.new.call

  it "draws the seven weekday chips plus an all-days chip" do
    html = body

    WorkingHour::WEEKDAY_NAMES.each { |name| expect(html).to include(name.first(3)) }
    expect(html).to include(%(data-action="onboarding#selectAllDays"))
  end

  it "counts the selected days in a target the client updates" do
    expect(body).to include(%(data-onboarding-target="dayCount"))
  end

  it "starts the lunch break collapsed behind a toggle" do
    document = Nokogiri::HTML5.fragment(body)

    expect(document.at_css(%([data-onboarding-target="breakToggle"]))).not_to be_nil
    expect(document.at_css(%([data-onboarding-target="break"]))["class"]).to include("hidden")
  end
end
