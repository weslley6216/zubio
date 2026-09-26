require "rails_helper"

RSpec.describe "Owner settings", type: :request do
  let(:tenant) { create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé") }
  let(:owner) { create(:user, tenant: tenant, name: "José Souza", email: "ze@example.com", password: "s3cr3t123") }

  def sign_in(establishment = tenant, user = owner)
    host! "#{establishment.subdomain}.zubio.com.br"
    post owner_session_path, params: { email: user.email, password: "s3cr3t123" }
  end

  def document = Nokogiri::HTML5(response.body)

  def row(key) = document.at_css(%([data-setting="#{key}"]))

  def summary(key) = row(key).at_css("[data-summary]").text

  def destination(key) = row(key).at_css("a")&.[]("href")

  describe "GET /owner/settings" do
    it "gathers the brand, the service and the account groups, each row with its current value" do
      create(:branding, tenant: tenant, brand_600: "#2C6CB0", brand_secondary_600: "#E8493C")
      create(:service, tenant: tenant)
      create(:service, tenant: tenant)
      create(:service, tenant: tenant, active: false)
      sign_in

      get owner_settings_path

      expect(response).to have_http_status(:ok)
      expect(document.css("main h2").map(&:text)).to eq([
        Views::Owner::Settings::Show::BRAND_GROUP,
        Views::Owner::Settings::Show::SERVICE_GROUP,
        Views::Owner::Settings::Show::ACCOUNT_GROUP
      ])
      expect(summary("name")).to eq("Barbearia do Zé")
      expect(summary("logo")).to eq(Views::Owner::Settings::Show::LOGO_INITIAL)
      expect(row("logo").at_css("img")).to be_nil
      expect(row("logo").css("span").map(&:text)).to include("B")
      expect(summary("colors")).to eq("#2C6CB0 · apoio #E8493C")
      expect(row("colors").to_html).to include("bg-brand-600", "bg-secondary-600")
      expect(summary("address")).to eq("barbearia-do-ze.zubio.com.br")
      expect(summary("services")).to eq("3 cadastrados, 1 desativado")
      expect(row("sign-out").at_css(%(form[action="#{owner_session_path}"]) + " button").text).to eq(Components::Owner::Header::SIGN_OUT_LABEL)
    end

    it "shows the uploaded logo on the logo row instead of the initial" do
      create(:branding, :with_logo, tenant: tenant)
      sign_in

      get owner_settings_path

      expect(summary("logo")).to eq(Views::Owner::Settings::Show::LOGO_UPLOADED)
      expect(row("logo").at_css("img")["src"]).to include("/rails/active_storage/representations/proxy/")
    end

    it "reads a lone brand color in capitals with a single chip when there is no secondary color" do
      create(:branding, tenant: tenant, brand_600: "#7e22ce")
      sign_in

      get owner_settings_path

      expect(summary("colors")).to eq("#7E22CE")
      expect(row("colors").to_html).to include("bg-brand-600")
      expect(row("colors").to_html).not_to include("bg-secondary-600")
    end

    it "reads the platform color for an establishment that never saved a brand" do
      sign_in

      get owner_settings_path

      expect(summary("colors")).to eq(Branding::DEFAULT_BRAND_600)
    end

    it "counts a single registered service in the singular, with no disabled part" do
      create(:service, tenant: tenant)
      sign_in

      get owner_settings_path

      expect(summary("services")).to eq("1 cadastrado")
    end

    it "counts disabled services in the plural" do
      create(:service, tenant: tenant, active: false)
      create(:service, tenant: tenant, active: false)
      sign_in

      get owner_settings_path

      expect(summary("services")).to eq("2 cadastrados, 2 desativados")
    end

    it "says no service is registered when the catalog is empty" do
      sign_in

      get owner_settings_path

      expect(summary("services")).to eq(Views::Owner::Settings::Show::NO_SERVICES)
    end

    it "offers the rows that have a screen and none for a destination without one" do
      sign_in

      get owner_settings_path

      expect(%w[name logo colors address services working_hours sign-out].map { |key| row(key) }).to all(be_present)
      [ "Minha agenda", "Meu link", "Ajuda", "Folgas e feriados",
        "Antecedência mínima", "Meus dados", "Refazer a configuração inicial" ].each do |label|
        expect(response.body).not_to include(label)
      end
    end

    it "takes the name, the logo and the colors to the brand screen, the services to the catalog, and leaves the address as reading only" do
      create(:branding, tenant: tenant)
      sign_in

      get owner_settings_path

      expect(%w[name logo colors].map { |key| destination(key) }).to eq([ edit_owner_brand_name_path, edit_owner_brand_logo_path, edit_owner_brand_colors_path ])
      expect(destination("services")).to eq(owner_services_path)
      expect(destination("working_hours")).to eq(edit_owner_working_hours_path)
      expect(destination("address")).to be_nil
    end

    it "summarizes the weekly schedule on the working-hours row" do
      professional = create(:professional, tenant: tenant, user: owner)
      ActsAsTenant.with_tenant(tenant) { professional.replace_working_hours!((2..6).index_with { [ [ "09:00", "18:00" ] ] }) }
      sign_in

      get owner_settings_path

      expect(summary("working_hours")).to eq("Ter a Sáb, 09:00–18:00")
      expect(destination("working_hours")).to eq(edit_owner_working_hours_path)
    end

    it "reads nothing defined when the owner has a professional but no hours" do
      create(:professional, tenant: tenant, user: owner)
      sign_in

      get owner_settings_path

      expect(summary("working_hours")).to eq(WorkingHour::Summary::NO_HOURS)
    end

    it "still reads nothing defined for an owner without a professional" do
      sign_in

      get owner_settings_path

      expect(summary("working_hours")).to eq(WorkingHour::Summary::NO_HOURS)
    end

    it "sends an anonymous visitor to the login without naming the establishment" do
      create(:branding, tenant: tenant)
      host! "#{tenant.subdomain}.zubio.com.br"

      get owner_settings_path

      expect(response).to redirect_to(new_owner_session_path)

      follow_redirect!

      expect(response.body).not_to include("Barbearia do Zé")
    end

    it "summarizes the name, the colors and the service count of the establishment in the host and nothing of another one" do
      create(:branding, tenant: tenant, brand_600: "#2C6CB0", brand_secondary_600: "#E8493C")
      create_list(:service, 3, tenant: tenant)
      host_professional = create(:professional, tenant: tenant, user: owner)
      ActsAsTenant.with_tenant(tenant) { host_professional.replace_working_hours!(2 => [ [ "07:00", "13:00" ] ]) }
      aurora = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
      aurora_owner = create(:user, tenant: aurora, email: "ana@example.com", password: "s3cr3t123")
      create(:branding, tenant: aurora, brand_600: "#7E22CE")
      create(:service, tenant: aurora)
      ActsAsTenant.with_tenant(aurora) { create(:professional, tenant: aurora, user: aurora_owner) }
      sign_in(aurora, aurora_owner)

      get owner_settings_path

      expect(summary("name")).to eq("Estúdio Aurora")
      expect(summary("colors")).to eq("#7E22CE")
      expect(summary("services")).to eq("1 cadastrado")
      expect(summary("working_hours")).to eq(WorkingHour::Summary::NO_HOURS)
      expect(response.body).not_to include("Barbearia do Zé")
      expect(response.body).not_to include("#2C6CB0")
      expect(response.body).not_to include("#E8493C")
      expect(response.body).not_to include("3 cadastrados")
    end
  end
end
