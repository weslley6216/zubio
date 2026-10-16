require "rails_helper"

RSpec.describe "Public booking day and time selection", type: :request do
  let(:tenant) { create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora") }

  it "offers the free slots of the chosen day for the service" do
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45)
    tuesday = Date.current.next_week(:tuesday)
    create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
    host! "#{tenant.subdomain}.zubio.com.br"

    get new_client_service_booking_path(service, day: tuesday.iso8601)

    expect(response).to have_http_status(:ok)
    expect(Nokogiri::HTML5(response.body).css("[data-slots] [data-slot]").map { |slot| slot.text.strip }).to eq([ "09:00", "09:45", "10:30", "11:15" ])
    expect(response.body).to include("Design de sobrancelhas")
  end

  it "strikes a taken slot through and still offers the free ones" do
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, duration_minutes: 45)
    tuesday = Date.current.next_week(:tuesday)
    create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
    create(:appointment, tenant: tenant, professional: professional, service: service, starts_at: tuesday.in_time_zone.change(hour: 9, min: 45))
    host! "#{tenant.subdomain}.zubio.com.br"

    get new_client_service_booking_path(service, day: tuesday.iso8601)

    document = Nokogiri::HTML5(response.body)
    expect(document.css("[data-slots] [data-slot]").map { |slot| slot.text.strip }).to eq([ "09:00", "10:30", "11:15" ])
    taken = document.css("[data-slots] [data-slot-taken]")
    expect(taken.map { |slot| slot.text.strip }).to eq([ "09:45" ])
    expect(taken.first["aria-label"]).to eq("09:45, ocupado")
    expect(taken.first["class"]).to include("line-through")
  end

  it "spells the service, the grid step and the chosen day like the canvas" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, duration_minutes: 45, price_cents: 6_000)
    create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
    host! "#{tenant.subdomain}.zubio.com.br"

    get new_client_service_booking_path(service)

    document = Nokogiri::HTML5(response.body)
    expect(document.at_css("[data-price]").text).to eq("R$ 60")
    expect(response.body).to include("45 min")
    expect(document.at_css("[data-grid-hint]").text).to eq("A grade anda de 45 em 45 porque o serviço dura 45.")
    expect(document.at_css("[data-summary]").text).to eq("Ter, 8 set · R$ 60")
    expect(document.at_css("[data-day='2026-09-08'] span:last-child").text).to eq("08")
  end

  it "names the single day with no free slot in the hint" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, duration_minutes: 45)
    (0..6).each { |weekday| create(:working_hour, tenant: tenant, professional: professional, weekday: weekday, opens_at: "09:00", closes_at: "12:00") }
    create(:schedule_exception, tenant: tenant, professional: professional, occurs_on: Date.new(2026, 9, 11))
    host! "#{tenant.subdomain}.zubio.com.br"

    get new_client_service_booking_path(service)

    expect(Nokogiri::HTML5(response.body).at_css("[data-days-off-hint]").text).to eq("Sexta está em cinza: sem horário livre.")
  end

  it "groups several days with no free slot in the hint" do
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, duration_minutes: 45)
    create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
    host! "#{tenant.subdomain}.zubio.com.br"

    get new_client_service_booking_path(service)

    expect(Nokogiri::HTML5(response.body).at_css("[data-days-off-hint]").text).to eq(Views::Client::Bookings::New::DAYS_OFF_HINT)
  end

  it "leaves the hint out when every day has a free slot" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, duration_minutes: 45)
    (0..6).each { |weekday| create(:working_hour, tenant: tenant, professional: professional, weekday: weekday, opens_at: "09:00", closes_at: "12:00") }
    host! "#{tenant.subdomain}.zubio.com.br"

    get new_client_service_booking_path(service)

    document = Nokogiri::HTML5(response.body)
    expect(document.css("[data-day-selector] a[data-day]").size).to eq(Client::BookingsController::WINDOW_DAYS)
    expect(document.at_css("[data-days-off-hint]")).to be_nil
  end

  it "leads back to the establishment page from the header" do
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, duration_minutes: 45)
    create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
    host! "#{tenant.subdomain}.zubio.com.br"

    get new_client_service_booking_path(service)

    back = Nokogiri::HTML5(response.body).at_css("header a[aria-label='#{Views::Client::Bookings::New::BACK_LABEL}']")
    expect(back["href"]).to eq(establishment_path)
  end

  it "offers the next days from today and disables the ones with no free slot" do
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, duration_minutes: 45)
    [ 2, 3, 4 ].each { |weekday| create(:working_hour, tenant: tenant, professional: professional, weekday: weekday, opens_at: "09:00", closes_at: "12:00") }
    host! "#{tenant.subdomain}.zubio.com.br"

    get new_client_service_booking_path(service)

    document = Nokogiri::HTML5(response.body)
    days = document.css("[data-day-selector] [data-day]")
    expect(days.size).to eq(Client::BookingsController::WINDOW_DAYS)
    expect(days.first["data-day"]).to eq(Date.current.iso8601)
    expect(days.any? { |day| day["aria-disabled"] == "true" }).to be(true)
    expect(days.any? { |day| day.name == "a" }).to be(true)
  end

  it "answers another day's grid keeping the service" do
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, name: "Corte", duration_minutes: 60)
    tuesday = Date.current.next_week(:tuesday)
    wednesday = tuesday + 1
    create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "11:00")
    create(:working_hour, tenant: tenant, professional: professional, weekday: 3, opens_at: "14:00", closes_at: "16:00")
    host! "#{tenant.subdomain}.zubio.com.br"

    get new_client_service_booking_path(service, day: wednesday.iso8601)

    expect(Nokogiri::HTML5(response.body).css("[data-slots] [data-slot]").map { |slot| slot.text.strip }).to eq([ "14:00", "15:00" ])
    expect(response.body).to include(new_client_service_booking_path(service, day: tuesday.iso8601))
    expect(response.body).to include("Corte")
  end

  it "steps the grid by the service duration" do
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, duration_minutes: 30)
    tuesday = Date.current.next_week(:tuesday)
    create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "11:00")
    host! "#{tenant.subdomain}.zubio.com.br"

    get new_client_service_booking_path(service, day: tuesday.iso8601)

    expect(Nokogiri::HTML5(response.body).css("[data-slots] [data-slot]").map { |slot| slot.text.strip }).to eq([ "09:00", "09:30", "10:00", "10:30" ])
  end

  it "explains a day with no service instead of an empty grid" do
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, duration_minutes: 45)
    create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
    monday = Date.current.next_week(:monday)
    host! "#{tenant.subdomain}.zubio.com.br"

    get new_client_service_booking_path(service, day: monday.iso8601)

    expect(Nokogiri::HTML5(response.body).css("[data-slots] [data-slot]").map { |slot| slot.text.strip }).to be_empty
    expect(response.body).to include(Views::Client::Bookings::New::NO_SERVICE_MESSAGE)
  end

  it "explains a day off instead of an empty grid" do
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, duration_minutes: 45)
    tuesday = Date.current.next_week(:tuesday)
    create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
    create(:schedule_exception, tenant: tenant, professional: professional, occurs_on: tuesday)
    host! "#{tenant.subdomain}.zubio.com.br"

    get new_client_service_booking_path(service, day: tuesday.iso8601)

    expect(Nokogiri::HTML5(response.body).css("[data-slots] [data-slot]").map { |slot| slot.text.strip }).to be_empty
    expect(response.body).to include(Views::Client::Bookings::New::NO_SERVICE_MESSAGE)
  end

  it "explains a fully booked day instead of an empty grid" do
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, duration_minutes: 45)
    tuesday = Date.current.next_week(:tuesday)
    create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "09:45")
    create(:appointment, tenant: tenant, professional: professional, service: service, starts_at: tuesday.in_time_zone.change(hour: 9))
    host! "#{tenant.subdomain}.zubio.com.br"

    get new_client_service_booking_path(service, day: tuesday.iso8601)

    expect(Nokogiri::HTML5(response.body).css("[data-slots] [data-slot]").map { |slot| slot.text.strip }).to be_empty
    expect(response.body).to include(Views::Client::Bookings::New::FULLY_BOOKED_MESSAGE)
  end

  it "tells an establishment with no published hours has no grid" do
    create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, duration_minutes: 45)
    host! "#{tenant.subdomain}.zubio.com.br"

    get new_client_service_booking_path(service)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(Views::Client::Bookings::New::UNPUBLISHED_MESSAGE)
    expect(response.body).not_to include("data-day-selector")
  end

  it "tells an establishment whose only professional is inactive has no grid" do
    professional = create(:professional, tenant: tenant, active: false)
    service = create(:service, tenant: tenant, duration_minutes: 45)
    create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
    host! "#{tenant.subdomain}.zubio.com.br"

    get new_client_service_booking_path(service)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(Views::Client::Bookings::New::UNPUBLISHED_MESSAGE)
    expect(response.body).not_to include("data-day-selector")
  end

  it "keeps the confirm button inert while no time can be chosen" do
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, duration_minutes: 45)
    tuesday = Date.current.next_week(:tuesday)
    create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
    host! "#{tenant.subdomain}.zubio.com.br"

    get new_client_service_booking_path(service, day: tuesday.iso8601)

    button = Nokogiri::HTML5(response.body).css("button").find { |candidate| candidate.text.strip == Views::Client::Bookings::New::CONFIRM_LABEL }
    expect(button).to be_present
    expect(button.key?("disabled")).to be(true)
  end

  %w[banana 2020-01-01 2026-13-40].each do |unusable_day|
    it "falls back to the first bookable day for day=#{unusable_day}" do
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      monday = Date.current.next_week(:monday)
      tuesday = monday + 1
      create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
      host! "#{tenant.subdomain}.zubio.com.br"

      travel_to(monday.in_time_zone.change(hour: 8)) { get new_client_service_booking_path(service, day: unusable_day) }

      document = Nokogiri::HTML5(response.body)
      expect(response).to have_http_status(:ok)
      expect(document.css("[data-day-selector] [aria-current='date']").map { |day| day["data-day"] }).to eq([ tuesday.iso8601 ])
      expect(document.css("[data-slots] [data-slot]").map { |slot| slot.text.strip }).to eq([ "09:00", "09:45", "10:30", "11:15" ])
    end
  end

  it "shows today as no longer bookable once its working hours are over" do
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, duration_minutes: 45)
    tuesday = Date.current.next_week(:tuesday)
    create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
    host! "#{tenant.subdomain}.zubio.com.br"

    travel_to(tuesday.in_time_zone.change(hour: 15)) { get new_client_service_booking_path(service, day: tuesday.iso8601) }

    document = Nokogiri::HTML5(response.body)
    expect(document.at_css("[data-day='#{tuesday.iso8601}']")["aria-disabled"]).to eq("true")
    expect(response.body).to include(Views::Client::Bookings::New::FULLY_BOOKED_MESSAGE)
  end

  it "answers not found for another establishment's service, with none of its data" do
    other_tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
    other_service = create(:service, tenant: other_tenant, name: "Barba do Zé")
    host! "#{tenant.subdomain}.zubio.com.br"
    allow(Rails.application).to receive(:env_config).and_wrap_original do |env_config|
      env_config.call.merge("action_dispatch.show_detailed_exceptions" => false)
    end

    get new_client_service_booking_path(other_service)

    expect(response).to have_http_status(:not_found)
    expect(response.body).not_to include("Barba do Zé")
  end

  it "answers not found for a deactivated service" do
    service = create(:service, tenant: tenant, active: false)
    host! "#{tenant.subdomain}.zubio.com.br"
    allow(Rails.application).to receive(:env_config).and_wrap_original do |env_config|
      env_config.call.merge("action_dispatch.show_detailed_exceptions" => false)
    end

    get new_client_service_booking_path(service)

    expect(response).to have_http_status(:not_found)
  end

  it "keeps another tenant's appointment from removing a slot here" do
    aurora_professional = create(:professional, tenant: tenant)
    aurora_service = create(:service, tenant: tenant, duration_minutes: 45)
    tuesday = Date.current.next_week(:tuesday)
    create(:working_hour, tenant: tenant, professional: aurora_professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
    ze = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
    ze_professional = create(:professional, tenant: ze)
    ze_service = create(:service, tenant: ze, duration_minutes: 45)
    create(:working_hour, tenant: ze, professional: ze_professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
    create(:appointment, tenant: ze, professional: ze_professional, service: ze_service, starts_at: tuesday.in_time_zone.change(hour: 9))
    host! "#{tenant.subdomain}.zubio.com.br"

    get new_client_service_booking_path(aurora_service, day: tuesday.iso8601)

    expect(Nokogiri::HTML5(response.body).css("[data-slots] [data-slot]").map { |slot| slot.text.strip }).to include("09:00")
  end

  it "paints the grid with brand tokens and never a demo token" do
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, duration_minutes: 45)
    tuesday = Date.current.next_week(:tuesday)
    create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
    host! "#{tenant.subdomain}.zubio.com.br"

    get new_client_service_booking_path(service, day: tuesday.iso8601)

    expect(response.body).to include("bg-brand-600")
    expect(response.body).to include("tabular-nums")
    expect(response.body).not_to include("demo")
  end

  it "asks the database the same number of times regardless of how full the window is" do
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, duration_minutes: 45)
    (1..5).each { |weekday| create(:working_hour, tenant: tenant, professional: professional, weekday: weekday, opens_at: "09:00", closes_at: "18:00") }
    host! "#{tenant.subdomain}.zubio.com.br"
    get new_client_service_booking_path(service)
    single = count_queries { get new_client_service_booking_path(service) }
    (7..11).each { |offset| create(:schedule_exception, tenant: tenant, professional: professional, occurs_on: Date.current + offset) }

    many = count_queries { get new_client_service_booking_path(service) }

    expect(single).to be_positive
    expect(many).to eq(single)
  end

  describe "POST create" do
    it "confirming creates a confirmed appointment and renders the receipt" do
      travel_to Time.zone.local(2026, 9, 8, 7, 0)
      professional = create(:professional, tenant: tenant, display_name: "Mary")
      service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45, price_cents: 6_000)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
      host! "#{tenant.subdomain}.zubio.com.br"
      starts_at = Date.new(2026, 9, 8).in_time_zone.change(hour: 9)

      post client_service_booking_path(service), params: { name: "Ana Paula Ribeiro", phone: "(11) 98877-1234", starts_at: starts_at.iso8601 }

      appointment_attributes = ActsAsTenant.with_tenant(tenant) do
        appointment = Appointment.occupying.sole
        [ appointment.service, appointment.professional, appointment.starts_at, appointment.confirmed? ]
      end
      expect(response).to have_http_status(:ok)
      expect(appointment_attributes).to eq([ service, professional, starts_at, true ])
      expect(response.body).to include("Horário confirmado")
      expect(response.body).to include("Ter, 8 set · 09:00")
    end

    it "creates the client and opens no client session" do
      travel_to Time.zone.local(2026, 9, 8, 7, 0)
      professional = create(:professional, tenant: tenant, display_name: "Mary")
      service = create(:service, tenant: tenant, duration_minutes: 45)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
      host! "#{tenant.subdomain}.zubio.com.br"
      starts_at = Date.new(2026, 9, 8).in_time_zone.change(hour: 9)

      post client_service_booking_path(service), params: { name: "Ana Paula Ribeiro", phone: "11988771234", starts_at: starts_at.iso8601 }

      expect(ActsAsTenant.with_tenant(tenant) { Client.where(phone: "11988771234").count }).to eq(1)
      expect(session[:client_id]).to be_nil
    end

    it "an existing phone reuses the single client" do
      travel_to Time.zone.local(2026, 9, 8, 7, 0)
      professional = create(:professional, tenant: tenant, display_name: "Mary")
      service = create(:service, tenant: tenant, duration_minutes: 45)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
      existing = create(:client, tenant: tenant, name: "Ana", phone: "11988771234")
      host! "#{tenant.subdomain}.zubio.com.br"
      starts_at = Date.new(2026, 9, 8).in_time_zone.change(hour: 9)

      post client_service_booking_path(service), params: { name: "Ana Paula Ribeiro", phone: "11988771234", starts_at: starts_at.iso8601 }

      expect(ActsAsTenant.with_tenant(tenant) { Client.count }).to eq(1)
      expect(ActsAsTenant.with_tenant(tenant) { Appointment.occupying.sole.client }).to eq(existing)
    end

    it "shows the save-this-link block with the cancel token url" do
      travel_to Time.zone.local(2026, 9, 8, 7, 0)
      professional = create(:professional, tenant: tenant, display_name: "Mary")
      service = create(:service, tenant: tenant, duration_minutes: 45)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
      host! "#{tenant.subdomain}.zubio.com.br"
      starts_at = Date.new(2026, 9, 8).in_time_zone.change(hour: 9)

      post client_service_booking_path(service), params: { name: "Ana", phone: "11988771234", starts_at: starts_at.iso8601 }

      token = ActsAsTenant.with_tenant(tenant) { Appointment.occupying.sole.cancel_token }
      expect(response.body).to include("/a/#{token}")
      expect(response.body).to include("Esta tela é o comprovante.")
    end

    it "books in the request tenant and creates nothing in another" do
      travel_to Time.zone.local(2026, 9, 8, 7, 0)
      professional = create(:professional, tenant: tenant, display_name: "Mary")
      service = create(:service, tenant: tenant, duration_minutes: 45)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
      ze = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
      host! "#{tenant.subdomain}.zubio.com.br"
      starts_at = Date.new(2026, 9, 8).in_time_zone.change(hour: 9)

      post client_service_booking_path(service), params: { name: "Ana", phone: "11988771234", starts_at: starts_at.iso8601 }

      expect(ActsAsTenant.with_tenant(tenant) { Appointment.count }).to eq(1)
      expect(ActsAsTenant.with_tenant(ze) { [ Appointment.count, Client.count ] }).to eq([ 0, 0 ])
    end

    it "blocks further booking attempts after the rate limit is exceeded, creating nothing extra" do
      professional = create(:professional, tenant: tenant, display_name: "Mary")
      service = create(:service, tenant: tenant, duration_minutes: 45)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
      host! "#{tenant.subdomain}.zubio.com.br"
      10.times { post client_service_booking_path(service), params: { name: "Ana", phone: "11988771234", starts_at: "not-a-time" } }

      post client_service_booking_path(service), params: { name: "Ana", phone: "11988771234", starts_at: "not-a-time" }

      expect(response).to redirect_to(new_client_service_booking_path(service))
      expect(ActsAsTenant.with_tenant(tenant) { Appointment.count }).to eq(0)
    end
  end
end
