require "rails_helper"

RSpec.describe Components::LongDate, type: :component do
  it "spells the weekday, day and month" do
    html = described_class.new(date: Date.new(2026, 9, 8)).call

    expect(html).to include("Terça, 8 de setembro")
  end
end
