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

  it "hides a taken slot and still offers a free one" do
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, duration_minutes: 45)
    tuesday = Date.current.next_week(:tuesday)
    create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
    create(:appointment, tenant: tenant, professional: professional, service: service, starts_at: tuesday.in_time_zone.change(hour: 9, min: 45))
    host! "#{tenant.subdomain}.zubio.com.br"

    get new_client_service_booking_path(service, day: tuesday.iso8601)

    times = Nokogiri::HTML5(response.body).css("[data-slots] [data-slot]").map { |slot| slot.text.strip }
    expect(times).to include("09:00")
    expect(times).not_to include("09:45")
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
end
