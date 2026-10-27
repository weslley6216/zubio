require "rails_helper"

RSpec.describe "Client Google sign-in", type: :system, js: true do
  let(:tenant) { create(:tenant, subdomain: "mary", name: "Mary Sombracelhas") }
  let(:service) { create(:service, tenant: tenant, name: "Design de sobrancelhas") }

  before do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    create(:branding, tenant: tenant, brand_600: "#8E4B6B")
    professional = create(:professional, tenant: tenant)
    create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "18:00")
    service
  end

  it "taps a service, offers the gate, and 'no account' reaches the data step" do
    visit "http://#{tenant.subdomain}.zubio.com.br#{establishment_path}"
    click_on service.name

    click_on "Continuar sem conta"

    expect(page).to have_content(Views::Client::Bookings::New::DATA_STEP)
    expect(page).to fit_the_phone_width
  end

  it "shows Google and no-account on the gate a visitor reaches from the showcase" do
    visit "http://#{tenant.subdomain}.zubio.com.br#{establishment_path}"

    click_on service.name

    expect(page).to have_content("Entre para agendar")
    expect(page).to have_link("Continuar com o Google")
    expect(page).to have_link("Continuar sem conta")
    expect(page).to fit_the_phone_width
  end

  it "returns from Google for the first time to the WhatsApp step with the Google name" do
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2", uid: "g-1", info: { email: "ana@gmail.com", name: "Ana Paula Ribeiro" }
    )
    visit "http://#{tenant.subdomain}.zubio.com.br#{new_client_session_path(service_id: service.id)}"

    click_on "Continuar com o Google"

    expect(page).to have_content("Qual é o seu WhatsApp?")
    expect(page).to have_content("Ana Paula Ribeiro")
    expect(page).to fit_the_phone_width
  end

  it "signs in with Google for the first time and reaches day and time" do
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2", uid: "g-1", info: { email: "ana@gmail.com", name: "Ana Paula Ribeiro" }
    )
    visit "http://#{tenant.subdomain}.zubio.com.br#{new_client_session_path(service_id: service.id)}"
    click_on "Continuar com o Google"
    fill_in "phone", with: "11988771234"

    click_on "Continuar"

    expect(page).to have_css("[data-day-selector]")
    expect(page).to fit_the_phone_width
  end

  it "signs a returning Google account straight back in and reaches day and time" do
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2", uid: "g-1", info: { email: "ana@gmail.com", name: "Ana Paula Ribeiro" }
    )
    ActsAsTenant.with_tenant(tenant) { Client.link_google!(uid: "g-1", email: "ana@gmail.com", name: "Ana Paula Ribeiro", phone: "11988771234") }
    visit "http://#{tenant.subdomain}.zubio.com.br#{new_client_session_path(service_id: service.id)}"

    click_on "Continuar com o Google"

    expect(page).to have_css("[data-day-selector]")
    expect(page).to have_no_content("Qual é o seu WhatsApp?")
    expect(page).to fit_the_phone_width
  end

  %w[light dark].each do |scheme|
    it "keeps the sign-in gate readable in #{scheme}" do
      emulate_color_scheme(scheme)

      visit "http://#{tenant.subdomain}.zubio.com.br#{new_client_session_path(service_id: service.id)}"

      expect(opaque?("header")).to be(true)
      expect(contrast_ratio("header")).to be >= Branding::ColorScale::MIN_CONTRAST
      expect(opaque?("[data-google-button]")).to be(true)
      expect(contrast_ratio("[data-google-button]")).to be >= Branding::ColorScale::MIN_CONTRAST
      expect(opaque?("[data-guest-button]")).to be(true)
    end

    it "keeps the WhatsApp step readable in #{scheme}" do
      token = Rails.application.message_verifier(:client_google_identity).generate(
        { "tenant" => tenant.subdomain, "uid" => "g-1", "email" => "ana@gmail.com", "name" => "Ana Paula Ribeiro", "service" => service.id }, expires_in: 15.minutes
      )
      emulate_color_scheme(scheme)

      visit "http://#{tenant.subdomain}.zubio.com.br#{new_client_account_phone_path(token: token)}"

      expect(opaque?("input[type='tel']")).to be(true)
      expect(contrast_ratio("input[type='tel']")).to be >= Branding::ColorScale::MIN_CONTRAST
      expect(opaque?("button[type='submit']")).to be(true)
      expect(contrast_ratio("button[type='submit']")).to be >= Branding::ColorScale::MIN_CONTRAST
    end
  end
end
