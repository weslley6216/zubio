require "rails_helper"

RSpec.describe ClientMailer, type: :mailer do
  describe "#booking_receipt" do
    let(:tenant) { create(:tenant, name: "Barbearia 2K", subdomain: "barbearia-2k") }
    let(:branding) { create(:branding, :with_logo, tenant: tenant, brand_600: "#B5123E") }
    let(:appointment) do
      branding
      professional = create(:professional, tenant: tenant, display_name: "Mary Sombracelhas")
      service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45, price_cents: 6_000)
      client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro", phone: "11988771234", email: "ana@gmail.com")
      create(:appointment, tenant: tenant, professional: professional, service: service, client: client,
        starts_at: Time.zone.local(2026, 11, 10, 9, 45))
    end

    it "is addressed to the client's account email" do
      mail = described_class.booking_receipt(tenant.id, appointment.id)

      expect(mail.to).to eq([ "ana@gmail.com" ])
    end

    it "comes from the establishment by name at the Zubio address" do
      mail = described_class.booking_receipt(tenant.id, appointment.id)

      expect(mail[:from].display_names).to eq([ "Barbearia 2K" ])
      expect(mail.from).to eq([ "no-reply@zubio.com.br" ])
    end

    it "names the establishment in the subject" do
      mail = described_class.booking_receipt(tenant.id, appointment.id)

      expect(mail.subject).to eq("Seu horário na Barbearia 2K")
    end

    it "is delivered as HTML with a plain-text alternative" do
      mail = described_class.booking_receipt(tenant.id, appointment.id)

      expect(mail.mime_type).to eq("multipart/alternative")
      expect(mail.parts.map(&:mime_type)).to eq([ "text/plain", "text/html" ])
    end

    it "opens the HTML with the establishment's brand and logo" do
      mail = described_class.booking_receipt(tenant.id, appointment.id)

      expect(mail.html_part.decoded).to include("background:#B5123E")
      expect(mail.html_part.decoded).to include("Horário confirmado")
      expect(mail.html_part.decoded).to include("https://barbearia-2k.zubio.com.br/rails/active_storage/")
    end

    it "carries the same details and link in both parts" do
      mail = described_class.booking_receipt(tenant.id, appointment.id)
      values = [
        "Ter, 10 nov · 09:45", "Design de sobrancelhas", "45 min · termina 10:30", "R$ 60,00",
        "barbearia-2k.zubio.com.br/a/#{appointment.cancel_token}"
      ]

      values.each do |value|
        expect(mail.html_part.decoded).to include(value)
        expect(mail.text_part.decoded).to include(value)
      end
    end

    it "greets by first name in the plain-text part" do
      mail = described_class.booking_receipt(tenant.id, appointment.id)

      expect(mail.text_part.decoded).to include("Olá, Ana!")
      expect(mail.text_part.decoded).to include("Seu horário na Barbearia 2K está confirmado:")
    end

    it "shows the initial when the establishment has no logo" do
      bald_tenant = create(:tenant, name: "Titiko Crochê", subdomain: "titiko-croche")
      create(:branding, tenant: bald_tenant, brand_600: "#2F6B3A")
      professional = create(:professional, tenant: bald_tenant, display_name: "Dona Titiko")
      service = create(:service, tenant: bald_tenant, name: "Ponto de crochê")
      client = create(:client, tenant: bald_tenant, name: "Joana Reis", email: "joana@gmail.com")
      bald_appointment = create(:appointment, tenant: bald_tenant, professional: professional, service: service, client: client,
        starts_at: Time.zone.local(2026, 11, 10, 9, 45))

      mail = described_class.booking_receipt(bald_tenant.id, bald_appointment.id)

      expect(mail.html_part.decoded).not_to include("rails/active_storage")
      expect(mail.html_part.decoded).to include("data-brand-initial")
    end

    it "falls back to the platform brand when the establishment has none" do
      bare_tenant = create(:tenant, name: "Sem Marca", subdomain: "sem-marca")
      professional = create(:professional, tenant: bare_tenant, display_name: "Dona Marca")
      service = create(:service, tenant: bare_tenant, name: "Serviço simples")
      client = create(:client, tenant: bare_tenant, name: "Joana Reis", email: "joana@gmail.com")
      bare_appointment = create(:appointment, tenant: bare_tenant, professional: professional, service: service, client: client,
        starts_at: Time.zone.local(2026, 11, 10, 9, 45))

      mail = described_class.booking_receipt(bare_tenant.id, bare_appointment.id)

      expect(mail.html_part.decoded).to include("background:#4F46E5")
    end

    it "keeps another establishment's name, logo and color out" do
      barbearia_branding = branding
      appointment

      titiko = create(:tenant, name: "Titiko Crochê", subdomain: "titiko-croche")
      create(:branding, :with_logo, tenant: titiko, brand_600: "#2F6B3A")
      professional = create(:professional, tenant: titiko, display_name: "Dona Titiko")
      service = create(:service, tenant: titiko, name: "Ponto de crochê")
      client = create(:client, tenant: titiko, name: "Joana Reis", email: "joana@gmail.com")
      titiko_appointment = create(:appointment, tenant: titiko, professional: professional, service: service, client: client,
        starts_at: Time.zone.local(2026, 11, 10, 9, 45))

      mail = described_class.booking_receipt(titiko.id, titiko_appointment.id)
      body = "#{mail.html_part.decoded}#{mail.text_part.decoded}"

      expect(body).not_to include("Barbearia 2K")
      expect(body).not_to include("#B5123E")
      expect(body).not_to include(barbearia_branding.logo.blob.signed_id)
      expect(body).to include("Titiko Crochê")
      expect(body).to include("#2F6B3A")
      expect(body).to include("titiko-croche.zubio.com.br")
      expect(mail[:from].display_names).to eq([ "Titiko Crochê" ])
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
