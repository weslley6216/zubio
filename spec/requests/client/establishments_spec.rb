require "rails_helper"

RSpec.describe "Public establishment showcase", type: :request do
  let(:tenant) { create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora") }

  def visit_showcase(subdomain = tenant.subdomain)
    host! "#{subdomain}.zubio.com.br"
    get root_path
  end

  def catalog_texts = Nokogiri::HTML5(response.body).css("[data-catalog] span").map(&:text)

  def sign_in_owner
    owner = create(:user, tenant: tenant, name: "Ana Lima", email: "ana@example.com", password: "s3cr3t123")
    host! "#{tenant.subdomain}.zubio.com.br"
    post owner_session_path, params: { email: owner.email, password: "s3cr3t123" }
  end

  it "shows the establishment and its active services with duration, with no login screen" do
    create(:service, tenant: tenant, name: "Corte feminino", duration_minutes: 45)
    create(:service, tenant: tenant, name: "Coloração completa", duration_minutes: 120)

    visit_showcase

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Estúdio Aurora")
    expect(response.body).to include("Corte feminino")
    expect(response.body).to include("Coloração completa")
    expect(catalog_texts).to include("45min", "2h")
    expect(response.body).not_to include(%(type="password"))
  end

  it "applies the establishment brand logo and color" do
    branding = create(:branding, :with_logo, tenant: tenant, brand_600: "#1D4ED8")
    create(:service, tenant: tenant, name: "Corte feminino")

    visit_showcase

    expect(response.body).to include("<img")
    expect(response.body).to include(%(href="/branding.css?v=#{branding.stylesheet_digest}"))
  end

  it "falls back to the initial when there is no logo" do
    create(:service, tenant: tenant, name: "Corte feminino")

    visit_showcase

    expect(response.body).to include("data-brand-initial")
    expect(response.body).not_to include("<img")
  end

  it "shows an active service and hides a deactivated one" do
    create(:service, tenant: tenant, name: "Corte feminino", active: true)
    create(:service, tenant: tenant, name: "Pacote antigo", active: false)

    visit_showcase

    expect(response.body).to include("Corte feminino")
    expect(response.body).not_to include("Pacote antigo")
  end

  it "shows a published-nothing message instead of an empty list" do
    create(:service, tenant: tenant, name: "Serviço oculto", active: false)

    visit_showcase

    expect(response.body).to include(Views::Client::Establishments::Show::EMPTY_TITLE)
    expect(response.body).to include(Views::Client::Establishments::Show::EMPTY_BODY)
    expect(response.body).to include("Estúdio Aurora")
    expect(response.body).not_to include("data-catalog")
  end

  it "links each service to the booking entry for that service" do
    corte = create(:service, tenant: tenant, name: "Corte feminino")
    coloracao = create(:service, tenant: tenant, name: "Coloração completa")

    visit_showcase

    expect(response.body).to include(%(href="#{new_client_service_booking_path(corte)}"))
    expect(response.body).to include(%(href="#{new_client_service_booking_path(coloracao)}"))
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
    sign_in_owner

    get owner_dashboard_path

    expect(response).to have_http_status(:ok)
  end

  it "shows the showcase at the root to a signed-in owner, not the panel or a login screen" do
    create(:service, tenant: tenant, name: "Corte feminino")
    sign_in_owner

    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Corte feminino")
    expect(response.body).not_to include(%(type="password"))
  end

  it "shows only the host establishment's services and none from another" do
    other_tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
    create(:service, tenant: other_tenant, name: "Barba do Zé")
    create(:service, tenant: tenant, name: "Corte feminino")

    visit_showcase

    expect(response.body).to include("Corte feminino")
    expect(response.body).not_to include("Barba do Zé")
  end

  it "paints the showcase with brand tokens and never a demo token" do
    create(:service, tenant: tenant, name: "Corte feminino")

    visit_showcase

    expect(response.body).to include("bg-brand-600")
    expect(response.body).to include("text-on-brand")
    expect(response.body).not_to include("demo")
  end

  it "asks the database the same number of times for many services as for one" do
    create(:service, tenant: tenant, name: "Corte feminino")
    visit_showcase
    single = count_queries { get root_path }

    create_list(:service, 4, tenant: tenant)

    expect(single).to be_positive
    expect(count_queries { get root_path }).to eq(single)
  end

  it "serves the showcase to an outdated browser, like the landing does" do
    create(:service, tenant: tenant, name: "Corte feminino")
    outdated_safari = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.3 Safari/605.1.15"
    host! "#{tenant.subdomain}.zubio.com.br"

    get root_path, headers: { "User-Agent" => outdated_safari }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Corte feminino")
  end
end
