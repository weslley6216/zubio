require "rails_helper"

RSpec.describe "My appointments", type: :request do
  let(:tenant) { create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora") }

  it "sends a visitor without a session to the establishment page" do
    host! "#{tenant.subdomain}.zubio.com.br"

    get client_my_appointments_path

    expect(response).to redirect_to(establishment_path)
  end

  it "lists the signed-in client's upcoming appointment linking to its page" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    professional = create(:professional, tenant: tenant, display_name: "Mary")
    service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45)
    client = create(:client, tenant: tenant, account_linked_at: Time.zone.local(2026, 9, 1, 8, 0))
    appointment = create(:appointment, tenant: tenant, professional: professional, service: service, client: client,
      starts_at: Time.zone.local(2026, 9, 8, 9, 45))
    sign_in_client(client)

    get client_my_appointments_path

    item = Nokogiri::HTML5(response.body).at_css("[data-my-appointment]")
    expect(item["href"]).to eq("/a/#{appointment.cancel_token}?from=list")
    expect(item.text).to include("09:45")
    expect(item.text).to include("45 min")
    expect(item.text).to include("Ter, 8 set")
    expect(item.text).to include("Design de sobrancelhas")
  end

  it "counts the upcoming appointments in the title" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    professional = create(:professional, tenant: tenant, display_name: "Mary")
    service = create(:service, tenant: tenant, duration_minutes: 45)
    client = create(:client, tenant: tenant, account_linked_at: Time.zone.local(2026, 9, 1, 8, 0))
    create(:appointment, tenant: tenant, professional: professional, service: service, client: client,
      starts_at: Time.zone.local(2026, 9, 8, 9, 45))
    create(:appointment, tenant: tenant, professional: professional, service: service, client: client,
      starts_at: Time.zone.local(2026, 10, 3, 14, 0))
    sign_in_client(client)

    get client_my_appointments_path

    expect(response.body).to include("2 próximos")
  end

  it "says one upcoming in the singular" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    professional = create(:professional, tenant: tenant, display_name: "Mary")
    service = create(:service, tenant: tenant, duration_minutes: 45)
    client = create(:client, tenant: tenant, account_linked_at: Time.zone.local(2026, 9, 1, 8, 0))
    create(:appointment, tenant: tenant, professional: professional, service: service, client: client,
      starts_at: Time.zone.local(2026, 9, 8, 9, 45))
    sign_in_client(client)

    get client_my_appointments_path

    expect(response.body).to include("1 próximo")
    expect(response.body).not_to include("1 próximos")
  end

  it "shows the empty state with a way to book when there is nothing upcoming" do
    client = create(:client, tenant: tenant, account_linked_at: Time.zone.local(2026, 9, 1, 8, 0))
    sign_in_client(client)

    get client_my_appointments_path

    page = Nokogiri::HTML5(response.body)
    expect(page.text).to include("Você não tem horários marcados aqui")
    expect(page.text).to include("Marcar um horário")
    expect(page.at_css("[data-rebook-link]")["href"]).to eq(establishment_path)
  end

  it "shows the masked e-mail and a sign-out in the footer" do
    client = create(:client, tenant: tenant, email: "ana@gmail.com", account_linked_at: Time.zone.local(2026, 9, 1, 8, 0))
    sign_in_client(client)

    get client_my_appointments_path

    page = Nokogiri::HTML5(response.body)
    expect(page.text).to include("Você entrou como")
    expect(page.text).to include("a***@gmail.com")
    sign_out_form = page.at_css("form[action='#{client_session_path}']")
    expect(sign_out_form.at_css("button").text).to include("Sair")
    expect(sign_out_form.at_css("input[name='_method'][value='delete']")).to be_present
  end

  it "leaves out an appointment booked before the account without a claim" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    professional = create(:professional, tenant: tenant, display_name: "Mary")
    service = create(:service, tenant: tenant, duration_minutes: 45)
    client = create(:client, tenant: tenant, account_linked_at: Time.zone.local(2026, 9, 8, 8, 0))
    claimed = create(:appointment, tenant: tenant, professional: professional, service: service, client: client,
      starts_at: Time.zone.local(2026, 9, 15, 9, 45), claimed_at: Time.zone.local(2026, 9, 1, 7, 0), created_at: Time.zone.local(2026, 9, 1, 7, 0))
    create(:appointment, tenant: tenant, professional: professional, service: service, client: client,
      starts_at: Time.zone.local(2026, 9, 16, 9, 45), created_at: Time.zone.local(2026, 9, 1, 7, 0))
    sign_in_client(client)

    get client_my_appointments_path

    tokens = Nokogiri::HTML5(response.body).css("[data-my-appointment]").map { |item| item["href"] }
    expect(tokens).to contain_exactly("/a/#{claimed.cancel_token}?from=list")
  end

  it "subscribes to the client appointments stream and asks for a morph refresh" do
    client = create(:client, tenant: tenant, account_linked_at: Time.zone.local(2026, 9, 1, 8, 0))
    sign_in_client(client)

    get client_my_appointments_path

    expect(response.body).to include("<turbo-cable-stream-source")
    expect(response.body).to include(%(<meta name="turbo-refresh-method" content="morph">))
    expect(response.body).to include(%(<meta name="turbo-refresh-scroll" content="preserve">))
  end

  it "never lists another tenant's appointment for the same Google account" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    ze = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
    ze_professional = create(:professional, tenant: ze)
    ze_service = create(:service, tenant: ze, duration_minutes: 45)
    ze_client = create(:client, tenant: ze, google_uid: "g-1", account_linked_at: Time.zone.local(2026, 9, 1, 8, 0))
    create(:appointment, tenant: ze, professional: ze_professional, service: ze_service, client: ze_client, starts_at: Time.zone.local(2026, 9, 15, 9, 45))
    professional = create(:professional, tenant: tenant, display_name: "Mary")
    service = create(:service, tenant: tenant, duration_minutes: 45)
    client = create(:client, tenant: tenant, google_uid: "g-1", account_linked_at: Time.zone.local(2026, 9, 1, 8, 0))
    own = create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: Time.zone.local(2026, 9, 15, 9, 45))
    sign_in_client(client)

    get client_my_appointments_path

    tokens = Nokogiri::HTML5(response.body).css("[data-my-appointment]").map { |item| item["href"] }
    expect(tokens).to contain_exactly("/a/#{own.cancel_token}?from=list")
  end
end
