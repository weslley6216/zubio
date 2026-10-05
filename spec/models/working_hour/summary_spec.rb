require "rails_helper"

RSpec.describe WorkingHour::Summary do
  describe "#weekdays_label" do
    it "bands a contiguous run as first to last" do
      summary = described_class.new((2..6).map { |weekday| build(:working_hour, weekday: weekday) })

      expect(summary.weekdays_label).to eq("Ter a Sáb")
    end

    it "bands the whole week from Sunday to Saturday" do
      summary = described_class.new((0..6).map { |weekday| build(:working_hour, weekday: weekday) })

      expect(summary.weekdays_label).to eq("Dom a Sáb")
    end

    it "names a single day on its own" do
      summary = described_class.new([ build(:working_hour, weekday: 1) ])

      expect(summary.weekdays_label).to eq("Seg")
    end

    it "enumerates the days when there is a gap" do
      summary = described_class.new([ build(:working_hour, weekday: 2), build(:working_hour, weekday: 4), build(:working_hour, weekday: 6) ])

      expect(summary.weekdays_label).to eq("Ter, Qui, Sáb")
    end
  end

  describe "#hours_label" do
    it "bands the opening and closing time with an en dash and no spaces" do
      summary = described_class.new([ build(:working_hour, weekday: 2, opens_at: "09:00", closes_at: "18:00") ])

      expect(summary.hours_label).to eq("09:00–18:00")
    end

    it "spans the whole day across a lunch break split into two segments" do
      summary = described_class.new([ build(:working_hour, weekday: 2, opens_at: "09:00", closes_at: "12:00"), build(:working_hour, weekday: 2, opens_at: "14:00", closes_at: "18:00") ])

      expect(summary.hours_label).to eq("09:00–18:00")
    end
  end

  describe "#line" do
    it "bands weekdays and hours when every attended day shares the same envelope" do
      summary = described_class.new((2..6).map { |weekday| build(:working_hour, weekday: weekday) })

      expect(summary.line).to eq("Ter a Sáb, 09:00–18:00")
    end

    it "keeps the shared envelope when a day is split by a lunch break" do
      summary = described_class.new([ build(:working_hour, weekday: 2, opens_at: "09:00", closes_at: "12:00"), build(:working_hour, weekday: 2, opens_at: "14:00", closes_at: "18:00"), build(:working_hour, weekday: 3, opens_at: "09:00", closes_at: "18:00") ])

      expect(summary.line).to eq("Ter a Qua, 09:00–18:00")
    end

    it "falls back to a count when the days keep different hours" do
      summary = described_class.new([ build(:working_hour, weekday: 2, opens_at: "09:00", closes_at: "18:00"), build(:working_hour, weekday: 4, opens_at: "10:00", closes_at: "16:00"), build(:working_hour, weekday: 6, opens_at: "08:00", closes_at: "12:00") ])

      expect(summary.line).to eq("3 dias de atendimento")
    end

    it "names a lone day with its own hours" do
      summary = described_class.new([ build(:working_hour, weekday: 2, opens_at: "09:00", closes_at: "12:00") ])

      expect(summary.line).to eq("Ter, 09:00–12:00")
    end

    it "says nothing is defined for an empty week" do
      summary = described_class.new([])

      expect(summary.line).to eq(WorkingHour::Summary::NO_HOURS)
    end
  end
end
