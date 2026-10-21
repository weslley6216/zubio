require "rails_helper"

RSpec.describe ClientMailer, type: :mailer do
  describe "#booking_receipt" do
    let(:tenant) { create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora") }
    let(:appointment) do
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, name: "Design de sobrancelhas")
      client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro", phone: "11988771234", email: "ana@gmail.com")
      create(:appointment, tenant: tenant, professional: professional, service: service, client: client,
        starts_at: Time.zone.local(2026, 11, 10, 9, 45))
    end

    it "is addressed to the client's account email" do
      mail = described_class.booking_receipt(tenant.id, appointment.id)

      expect(mail.to).to eq([ "ana@gmail.com" ])
    end

    it "carries the day, the time and the service" do
      mail = described_class.booking_receipt(tenant.id, appointment.id)

      expect(mail.body.to_s).to include("10/11/2026")
      expect(mail.body.to_s).to include("09:45")
      expect(mail.body.to_s).to include("Design de sobrancelhas")
    end

    it "links the appointment by its token on the establishment's host" do
      mail = described_class.booking_receipt(tenant.id, appointment.id)

      expect(mail.body.to_s).to include("estudio-aurora.zubio.com.br/a/#{appointment.cancel_token}")
    end

    it "names the establishment in the subject" do
      mail = described_class.booking_receipt(tenant.id, appointment.id)

      expect(mail.subject).to eq("Seu horário na Estúdio Aurora")
    end

    it "is delivered as plain text" do
      mail = described_class.booking_receipt(tenant.id, appointment.id)

      expect(mail.mime_type).to eq("text/plain")
    end

    it "reopens the tenant from its argument when delivered later" do
      appointment
      ActsAsTenant.current_tenant = nil

      perform_enqueued_jobs { described_class.booking_receipt(tenant.id, appointment.id).deliver_later }

      expect(ActionMailer::Base.deliveries.last.to).to eq([ "ana@gmail.com" ])
    end

    it "cannot be built from an appointment id outside the given tenant" do
      ze = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")

      expect { described_class.booking_receipt(ze.id, appointment.id).message }
        .to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
