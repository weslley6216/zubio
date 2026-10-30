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
      create(:working_hour, tenant: tenant, professional: professional, weekday: Date.current.wday, opens_at: "08:00", closes_at: "20:00")
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

    it "offers a 'Novo agendamento' button linking to the new-appointment screen" do
      create(:branding, tenant: tenant)
      sign_in_owner(owner)

      get owner_appointments_path

      expect(response.body).to include("Novo agendamento")
      expect(response.body).to include(%(href="#{new_owner_appointment_path}"))
    end

    it "sends an anonymous visitor to the login" do
      create(:branding, tenant: tenant)
      service = create(:service, tenant: tenant)
      client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro", phone: "11988771234")
      ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: Date.current.in_time_zone.change(hour: 9)) }
      host! "#{tenant.subdomain}.zubio.com.br"

      get owner_appointments_path

      expect(response).to redirect_to(new_owner_session_path)
    end

    it "shows no client name or phone on the login the anonymous visitor is sent to" do
      create(:branding, tenant: tenant)
      service = create(:service, tenant: tenant)
      client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro", phone: "11988771234")
      ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: Date.current.in_time_zone.change(hour: 9)) }
      host! "#{tenant.subdomain}.zubio.com.br"

      get owner_appointments_path
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

    it "counts and shows only its own tenant's cancellation in the group" do
      ze = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
      ze_professional = create(:professional, tenant: ze)
      ze_service = create(:service, tenant: ze)
      ze_client = create(:client, tenant: ze, name: "Carlos Zé")
      ActsAsTenant.with_tenant(ze) { create(:appointment, :cancelled, tenant: ze, professional: ze_professional, service: ze_service, client: ze_client, starts_at: Date.current.in_time_zone.change(hour: 9)) }
      create(:branding, tenant: tenant)
      aurora_service = create(:service, tenant: tenant)
      aurora_client = create(:client, tenant: tenant, name: "Ana Aurora")
      ActsAsTenant.with_tenant(tenant) { create(:appointment, :cancelled, tenant: tenant, professional: professional, service: aurora_service, client: aurora_client, starts_at: Date.current.in_time_zone.change(hour: 9)) }
      sign_in_owner(owner)

      get owner_appointments_path

      expect(response.body).to include("Ana Aurora")
      expect(response.body).to include("1 desmarcado")
      expect(response.body).not_to include("Carlos Zé")
    end

    it "queries the database the same number of times with a cancelled appointment present as without one" do
      travel_to Time.zone.local(2026, 9, 8, 7, 0)
      create(:branding, tenant: tenant)
      service = create(:service, tenant: tenant)
      client = create(:client, tenant: tenant)
      ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: Date.current.in_time_zone.change(hour: 9)) }
      sign_in_owner(owner)

      without_cancellation = count_queries { get owner_appointments_path }

      ActsAsTenant.with_tenant(tenant) { create(:appointment, :cancelled, tenant: tenant, professional: professional, service: service, client: create(:client, tenant: tenant), starts_at: Date.current.in_time_zone.change(hour: 15)) }
      with_cancellation = count_queries { get owner_appointments_path }

      expect(without_cancellation).to be_positive
      expect(with_cancellation).to eq(without_cancellation)
    end

    it "queries the database the same number of times for many appointments as for one" do
      travel_to Time.zone.local(2026, 9, 8, 7, 0)
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

    it "frames the out-of-hours appointment in the day's list" do
      create(:branding, tenant: tenant)
      service = create(:service, tenant: tenant)
      client = create(:client, tenant: tenant, name: "Camila Nunes")
      friday = Date.current.next_week(:friday)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 5, opens_at: "09:00", closes_at: "18:00")
      ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: friday.in_time_zone.change(hour: 18, min: 30)) }
      sign_in_owner(owner)

      get owner_appointments_path(day: friday.iso8601)

      expect(response.body).to include("Fora do expediente")
      expect(response.body).to include("border-danger")
    end

    it "leaves the in-hours appointment unframed" do
      create(:branding, tenant: tenant)
      service = create(:service, tenant: tenant)
      client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro")
      friday = Date.current.next_week(:friday)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 5, opens_at: "09:00", closes_at: "18:00")
      ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: friday.in_time_zone.change(hour: 14)) }
      sign_in_owner(owner)

      get owner_appointments_path(day: friday.iso8601)

      expect(response.body).to include("Confirmado")
      expect(response.body).not_to include("Fora do expediente")
    end

    it "frames every appointment of a day off" do
      create(:branding, tenant: tenant)
      service = create(:service, tenant: tenant)
      first_client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro")
      second_client = create(:client, tenant: tenant, name: "Juliana Prado")
      tuesday = Date.current.next_week(:tuesday)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "18:00")
      create(:schedule_exception, tenant: tenant, professional: professional, occurs_on: tuesday)
      ActsAsTenant.with_tenant(tenant) do
        create(:appointment, tenant: tenant, professional: professional, service: service, client: first_client, starts_at: tuesday.in_time_zone.change(hour: 10))
        create(:appointment, tenant: tenant, professional: professional, service: service, client: second_client, starts_at: tuesday.in_time_zone.change(hour: 14))
      end
      sign_in_owner(owner)

      get owner_appointments_path(day: tuesday.iso8601)

      expect(response.body.scan("Fora do expediente").count).to eq(2)
    end

    it "does not frame the slot once the hours cover it" do
      create(:branding, tenant: tenant)
      service = create(:service, tenant: tenant)
      client = create(:client, tenant: tenant, name: "Camila Nunes")
      friday = Date.current.next_week(:friday)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 5, opens_at: "09:00", closes_at: "20:00")
      ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: friday.in_time_zone.change(hour: 18, min: 30)) }
      sign_in_owner(owner)

      get owner_appointments_path(day: friday.iso8601)

      expect(response.body).not_to include("Fora do expediente")
    end

    it "frames by the signed-in tenant's hours only" do
      ze = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
      ze_professional = create(:professional, tenant: ze)
      create(:working_hour, tenant: ze, professional: ze_professional, weekday: 5, opens_at: "09:00", closes_at: "20:00")
      create(:branding, tenant: tenant)
      service = create(:service, tenant: tenant)
      client = create(:client, tenant: tenant, name: "Camila Nunes")
      friday = Date.current.next_week(:friday)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 5, opens_at: "09:00", closes_at: "18:00")
      ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: friday.in_time_zone.change(hour: 18, min: 30)) }
      sign_in_owner(owner)

      get owner_appointments_path(day: friday.iso8601)

      expect(response.body).to include("Fora do expediente")
      expect(response.body).not_to include("Barbearia do Zé")
    end

    it "queries the database the same number of times for many out-of-hours appointments as for one" do
      friday = Date.current.next_week(:friday)
      travel_to(friday.in_time_zone.change(hour: 7)) do
        create(:branding, tenant: tenant)
        service = create(:service, tenant: tenant)
        client = create(:client, tenant: tenant)
        create(:working_hour, tenant: tenant, professional: professional, weekday: 5, opens_at: "09:00", closes_at: "18:00")
        ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: friday.in_time_zone.change(hour: 18, min: 30)) }
        sign_in_owner(owner)

        single = count_queries { get owner_appointments_path(day: friday.iso8601) }

        ActsAsTenant.with_tenant(tenant) do
          create(:appointment, tenant: tenant, professional: professional, service: service, client: create(:client, tenant: tenant), starts_at: friday.in_time_zone.change(hour: 19, min: 30))
          create(:appointment, tenant: tenant, professional: professional, service: service, client: create(:client, tenant: tenant), starts_at: friday.in_time_zone.change(hour: 20, min: 30))
        end
        many = count_queries { get owner_appointments_path(day: friday.iso8601) }

        expect(single).to be_positive
        expect(many).to eq(single)
      end
    end

    it "subscribes to the tenant agenda stream and asks for a morph refresh" do
      create(:branding, tenant: tenant)
      sign_in_owner(owner)

      get owner_appointments_path

      expect(response.body).to include("<turbo-cable-stream-source")
      expect(response.body).to include(%(<meta name="turbo-refresh-method" content="morph">))
      expect(response.body).to include(%(<meta name="turbo-refresh-scroll" content="preserve">))
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
      whatsapp_link = detail.at_css(%(a[href="https://wa.me/5511988771234"]))
      expect(whatsapp_link.ancestors("form")).to be_empty
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
      agenda = Nokogiri::HTML5(response.body).at_css("turbo-frame#agenda_day")
      expect(agenda.at_css(%(a[aria-current="true"])).text).to eq("Ana Paula Ribeiro")
    end

    it "sends an anonymous visitor to the login" do
      travel_to Time.zone.local(2026, 9, 8, 7, 0)
      create(:branding, tenant: tenant)
      service = create(:service, tenant: tenant)
      client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro", phone: "11988771234")
      appointment = ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: Time.zone.local(2026, 9, 8, 9, 45)) }
      host! "#{tenant.subdomain}.zubio.com.br"

      get owner_appointment_path(appointment)

      expect(response).to redirect_to(new_owner_session_path)
    end

    it "shows no client name or phone on the login the anonymous visitor is sent to" do
      travel_to Time.zone.local(2026, 9, 8, 7, 0)
      create(:branding, tenant: tenant)
      service = create(:service, tenant: tenant)
      client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro", phone: "11988771234")
      appointment = ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: Time.zone.local(2026, 9, 8, 9, 45)) }
      host! "#{tenant.subdomain}.zubio.com.br"

      get owner_appointment_path(appointment)
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

      expect(response.body).to include(Components::Owner::AppointmentDetailFrame::SELECT_HINT)
      expect(Nokogiri::HTML5(response.body).at_css("turbo-frame#appointment_detail section")).to be_nil
    end

    it "opens the appointment's show without the select hint" do
      create(:branding, tenant: tenant)
      service = create(:service, tenant: tenant)
      client = create(:client, tenant: tenant)
      appointment = ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: Time.current.change(hour: 9)) }
      sign_in_owner(owner)

      get owner_appointment_path(appointment)

      expect(response.body).not_to include(Components::Owner::AppointmentDetailFrame::SELECT_HINT)
    end
  end

  describe "frame responses" do
    it "responds to the day frame with only the day's list, without the header or the day strip" do
      create(:branding, tenant: tenant)
      service = create(:service, tenant: tenant)
      other_day = Date.current + 1.day
      client = create(:client, tenant: tenant, name: "Bia Amanhã")
      ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: other_day.in_time_zone.change(hour: 9)) }
      sign_in_owner(owner)

      get owner_appointments_path(day: other_day.iso8601), headers: { "Turbo-Frame" => "agenda_day" }

      document = Nokogiri::HTML5(response.body)
      expect(response.body).to include("Bia Amanhã")
      expect(response.body).to include(Components::LongDate.new(date: other_day).call)
      expect(document.at_css("turbo-frame#agenda_day")).to be_present
      expect(document.at_css("header")).to be_nil
      expect(document.at_css("[data-day-selector]")).to be_nil
    end

    it "responds to the detail frame with only the detail, without the list" do
      travel_to Time.zone.local(2026, 9, 8, 7, 0)
      create(:branding, tenant: tenant)
      service = create(:service, tenant: tenant)
      client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro")
      appointment = ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: Time.zone.local(2026, 9, 8, 9, 45)) }
      sign_in_owner(owner)

      get owner_appointment_path(appointment), headers: { "Turbo-Frame" => "appointment_detail" }

      document = Nokogiri::HTML5(response.body)
      expect(document.at_css("turbo-frame#appointment_detail section")).to be_present
      expect(document.at_css("main")).to be_nil
    end

    it "renders the whole page with the header and the strip without a frame header" do
      create(:branding, tenant: tenant)
      sign_in_owner(owner)

      get owner_appointments_path

      document = Nokogiri::HTML5(response.body)
      expect(document.at_css("header")).to be_present
      expect(document.at_css("[data-day-selector]")).to be_present
    end

    it "answers not found for another establishment's appointment requested through the detail frame, with none of its data" do
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

      get owner_appointment_path(ze_appointment), headers: { "Turbo-Frame" => "appointment_detail" }

      expect(response).to have_http_status(:not_found)
      expect(response.body).not_to include("Carlos Zé")
      expect(response.body).not_to include("(11) 97777-6666")
      expect(response.body).not_to include("11977776666")
      expect(response.body).not_to include("Barbearia do Zé")
    end

    it "shows its own appointment's detail through the detail frame" do
      create(:branding, tenant: tenant)
      service = create(:service, tenant: tenant)
      client = create(:client, tenant: tenant, name: "Ana Aurora")
      appointment = ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: Time.current.change(hour: 9)) }
      sign_in_owner(owner)

      get owner_appointment_path(appointment), headers: { "Turbo-Frame" => "appointment_detail" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Ana Aurora")
    end
  end

  describe "GET /owner/appointments/new" do
    it "offers only the free slots, the same grid the public page renders" do
      travel_to Time.zone.local(2026, 9, 8, 7, 0)
      service = create(:service, tenant: tenant, duration_minutes: 60)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
      ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional, service: service, starts_at: Date.current.in_time_zone.change(hour: 10)) }
      sign_in_owner(owner)

      get new_owner_appointment_path(service_id: service.id, day: Date.current.iso8601)
      owner_free = Nokogiri::HTML5(response.body).css("[data-slots] [data-slot]").map { |slot| slot.text.strip }
      get new_client_service_booking_path(service, day: Date.current.iso8601)
      public_free = Nokogiri::HTML5(response.body).css("[data-slots] [data-slot]").map { |slot| slot.text.strip }

      expect(owner_free).to eq([ "09:00", "11:00" ])
      expect(owner_free).to eq(public_free)
    end

    it "redirects an anonymous visitor on GET new to the login and creates nothing" do
      service = create(:service, tenant: tenant)
      host! "#{tenant.subdomain}.zubio.com.br"

      get new_owner_appointment_path(service_id: service.id)

      expect(response).to redirect_to(new_owner_session_path)
      expect(ActsAsTenant.with_tenant(tenant) { Appointment.count }).to eq(0)
    end

    it "shows the unpublished message when the schedule is empty" do
      service = create(:service, tenant: tenant)
      sign_in_owner(owner)

      get new_owner_appointment_path(service_id: service.id)

      expect(response.body).to include(Views::Client::Bookings::New::UNPUBLISHED_MESSAGE)
      expect(response.body).not_to include("data-slots")
    end

    it "shows the unpublished message when there is no active service" do
      sign_in_owner(owner)

      get new_owner_appointment_path

      expect(response.body).to include(Views::Client::Bookings::New::UNPUBLISHED_MESSAGE)
    end

    it "answers a day switch with only the booking grid frame" do
      travel_to Time.zone.local(2026, 9, 8, 7, 0)
      service = create(:service, tenant: tenant, duration_minutes: 60)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
      sign_in_owner(owner)

      get new_owner_appointment_path(service_id: service.id, day: Date.current.iso8601), headers: { "Turbo-Frame" => "booking-grid" }

      expect(response.body).to include(%(id="booking-grid"))
      expect(Nokogiri::HTML5(response.body).css("[data-slots] [data-slot]").map { |slot| slot.text.strip }).to eq([ "09:00", "10:00", "11:00" ])
      expect(response.body).not_to include(Views::Owner::Appointments::New::TITLE)
    end

    it "404s on an inactive or unknown service" do
      inactive = create(:service, tenant: tenant, active: false)
      sign_in_owner(owner)

      get new_owner_appointment_path(service_id: inactive.id)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /owner/appointments" do
    it "creates the confirmed appointment and redirects to the day's agenda" do
      travel_to Time.zone.local(2026, 9, 8, 7, 0)
      service = create(:service, tenant: tenant, duration_minutes: 60)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
      sign_in_owner(owner)
      starts_at = Date.new(2026, 9, 8).in_time_zone.change(hour: 11)

      post owner_appointments_path, params: { service_id: service.id, name: "Juliana Prado", phone: "(11) 99123-4455", starts_at: starts_at.iso8601 }

      appointment = ActsAsTenant.with_tenant(tenant) { Appointment.includes(:client).last }
      expect(appointment.client.name).to eq("Juliana Prado")
      expect(appointment).to be_confirmed
      expect(response).to redirect_to(owner_appointment_path(appointment))
    end

    it "removes the booked slot from the public grid" do
      travel_to Time.zone.local(2026, 9, 8, 7, 0)
      service = create(:service, tenant: tenant, duration_minutes: 60)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
      sign_in_owner(owner)
      starts_at = Date.new(2026, 9, 8).in_time_zone.change(hour: 11)
      post owner_appointments_path, params: { service_id: service.id, name: "Juliana Prado", phone: "(11) 99123-4455", starts_at: starts_at.iso8601 }

      get new_client_service_booking_path(service, day: starts_at.to_date.iso8601)

      expect(Nokogiri::HTML5(response.body).css("[data-slots] [data-slot]").map { |slot| slot.text.strip }).not_to include("11:00")
    end

    it "books an existing client by client_id without duplicating her" do
      travel_to Time.zone.local(2026, 9, 8, 7, 0)
      service = create(:service, tenant: tenant, duration_minutes: 60)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
      existing = create(:client, tenant: tenant, name: "Juliana Prado", phone: "11991234455")
      sign_in_owner(owner)
      starts_at = Date.new(2026, 9, 8).in_time_zone.change(hour: 11)

      post owner_appointments_path, params: { service_id: service.id, client_id: existing.id, starts_at: starts_at.iso8601 }

      appointment = ActsAsTenant.with_tenant(tenant) { Appointment.includes(:client).last }
      expect(appointment.client).to eq(existing)
      expect(ActsAsTenant.with_tenant(tenant) { Client.count }).to eq(1)
    end

    it "loses the race, creates no second appointment and keeps the client, service, day and time" do
      travel_to Time.zone.local(2026, 9, 8, 7, 0)
      service = create(:service, tenant: tenant, duration_minutes: 60)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
      starts_at = Date.new(2026, 9, 8).in_time_zone.change(hour: 11)
      ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional, service: service, starts_at: starts_at) }
      sign_in_owner(owner)

      post owner_appointments_path, params: { service_id: service.id, name: "Juliana Prado", phone: "(11) 99123-4455", starts_at: starts_at.iso8601 }

      expect(response).to have_http_status(:unprocessable_content)
      expect(ActsAsTenant.with_tenant(tenant) { Appointment.count }).to eq(1)
      expect(response.body).to include("Alguém marcou 11:00 antes de você")
      expect(response.body).to include(service.name)
      expect(response.body).to include("setembro")
      document = Nokogiri::HTML5(response.body)
      expect(document.at_css("[data-slot-taken][data-time='11:00']")).to be_present
      expect(document.at_css("[data-slot][data-time='10:00'][aria-pressed='true']")).to be_present
      expect(document.at_css("input[name='name']")["value"]).to eq("Juliana Prado")
      expect(document.at_css("input[name='phone']")["value"]).to eq("(11) 99123-4455")
    end

    it "keeps the existing client by id when it loses the race" do
      travel_to Time.zone.local(2026, 9, 8, 7, 0)
      service = create(:service, tenant: tenant, duration_minutes: 60)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
      existing = create(:client, tenant: tenant, name: "Juliana Prado", phone: "11991234455")
      starts_at = Date.new(2026, 9, 8).in_time_zone.change(hour: 11)
      ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional, service: service, starts_at: starts_at) }
      sign_in_owner(owner)

      post owner_appointments_path, params: { service_id: service.id, client_id: existing.id, starts_at: starts_at.iso8601 }

      form = Nokogiri::HTML5(response.body).at_css("form[action='#{owner_appointments_path}']")
      expect(form.at_css("input[name='client_id']")["value"]).to eq(existing.id.to_s)
      expect(form.at_css("input[name='name']")).to be_nil
      expect(response.body).to include("(11) 99123-4455")
    end

    it "redirects an anonymous visitor on POST to the login and creates nothing" do
      service = create(:service, tenant: tenant)
      host! "#{tenant.subdomain}.zubio.com.br"

      post owner_appointments_path, params: { service_id: service.id, name: "Juliana Prado", phone: "11991234455", starts_at: Time.current.iso8601 }

      expect(response).to redirect_to(new_owner_session_path)
      expect(ActsAsTenant.with_tenant(tenant) { Appointment.count }).to eq(0)
    end

    it "ignores a client_id from another tenant" do
      other = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
      other_client = create(:client, tenant: other)
      service = create(:service, tenant: tenant)
      sign_in_owner(owner)

      post owner_appointments_path, params: { service_id: service.id, client_id: other_client.id, starts_at: Time.current.iso8601 }

      expect(response).to have_http_status(:not_found)
      expect(ActsAsTenant.with_tenant(tenant) { Appointment.count }).to eq(0)
    end

    it "re-renders without creating when the time is missing or malformed" do
      service = create(:service, tenant: tenant)
      sign_in_owner(owner)

      post owner_appointments_path, params: { service_id: service.id, name: "Juliana Prado", phone: "11991234455", starts_at: "not-a-time" }

      expect(response).to have_http_status(:unprocessable_content)
      expect(ActsAsTenant.with_tenant(tenant) { Appointment.count }).to eq(0)
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
