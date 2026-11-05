require "rails_helper"

RSpec.describe "Public establishment showcase", type: :request do
  let(:tenant) { create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora") }

  it "shows the establishment and its active services with duration, with no login screen" do
    create(:service, tenant: tenant, name: "Corte feminino", duration_minutes: 45)
    create(:service, tenant: tenant, name: "Coloração completa", duration_minutes: 120)
    host! "#{tenant.subdomain}.zubio.com.br"

    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Estúdio Aurora")
    expect(response.body).to include("Corte feminino")
    expect(response.body).to include("Coloração completa")
    expect(Nokogiri::HTML5(response.body).css("[data-catalog] span").map(&:text)).to include("45 min", "2h")
    expect(response.body).not_to include(%(type="password"))
  end

  it "offers the client the booking links and no entry to the owner panel" do
    service = create(:service, tenant: tenant, name: "Corte feminino")
    host! "#{tenant.subdomain}.zubio.com.br"

    get root_path

    links = Nokogiri::HTML5(response.body).css("a").map { |link| link["href"] }
    expect(links).to include(new_client_session_path(service_id: service.id))
    expect(links).not_to include(new_owner_session_path)
  end

  it "applies the establishment brand logo and color" do
    branding = create(:branding, :with_logo, tenant: tenant, brand_600: "#1D4ED8")
    create(:service, tenant: tenant, name: "Corte feminino")
    host! "#{tenant.subdomain}.zubio.com.br"

    get root_path

    expect(response.body).to include("<img")
    expect(response.body).to include(%(href="/branding.css?v=#{branding.stylesheet_digest}"))
  end

  it "falls back to the initial when there is no logo" do
    create(:service, tenant: tenant, name: "Corte feminino")
    host! "#{tenant.subdomain}.zubio.com.br"

    get root_path

    expect(response.body).to include("data-brand-initial")
    expect(response.body).to include("(--theme-bg-tint)")
    expect(response.body).not_to include("<img")
  end

  it "shows an active service and hides a deactivated one" do
    create(:service, tenant: tenant, name: "Corte feminino", active: true)
    create(:service, tenant: tenant, name: "Pacote antigo", active: false)
    host! "#{tenant.subdomain}.zubio.com.br"

    get root_path

    expect(response.body).to include("Corte feminino")
    expect(response.body).not_to include("Pacote antigo")
  end

  it "shows a published-nothing message instead of an empty list" do
    create(:service, tenant: tenant, name: "Serviço oculto", active: false)
    host! "#{tenant.subdomain}.zubio.com.br"

    get root_path

    expect(response.body).to include(Views::Client::Establishments::Show::EMPTY_TITLE)
    expect(response.body).to include(Views::Client::Establishments::Show::EMPTY_BODY)
    expect(response.body).to include("Estúdio Aurora")
    expect(response.body).not_to include("data-catalog")
  end

  it "links a service card to the sign-in gate for a visitor" do
    service = create(:service, tenant: tenant, name: "Corte feminino")
    host! "#{tenant.subdomain}.zubio.com.br"

    get root_path

    expect(response.body).to include(%(href="#{new_client_session_path(service_id: service.id)}"))
  end

  it "links a service card straight to booking for a signed-in client" do
    service = create(:service, tenant: tenant, name: "Corte feminino")
    client = create(:client, tenant: tenant)
    host! "#{tenant.subdomain}.zubio.com.br"
    sign_in_client(client)

    get root_path

    expect(response.body).to include(%(href="#{new_client_service_booking_path(service)}"))
  end

  it "answers 404 for an unknown subdomain, leaking no establishment name" do
    create(:service, tenant: tenant, name: "Corte feminino")
    host! "does-not-exist.zubio.com.br"

    get root_path

    expect(response).to have_http_status(:not_found)
    expect(response.body).not_to include("Estúdio Aurora")
  end

  it "answers 404 for a suspended establishment" do
    create(:tenant, subdomain: "suspended-salon", name: "Salão Suspenso", status: "suspended")
    host! "suspended-salon.zubio.com.br"

    get root_path

    expect(response).to have_http_status(:not_found)
  end

  it "keeps the owner dashboard reachable" do
    sign_in_owner(create(:user, tenant: tenant))

    get owner_appointments_path

    expect(response).to have_http_status(:ok)
  end

  it "shows the showcase at the root to a signed-in owner, not the panel or a login screen" do
    create(:service, tenant: tenant, name: "Corte feminino")
    sign_in_owner(create(:user, tenant: tenant))

    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Corte feminino")
    expect(response.body).not_to include(%(type="password"))
  end

  it "shows only the host establishment's services and none from another" do
    other_tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
    create(:service, tenant: other_tenant, name: "Barba do Zé")
    create(:service, tenant: tenant, name: "Corte feminino")
    host! "#{tenant.subdomain}.zubio.com.br"

    get root_path

    expect(response.body).to include("Corte feminino")
    expect(response.body).not_to include("Barba do Zé")
  end

  it "paints the showcase with theme tokens and never a demo token" do
    create(:service, tenant: tenant, name: "Corte feminino")
    host! "#{tenant.subdomain}.zubio.com.br"

    get root_path

    expect(response.body).to include("(--theme-bg)")
    expect(response.body).to include("(--theme-card)")
    expect(response.body).not_to include("demo")
  end

  it "shows the amount of a service whose price is visible" do
    create(:service, tenant: tenant, name: "Corte feminino", price_cents: 9_000)
    host! "#{tenant.subdomain}.zubio.com.br"

    get root_path

    expect(Nokogiri::HTML5(response.body).css("[data-catalog] span").map(&:text)).to include("R$ 90")
  end

  it "hides the amount of a hidden-price service, showing sob consulta with the amount nowhere in the response" do
    create(:service, :price_hidden, tenant: tenant, name: "Primeira sessão", price_cents: 9_000)
    host! "#{tenant.subdomain}.zubio.com.br"

    get root_path

    expect(response.body).to include(Service::Price::UNPRICED_LABEL)
    expect(response.body).not_to include("90,00")
  end

  it "renders sob consulta in the muted token that follows the light and dark themes" do
    create(:service, :price_hidden, tenant: tenant, name: "Primeira sessão", price_cents: 9_000)
    host! "#{tenant.subdomain}.zubio.com.br"

    get root_path

    expect(response.body).to include(Views::Client::Establishments::Show::UNPRICED_CLASS)
  end

  it "keeps the host's hidden price out of its response even when another establishment shows the same one" do
    other_tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
    create(:service, tenant: other_tenant, name: "Primeira sessão", price_cents: 9_000)
    create(:service, :price_hidden, tenant: tenant, name: "Primeira sessão", price_cents: 9_000)
    host! "#{tenant.subdomain}.zubio.com.br"

    get root_path

    expect(response.body).to include(Service::Price::UNPRICED_LABEL)
    expect(response.body).not_to include("90,00")
  end

  it "asks the database the same number of times for many services as for one" do
    create(:service, tenant: tenant, name: "Corte feminino")
    host! "#{tenant.subdomain}.zubio.com.br"
    get root_path
    single = count_queries { get root_path }
    create_list(:service, 4, tenant: tenant)

    many = count_queries { get root_path }

    expect(single).to be_positive
    expect(many).to eq(single)
  end

  it "serves the showcase to an outdated browser, like the landing does" do
    create(:service, tenant: tenant, name: "Corte feminino")
    outdated_safari = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.3 Safari/605.1.15"
    host! "#{tenant.subdomain}.zubio.com.br"

    get root_path, headers: { "User-Agent" => outdated_safari }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Corte feminino")
  end

  it "announces the establishment's name, an online-booking line, its logo and its canonical address" do
    create(:branding, :with_logo, tenant: tenant)
    host! "#{tenant.subdomain}.zubio.com.br"

    get root_path

    head = Nokogiri::HTML5(response.body)
    expect(head.at_css('meta[property="og:title"]')["content"]).to eq("Estúdio Aurora")
    expect(head.at_css('meta[property="og:description"]')["content"]).to eq("Agende seu horário online — Estúdio Aurora.")
    expect(head.at_css('meta[property="og:image"]')).not_to be_nil
    expect(head.at_css('meta[property="og:url"]')["content"]).to eq("http://estudio-aurora.zubio.com.br/")
  end

  it "gives the preview an absolute image and address on the establishment's own host" do
    create(:branding, :with_logo, tenant: tenant)
    host! "#{tenant.subdomain}.zubio.com.br"

    get root_path

    head = Nokogiri::HTML5(response.body)
    expect(head.at_css('meta[property="og:url"]')["content"]).to start_with("http://estudio-aurora.zubio.com.br")
    expect(head.at_css('meta[property="og:image"]')["content"]).to start_with("http://estudio-aurora.zubio.com.br")
  end

  it "keeps the preview's title and description but announces no image when there is no logo" do
    host! "#{tenant.subdomain}.zubio.com.br"

    get root_path

    head = Nokogiri::HTML5(response.body)
    expect(head.at_css('meta[property="og:title"]')["content"]).to eq("Estúdio Aurora")
    expect(head.at_css('meta[property="og:description"]')["content"]).to eq("Agende seu horário online — Estúdio Aurora.")
    expect(head.at_css('meta[property="og:image"]')).to be_nil
  end

  it "announces nothing to share on the owner's authenticated screens" do
    sign_in_owner(create(:user, tenant: tenant))

    get owner_appointments_path

    expect(response).to have_http_status(:ok)
    expect(Nokogiri::HTML5(response.body).css('meta[property^="og:"]')).to be_empty
  end

  it "announces only the host establishment and nothing of another in the preview" do
    create(:branding, :with_logo, tenant: tenant)
    other_tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
    create(:branding, :with_logo, tenant: other_tenant)
    host! "#{tenant.subdomain}.zubio.com.br"

    get root_path

    head = Nokogiri::HTML5(response.body)
    expect(head.at_css('meta[property="og:title"]')["content"]).to eq("Estúdio Aurora")
    expect(head.at_css('meta[property="og:url"]')["content"]).to include("estudio-aurora.zubio.com.br")
    expect(response.body).not_to include("Barbearia do Zé")
    expect(response.body).not_to include("barbearia-do-ze.zubio.com.br")
  end

  it "shows the professional's week as one line beside the name" do
    professional = create(:professional, tenant: tenant)
    (2..6).each { |weekday| create(:working_hour, tenant: tenant, professional: professional, weekday: weekday, opens_at: "09:00", closes_at: "18:00") }
    create(:service, tenant: tenant, name: "Corte feminino")
    host! "#{tenant.subdomain}.zubio.com.br"

    get root_path

    expect(Nokogiri::HTML5(response.body).at_css("[data-opening-hours]").text).to eq("Ter a Sáb · 09:00–18:00")
  end

  it "shows no week line when the establishment has no professional yet" do
    create(:service, tenant: tenant, name: "Corte feminino")
    host! "#{tenant.subdomain}.zubio.com.br"

    get root_path

    expect(response.body).not_to include("data-opening-hours")
    expect(response.body).to include("Corte feminino")
  end

  it "keeps another tenant's working hours out of the host's week line" do
    other_tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
    other_professional = create(:professional, tenant: other_tenant)
    create(:working_hour, tenant: other_tenant, professional: other_professional, weekday: 1, opens_at: "09:00", closes_at: "20:00")
    professional = create(:professional, tenant: tenant)
    create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "18:00")
    create(:service, tenant: tenant, name: "Corte feminino")
    host! "#{tenant.subdomain}.zubio.com.br"

    get root_path

    expect(Nokogiri::HTML5(response.body).at_css("[data-opening-hours]").text).to eq("Ter · 09:00–18:00")
    expect(response.body).not_to include("20:00")
  end

  it "shows the sheet's title and subtitle above the service list" do
    create(:service, tenant: tenant, name: "Corte feminino")
    host! "#{tenant.subdomain}.zubio.com.br"

    get root_path

    expect(response.body).to include(Views::Client::Establishments::Show::TITLE)
    expect(response.body).to include(Views::Client::Establishments::Show::SUBTITLE)
  end

  it "shows no sheet title when there are no services to choose from" do
    host! "#{tenant.subdomain}.zubio.com.br"

    get root_path

    expect(response.body).not_to include(Views::Client::Establishments::Show::TITLE)
  end

  it "shows a service's description, duration in minutes and its short price" do
    create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45, price_cents: 6_000,
      description: "Medição, limpeza e finalização")
    host! "#{tenant.subdomain}.zubio.com.br"

    get root_path

    expect(Nokogiri::HTML5(response.body).css("[data-catalog] [data-description]").map(&:text)).to include("Medição, limpeza e finalização")
    expect(response.body).to include("45 min")
    expect(response.body).to include("R$ 60")
  end

  it "shows Sob consulta for a service with no fixed price, and the price for one that has it" do
    create(:service, :price_hidden, tenant: tenant, name: "Retoque de henna", price_cents: 4_000)
    create(:service, tenant: tenant, name: "Corte feminino", price_cents: 9_000)
    host! "#{tenant.subdomain}.zubio.com.br"

    get root_path

    expect(response.body).to include(Service::Price::UNPRICED_LABEL)
    expect(response.body).to include("R$ 90")
  end

  it "shows the my-appointments button announced for screen readers to any visitor" do
    host! "#{tenant.subdomain}.zubio.com.br"

    get root_path

    expect(response.body).to include('aria-label="Meus agendamentos"')
    expect(response.body).to include("Meus horários")
    expect(response.body).to include(%(href="#{new_client_session_path}"))
    expect(response.body).not_to include("data-my-appointments-badge")
  end

  it "badges the button with the number of upcoming appointments for a signed-in client" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant)
    client = create(:client, tenant: tenant, account_linked_at: Time.zone.local(2026, 9, 1, 8, 0))
    create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: Time.zone.local(2026, 9, 15, 9, 45))
    create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: Time.zone.local(2026, 9, 16, 9, 45))
    host! "#{tenant.subdomain}.zubio.com.br"
    sign_in_client(client)

    get root_path

    expect(response.body).to include('aria-label="Meus agendamentos, 2 próximos"')
    expect(Nokogiri::HTML5(response.body).at_css("[data-my-appointments-badge]").text).to eq("2")
    expect(response.body).to include(%(href="#{client_my_appointments_path}"))
  end

  it "says one upcoming in the singular on the badge aria-label" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant)
    client = create(:client, tenant: tenant, account_linked_at: Time.zone.local(2026, 9, 1, 8, 0))
    create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: Time.zone.local(2026, 9, 15, 9, 45))
    host! "#{tenant.subdomain}.zubio.com.br"
    sign_in_client(client)

    get root_path

    expect(response.body).to include('aria-label="Meus agendamentos, 1 próximo"')
    expect(response.body).not_to include("1 próximos")
  end

  it "shows no badge for a signed-in client with nothing upcoming" do
    client = create(:client, tenant: tenant, account_linked_at: Time.zone.local(2026, 9, 1, 8, 0))
    host! "#{tenant.subdomain}.zubio.com.br"
    sign_in_client(client)

    get root_path

    expect(response.body).not_to include("data-my-appointments-badge")
    expect(response.body).to include(%(href="#{client_my_appointments_path}"))
  end

  it "counts only the host tenant's appointments in the badge" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    other_tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
    other_professional = create(:professional, tenant: other_tenant)
    other_service = create(:service, tenant: other_tenant)
    other_client = create(:client, tenant: other_tenant, google_uid: "g-1", account_linked_at: Time.zone.local(2026, 9, 1, 8, 0))
    create(:appointment, tenant: other_tenant, professional: other_professional, service: other_service, client: other_client, starts_at: Time.zone.local(2026, 9, 15, 9, 45))
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant)
    client = create(:client, tenant: tenant, google_uid: "g-1", account_linked_at: Time.zone.local(2026, 9, 1, 8, 0))
    create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: Time.zone.local(2026, 9, 15, 9, 45))
    create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: Time.zone.local(2026, 9, 16, 9, 45))
    host! "#{tenant.subdomain}.zubio.com.br"
    sign_in_client(client)

    get root_path

    expect(Nokogiri::HTML5(response.body).at_css("[data-my-appointments-badge]").text).to eq("2")
  end

  it "shows the Google sign-in failure alert when the visitor is bounced back from a failed sign-in" do
    create(:service, tenant: tenant, name: "Corte feminino")
    host! "#{tenant.subdomain}.zubio.com.br"

    get root_path(signin: "failed")

    expect(response.body).to include("Não foi possível entrar com o Google. Tente de novo.")
  end

  it "shows no sign-in failure alert on a plain visit" do
    create(:service, tenant: tenant, name: "Corte feminino")
    host! "#{tenant.subdomain}.zubio.com.br"

    get root_path

    expect(response.body).not_to include("Não foi possível entrar com o Google. Tente de novo.")
  end

  it "offers the install invite to an anonymous visitor, gated by a prior visit mark" do
    create(:service, tenant: tenant, name: "Corte feminino")
    host! "#{tenant.subdomain}.zubio.com.br"

    get root_path

    fragment = Nokogiri::HTML5.fragment(response.body)
    invite = fragment.at_css("[data-controller='pwa-install']")
    expect(invite["data-pwa-install-require-visit-value"]).not_to be_nil
  end

  it "offers the install invite to a signed-in client without the visit gate and with a standalone path" do
    create(:service, tenant: tenant, name: "Corte feminino")
    client = create(:client, tenant: tenant)
    host! "#{tenant.subdomain}.zubio.com.br"
    sign_in_client(client)

    get root_path

    fragment = Nokogiri::HTML5.fragment(response.body)
    invite = fragment.at_css("[data-controller='pwa-install']")
    expect(invite["data-pwa-install-require-visit-value"]).to be_nil
    expect(invite["data-pwa-install-standalone-path-value"]).to eq(client_app_installation_path)
  end

  it "does not offer the install invite to a signed-in client who already installed the app" do
    create(:service, tenant: tenant, name: "Corte feminino")
    client = create(:client, tenant: tenant)
    client.record_app_installation!
    host! "#{tenant.subdomain}.zubio.com.br"
    sign_in_client(client)

    get root_path

    expect(response.body).not_to include("data-controller=\"pwa-install\"")
  end

  it "shows a logo-less host its own initial and serves no other tenant's emblem image" do
    create(:branding, :with_wide_logo, tenant: create(:tenant, subdomain: "mary-sombracelhas", name: "Mary Sombracelhas"))
    create(:service, tenant: tenant, name: "Corte feminino")
    host! "#{tenant.subdomain}.zubio.com.br"

    get root_path

    expect(response.body).to include("data-brand-initial")
    expect(response.body).not_to include("<img")
  end

  it "does not wire the showcase to another tenant's theme stylesheet" do
    ze = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
    ze_branding = create(:branding, :with_background, tenant: ze)
    create(:service, tenant: ze, name: "Corte")
    mary = create(:tenant, subdomain: "mary-sombracelhas", name: "Mary Sombracelhas")
    mary_branding = create(:branding, tenant: mary)
    create(:service, tenant: mary, name: "Design de sobrancelhas")

    host! "mary-sombracelhas.zubio.com.br"
    get root_path
    mary_href = Nokogiri::HTML5(response.body).at_css("link[href*='branding.css']")["href"]

    host! "barbearia-do-ze.zubio.com.br"
    get root_path
    ze_href = Nokogiri::HTML5(response.body).at_css("link[href*='branding.css']")["href"]

    expect(mary_href).to include(mary_branding.stylesheet_digest)
    expect(ze_href).to include(ze_branding.stylesheet_digest)
    expect(mary_href).not_to eq(ze_href)
  end
end
