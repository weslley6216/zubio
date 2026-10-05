require "rails_helper"

RSpec.describe Components::Toggle, type: :component do
  def document(**options) = Nokogiri::HTML5.fragment(described_class.new(**options).call)

  it "draws a 46px pill with a sliding thumb off the brand track" do
    html = described_class.new.call

    expect(html).to include("w-[46px]")
    expect(html).to include("has-checked:bg-brand-600")
    expect(html).to include("peer-checked:translate-x-5")
  end

  it "forwards name, value, checked and id to a screen-reader-only checkbox" do
    checkbox = document(name: "schedule_exception[attends]", value: "1", checked: true,
      id: "schedule_exception_attends").at_css("input")

    expect(checkbox["type"]).to eq("checkbox")
    expect(checkbox["class"]).to include("peer", "sr-only")
    expect(checkbox["name"]).to eq("schedule_exception[attends]")
    expect(checkbox["value"]).to eq("1")
    expect(checkbox["checked"]).to be_truthy
    expect(checkbox["id"]).to eq("schedule_exception_attends")
  end

  it "leaves an unchecked toggle without the checked attribute" do
    expect(document(checked: false).at_css("input")["checked"]).to be_falsey
  end

  it "forwards data attributes so a consumer can wire its own behavior" do
    checkbox = document(data: { action: "change->onboarding#toggleBreak", onboarding_target: "breakToggle" }).at_css("input")

    expect(checkbox["data-action"]).to eq("change->onboarding#toggleBreak")
    expect(checkbox["data-onboarding-target"]).to eq("breakToggle")
  end
end
