require "rails_helper"

RSpec.describe WorkingHour::Summary do
  def hour(weekday, opens = "09:00", closes = "18:00")
    ActsAsTenant.with_tenant(Tenant.new) { WorkingHour.new(weekday: weekday, opens_at: opens, closes_at: closes) }
  end

  describe "#weekdays_label" do
    it "bands a contiguous run as first to last" do
      summary = described_class.new([ hour(2), hour(3), hour(4), hour(5), hour(6) ])

      expect(summary.weekdays_label).to eq("Ter a Sáb")
    end

    it "bands the whole week from Sunday to Saturday" do
      summary = described_class.new((0..6).map { |weekday| hour(weekday) })

      expect(summary.weekdays_label).to eq("Dom a Sáb")
    end

    it "names a single day on its own" do
      expect(described_class.new([ hour(1) ]).weekdays_label).to eq("Seg")
    end

    it "enumerates the days when there is a gap" do
      summary = described_class.new([ hour(2), hour(4), hour(6) ])

      expect(summary.weekdays_label).to eq("Ter, Qui, Sáb")
    end
  end

  describe "#hours_label" do
    it "bands the opening and closing time with an en dash and no spaces" do
      expect(described_class.new([ hour(2) ]).hours_label).to eq("09:00–18:00")
    end

    it "spans the whole day across a lunch break split into two segments" do
      summary = described_class.new([ hour(2, "09:00", "12:00"), hour(2, "14:00", "18:00") ])

      expect(summary.hours_label).to eq("09:00–18:00")
    end
  end
end
