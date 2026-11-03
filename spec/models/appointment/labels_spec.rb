require "rails_helper"

RSpec.describe Appointment::Labels do
  describe ".day_label" do
    it "names a day by its abbreviated weekday, day and month" do
      expect(described_class.day_label(Date.new(2026, 11, 10))).to eq("Ter, 10 nov")
    end
  end

  describe "#when_label" do
    it "tells when the appointment happens" do
      appointment = create(:appointment, starts_at: Time.zone.local(2026, 11, 10, 9, 45))

      expect(described_class.new(appointment).when_label).to eq("Ter, 10 nov · 09:45")
    end
  end

  describe "#duration_label" do
    it "tells how long it lasts and when it ends" do
      appointment = create(:appointment, starts_at: Time.zone.local(2026, 11, 10, 9, 45))

      expect(described_class.new(appointment).duration_label).to eq("45 min · termina 10:30")
    end
  end

  describe "#price_label" do
    it "shows the public price" do
      tenant = create(:tenant)
      service = create(:service, tenant: tenant, price_cents: 6_000)
      appointment = create(:appointment, tenant: tenant, service: service)

      expect(described_class.new(appointment).price_label).to eq("R$ 60,00")
    end

    it "hides a price the establishment keeps private" do
      tenant = create(:tenant)
      service = create(:service, :price_hidden, tenant: tenant, price_cents: 6_000)
      appointment = create(:appointment, tenant: tenant, service: service)

      expect(described_class.new(appointment).price_label).to eq("Sob consulta")
    end
  end
end
