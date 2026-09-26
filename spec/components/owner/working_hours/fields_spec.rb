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

  it "summarizes the lunch break in a target the client fills" do
    document = Nokogiri::HTML5.fragment(body)

    expect(document.at_css(%([data-onboarding-target="breakSummary"]))).not_to be_nil
    expect(document.at_css("#working_hours_break_starts_at")["data-action"]).to include("onboarding#summarizeBreak")
    expect(document.at_css("#working_hours_opens_at")["data-action"]).to be_nil
  end

  it "keeps the lunch toggle inside the schedule card" do
    document = Nokogiri::HTML5.fragment(body)
    card = document.at_css("[data-schedule-card]")

    expect(card.at_css("#working_hours_opens_at")).not_to be_nil
    expect(card.at_css(%([data-onboarding-target="breakToggle"]))).not_to be_nil
  end

  it "gives the schedule fields a stable id" do
    html = body

    expect(html).to include(%(id="working_hours_opens_at"))
    expect(html).to include(%(id="working_hours_closes_at"))
    expect(html).to include(%(id="working_hours_break_starts_at"))
    expect(html).to include(%(id="working_hours_break_ends_at"))
  end
  it "marks the answered days and fills the range and lunch values on refill" do
    schedule = Onboarding::Schedule.new(weekdays: [ 2, 3 ], opens_at: "09:00", closes_at: "18:00", break_starts_at: "12:00", break_ends_at: "14:00")

    document = Nokogiri::HTML5.fragment(described_class.new(schedule: schedule).call)

    checked = document.css(%(input[name="working_hours[weekdays][]"][checked])).map { |node| node["value"] }
    expect(checked).to contain_exactly("2", "3")
    expect(document.at_css("#working_hours_opens_at")["value"]).to eq("09:00")
    expect(document.at_css("#working_hours_closes_at")["value"]).to eq("18:00")
    expect(document.at_css("#working_hours_break_starts_at")["value"]).to eq("12:00")
  end

  it "renders the closing-time error next to the range on refill" do
    schedule = Onboarding::Schedule.new(weekdays: [ 2 ], opens_at: "09:00", closes_at: "")
    schedule.errors.add(:closes_at, "não pode ficar em branco")

    html = described_class.new(schedule: schedule).call

    expect(html).to include("não pode ficar em branco")
  end

  it "renders the lunch error next to the break fields on refill" do
    schedule = Onboarding::Schedule.new(weekdays: [ 2 ], opens_at: "09:00", closes_at: "18:00", break_starts_at: "14:00", break_ends_at: "12:00")
    schedule.errors.add(:break_ends_at, Onboarding::Schedule::BREAK_INVERTED_MESSAGE)

    document = Nokogiri::HTML5.fragment(described_class.new(schedule: schedule).call)

    expect(document.at_css("[data-onboarding-target='break']").parent.text).to include(Onboarding::Schedule::BREAK_INVERTED_MESSAGE)
  end

  it "renders no day marked and no values without a schedule" do
    document = Nokogiri::HTML5.fragment(described_class.new.call)

    expect(document.css(%(input[name="working_hours[weekdays][]"][checked]))).to be_empty
    expect(document.at_css("#working_hours_opens_at")["value"]).to be_nil
  end
end
