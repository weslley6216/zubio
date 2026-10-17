require "rails_helper"

RSpec.describe "Owner appointments", type: :request do
  let(:tenant) { create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora") }
  let(:owner) { create(:user, :with_professional, tenant: tenant, name: "Ana Lima", email: "ana@example.com", password: "s3cr3t123") }
  let(:professional) { owner.professional }

  describe "GET /owner/appointments" do
    it "lists the day's appointments in time order with time, duration, client and service" do
      create(:branding, tenant: tenant)
      service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45)
      morning_client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro")
      afternoon_client = create(:client, tenant: tenant, name: "Juliana Prado")
      ActsAsTenant.with_tenant(tenant) do
        create(:appointment, tenant: tenant, professional: professional, service: service, client: afternoon_client, starts_at: Date.current.in_time_zone.change(hour: 14))
        create(:appointment, tenant: tenant, professional: professional, service: service, client: morning_client, starts_at: Date.current.in_time_zone.change(hour: 9, min: 45))
      end
      sign_in_owner(owner)

      get owner_appointments_path

      body = response.body
      expect(body.index("Ana Paula Ribeiro")).to be < body.index("Juliana Prado")
      expect(body).to include("09:45")
      expect(body).to include("45 min")
      expect(body).to include("Design de sobrancelhas")
    end

    it "shows the formatted phone and makes it clickable via tel:" do
      create(:branding, tenant: tenant)
      service = create(:service, tenant: tenant)
      client = create(:client, tenant: tenant, phone: "11988771234")
      ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: Date.current.in_time_zone.change(hour: 9)) }
      sign_in_owner(owner)

      get owner_appointments_path

      expect(response.body).to include("(11) 98877-1234")
      expect(response.body).to include(%(href="tel:+5511988771234"))
    end

    it "keeps the cancelled appointment struck through with a badge and the confirmed one without a cancelled mark" do
      create(:branding, tenant: tenant)
      service = create(:service, tenant: tenant)
      confirmed_client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro")
      cancelled_client = create(:client, tenant: tenant, name: "Bruna Salles")
      ActsAsTenant.with_tenant(tenant) do
        create(:appointment, tenant: tenant, professional: professional, service: service, client: confirmed_client, starts_at: Date.current.in_time_zone.change(hour: 9))
        create(:appointment, :cancelled, tenant: tenant, professional: professional, service: service, client: cancelled_client, starts_at: Date.current.in_time_zone.change(hour: 15, min: 30))
      end
      sign_in_owner(owner)

      get owner_appointments_path

      expect(response.body).to include("Confirmado")
      expect(response.body).to include("Desmarcado")
      expect(response.body).to include("line-through")
      confirmed_block = response.body[response.body.index("Ana Paula Ribeiro") - 200, 400]
      expect(confirmed_block).not_to include("Desmarcado")
    end

    it "switches to the chosen day's appointments and marks the matching pill" do
      create(:branding, tenant: tenant)
      service = create(:service, tenant: tenant)
      today_client = create(:client, tenant: tenant, name: "Ana Hoje")
      other_day_client = create(:client, tenant: tenant, name: "Bia Amanhã")
      other_day = Date.current + 1.day
      ActsAsTenant.with_tenant(tenant) do
        create(:appointment, tenant: tenant, professional: professional, service: service, client: today_client, starts_at: Date.current.in_time_zone.change(hour: 9))
        create(:appointment, tenant: tenant, professional: professional, service: service, client: other_day_client, starts_at: other_day.in_time_zone.change(hour: 9))
      end
      sign_in_owner(owner)

      get owner_appointments_path(day: other_day.iso8601)

      expect(response.body).to include("Bia Amanhã")
      expect(response.body).not_to include("Ana Hoje")
      pill = Nokogiri::HTML5(response.body).at_css(%(a[href$="day=#{other_day.iso8601}"]))
      expect(pill["aria-current"]).to eq("date")
    end

    it "shows the empty-day message and offers the public link, without a list" do
      create(:branding, tenant: tenant)
      sign_in_owner(owner)

      get owner_appointments_path

      expect(response.body).to include("Nenhum agendamento neste dia.")
      expect(response.body).to include("estudio-aurora.zubio.com.br")
    end

    it "does not show the empty-day message on a day with an appointment" do
      create(:branding, tenant: tenant)
      service = create(:service, tenant: tenant)
      client = create(:client, tenant: tenant)
      ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: Date.current.in_time_zone.change(hour: 9)) }
      sign_in_owner(owner)

      get owner_appointments_path

      expect(response.body).not_to include("Nenhum agendamento neste dia.")
    end

    it "sends an anonymous visitor to the login without any client name or phone in the response" do
      create(:branding, tenant: tenant)
      service = create(:service, tenant: tenant)
      client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro", phone: "11988771234")
      ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: Date.current.in_time_zone.change(hour: 9)) }
      host! "#{tenant.subdomain}.zubio.com.br"

      get owner_appointments_path
      expect(response).to redirect_to(new_owner_session_path)
      follow_redirect!

      expect(response.body).not_to include("Ana Paula Ribeiro")
      expect(response.body).not_to include(client.phone_display)
      expect(response.body).not_to include(client.phone)
    end

    it "shows the appointments of its own tenant and none of another's" do
      ze = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
      ze_professional = create(:professional, tenant: ze)
      ze_service = create(:service, tenant: ze)
      ze_client = create(:client, tenant: ze, name: "Carlos Zé")
      ActsAsTenant.with_tenant(ze) { create(:appointment, tenant: ze, professional: ze_professional, service: ze_service, client: ze_client, starts_at: Date.current.in_time_zone.change(hour: 9)) }
      create(:branding, tenant: tenant)
      aurora_service = create(:service, tenant: tenant)
      aurora_client = create(:client, tenant: tenant, name: "Ana Aurora")
      ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional, service: aurora_service, client: aurora_client, starts_at: Date.current.in_time_zone.change(hour: 9)) }
      sign_in_owner(owner)

      get owner_appointments_path

      expect(response.body).to include("Ana Aurora")
      expect(response.body).not_to include("Carlos Zé")
    end

    it "queries the database the same number of times for many appointments as for one" do
      create(:branding, tenant: tenant)
      service = create(:service, tenant: tenant)
      client = create(:client, tenant: tenant)
      ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: Date.current.in_time_zone.change(hour: 9)) }
      sign_in_owner(owner)

      single = count_queries { get owner_appointments_path }

      ActsAsTenant.with_tenant(tenant) do
        4.times { |index| create(:appointment, tenant: tenant, professional: professional, service: service, client: create(:client, tenant: tenant), starts_at: Date.current.in_time_zone.change(hour: 10 + index)) }
      end
      many = count_queries { get owner_appointments_path }

      expect(single).to be_positive
      expect(many).to eq(single)
    end
  end

  describe "GET /owner/appointments/:id" do
    it "shows the time range, badge, long date, client, phone, service, price and duration" do
      travel_to Time.zone.local(2026, 9, 8, 7, 0)
      create(:branding, tenant: tenant)
      service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45, price_cents: 6000)
      client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro", phone: "11988771234")
      appointment = ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: Time.zone.local(2026, 9, 8, 9, 45)) }
      sign_in_owner(owner)

      get owner_appointment_path(appointment)

      expect(response.body).to include("09:45")
      expect(response.body).to include("10:30")
      expect(response.body).to include("Confirmado")
      expect(response.body).to include("Terça, 8 de setembro")
      expect(response.body).to include("Ana Paula Ribeiro")
      expect(response.body).to include("(11) 98877-1234")
      expect(response.body).to include("Design de sobrancelhas")
      expect(response.body).to include("R$ 60,00")
      expect(response.body).to include("45 min")
    end

    it "shows the third visit after two earlier non-cancelled appointments" do
      travel_to Time.zone.local(2026, 9, 8, 7, 0)
      create(:branding, tenant: tenant)
      service = create(:service, tenant: tenant)
      client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro", phone: "11988771234")
      appointment = ActsAsTenant.with_tenant(tenant) do
        create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: Time.zone.local(2026, 8, 11, 9, 45))
        create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: Time.zone.local(2026, 8, 25, 9, 45))
        create(:appointment, :cancelled, tenant: tenant, professional: professional, service: service, client: client, starts_at: Time.zone.local(2026, 9, 1, 9, 45))
        create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: Time.zone.local(2026, 9, 8, 9, 45))
      end
      sign_in_owner(owner)

      get owner_appointment_path(appointment)

      expect(response.body).to include("3ª visita")
    end

    it "links the WhatsApp conversation to wa.me with the E.164 number" do
      travel_to Time.zone.local(2026, 9, 8, 7, 0)
      create(:branding, tenant: tenant)
      service = create(:service, tenant: tenant)
      client = create(:client, tenant: tenant, phone: "11988771234")
      appointment = ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: Time.zone.local(2026, 9, 8, 9, 45)) }
      sign_in_owner(owner)

      get owner_appointment_path(appointment)

      expect(response.body).to include(%(href="https://wa.me/5511988771234"))
      detail = Nokogiri::HTML5(response.body).at_css("turbo-frame#appointment_detail section")
      expect(detail.at_css("form")).to be_nil
    end

    it "dials the client through tel: in E.164" do
      travel_to Time.zone.local(2026, 9, 8, 7, 0)
      create(:branding, tenant: tenant)
      service = create(:service, tenant: tenant)
      client = create(:client, tenant: tenant, phone: "11988771234")
      appointment = ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: Time.zone.local(2026, 9, 8, 9, 45)) }
      sign_in_owner(owner)

      get owner_appointment_path(appointment)

      detail = Nokogiri::HTML5(response.body).at_css("turbo-frame#appointment_detail section")
      expect(detail.at_css(%(a[href="tel:+5511988771234"]))).to be_present
    end

    it "keeps the day's list next to the detail" do
      travel_to Time.zone.local(2026, 9, 8, 7, 0)
      create(:branding, tenant: tenant)
      service = create(:service, tenant: tenant)
      ana = create(:client, tenant: tenant, name: "Ana Paula Ribeiro")
      juliana = create(:client, tenant: tenant, name: "Juliana Prado")
      appointment = ActsAsTenant.with_tenant(tenant) do
        create(:appointment, tenant: tenant, professional: professional, service: service, client: juliana, starts_at: Time.zone.local(2026, 9, 8, 14, 0))
        create(:appointment, tenant: tenant, professional: professional, service: service, client: ana, starts_at: Time.zone.local(2026, 9, 8, 9, 45))
      end
      sign_in_owner(owner)

      get owner_appointment_path(appointment)

      expect(response.body).to include("Juliana Prado")
      detail = Nokogiri::HTML5(response.body).at_css("turbo-frame#appointment_detail")
      expect(detail.at_css(%(a[aria-current="true"]))).to be_present
    end

    it "sends an anonymous visitor to the login without any client name or phone" do
      travel_to Time.zone.local(2026, 9, 8, 7, 0)
      create(:branding, tenant: tenant)
      service = create(:service, tenant: tenant)
      client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro", phone: "11988771234")
      appointment = ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: Time.zone.local(2026, 9, 8, 9, 45)) }
      host! "#{tenant.subdomain}.zubio.com.br"

      get owner_appointment_path(appointment)
      expect(response).to redirect_to(new_owner_session_path)
      follow_redirect!

      expect(response.body).not_to include("Ana Paula Ribeiro")
      expect(response.body).not_to include(client.phone_display)
      expect(response.body).not_to include(client.phone)
    end

    it "answers not found for another establishment's appointment, with none of its data" do
      ze = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
      ze_professional = create(:professional, tenant: ze)
      ze_service = create(:service, tenant: ze)
      ze_client = create(:client, tenant: ze, name: "Carlos Zé", phone: "11977776666")
      ze_appointment = ActsAsTenant.with_tenant(ze) { create(:appointment, tenant: ze, professional: ze_professional, service: ze_service, client: ze_client, starts_at: Time.current.change(hour: 9)) }
      create(:branding, tenant: tenant)
      sign_in_owner(owner)
      allow(Rails.application).to receive(:env_config).and_wrap_original do |env_config|
        env_config.call.merge("action_dispatch.show_detailed_exceptions" => false)
      end

      get owner_appointment_path(ze_appointment)

      expect(response).to have_http_status(:not_found)
      expect(response.body).not_to include("Carlos Zé")
      expect(response.body).not_to include("(11) 97777-6666")
      expect(response.body).not_to include("11977776666")
      expect(response.body).not_to include("Barbearia do Zé")
    end

    it "shows its own appointment's detail" do
      create(:branding, tenant: tenant)
      service = create(:service, tenant: tenant)
      client = create(:client, tenant: tenant, name: "Ana Aurora")
      appointment = ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: Time.current.change(hour: 9)) }
      sign_in_owner(owner)

      get owner_appointment_path(appointment)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Ana Aurora")
    end

    it "shows the cancelled appointment's detail with its badge and no cancel button" do
      create(:branding, tenant: tenant)
      service = create(:service, tenant: tenant)
      client = create(:client, tenant: tenant)
      appointment = ActsAsTenant.with_tenant(tenant) { create(:appointment, :cancelled, tenant: tenant, professional: professional, service: service, client: client, starts_at: Time.current.change(hour: 9)) }
      sign_in_owner(owner)

      get owner_appointment_path(appointment)

      expect(response.body).to include("Desmarcado")
      expect(response.body).not_to include("Desmarcar este horário")
    end
  end

  describe "GET /owner/appointments without a selected appointment" do
    it "opens the agenda without a selected appointment showing the select hint" do
      create(:branding, tenant: tenant)
      sign_in_owner(owner)

      get owner_appointments_path

      expect(response.body).to include(Views::Owner::Appointments::Index::SELECT_HINT)
      expect(Nokogiri::HTML5(response.body).at_css("turbo-frame#appointment_detail section")).to be_nil
    end

    it "opens the appointment's show without the select hint" do
      create(:branding, tenant: tenant)
      service = create(:service, tenant: tenant)
      client = create(:client, tenant: tenant)
      appointment = ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: Time.current.change(hour: 9)) }
      sign_in_owner(owner)

      get owner_appointment_path(appointment)

      expect(response.body).not_to include(Views::Owner::Appointments::Index::SELECT_HINT)
    end
  end

  describe "POST /owner/session" do
    it "leads into the day's agenda after entering the panel" do
      create(:branding, tenant: tenant)
      host! "#{tenant.subdomain}.zubio.com.br"

      post owner_session_path, params: { email: owner.email, password: owner.password }

      expect(response).to redirect_to(owner_appointments_path)
    end
  end
end
