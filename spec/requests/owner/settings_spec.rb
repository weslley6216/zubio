require "rails_helper"

RSpec.describe "Owner settings", type: :request do
  let(:tenant) { create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé") }
  let(:owner) { create(:user, tenant: tenant, name: "José Souza", email: "ze@example.com", password: "s3cr3t123") }

  describe "GET /owner/settings" do
    it "tops the hub with a bar back to the panel instead of the panel navigation" do
      create(:branding, tenant: tenant)
      sign_in_owner(owner)

      get owner_settings_path

      document = Nokogiri::HTML5(response.body)
      title = document.at_css("[data-top-bar] [data-top-title]")
      expect(document.at_css("[data-top-bar] a")["href"]).to eq(owner_dashboard_path)
      expect(title.text).to eq(Views::Owner::Settings::Show::TITLE)
      expect(title["class"]).to include("text-base", "font-extrabold")
      expect(response.body).not_to include(Components::Owner::Menu::LABEL)
    end

    it "points the rows that lead to a screen with a chevron and leaves the address reading only" do
      create(:branding, tenant: tenant)
      sign_in_owner(owner)

      get owner_settings_path

      document = Nokogiri::HTML5(response.body)
      expect(document.at_css("[data-setting='name']").to_html).to include(Views::Owner::Settings::Show::CHEVRON_PATH)
      expect(document.at_css("[data-setting='address']").to_html).not_to include(Views::Owner::Settings::Show::CHEVRON_PATH)
    end

    it "gathers the brand, the service and the account groups, each row with its current value" do
      create(:branding, tenant: tenant, brand_600: "#2C6CB0", brand_secondary_600: "#E8493C")
      create(:service, tenant: tenant)
      create(:service, tenant: tenant)
      create(:service, tenant: tenant, active: false)
      sign_in_owner(owner)

      get owner_settings_path

      document = Nokogiri::HTML5(response.body)
      expect(response).to have_http_status(:ok)
      expect(document.css("main h2").map(&:text)).to eq([
        Views::Owner::Settings::Show::BRAND_GROUP,
        Views::Owner::Settings::Show::SERVICE_GROUP,
        Views::Owner::Settings::Show::ACCOUNT_GROUP
      ])
      expect(document.at_css("[data-setting='name'] [data-summary]").text).to eq("Barbearia do Zé")
      expect(document.at_css("[data-setting='logo'] [data-summary]").text).to eq(Views::Owner::Settings::Show::LOGO_INITIAL)
      expect(document.at_css("[data-setting='logo']").at_css("img")).to be_nil
      expect(document.at_css("[data-setting='logo']").css("span").map(&:text)).to include("B")
      expect(document.at_css("[data-setting='colors'] [data-summary]").text).to eq("#2C6CB0 · apoio #E8493C")
      expect(document.at_css("[data-setting='colors']").to_html).to include("bg-brand-600", "bg-secondary-600")
      expect(document.at_css("[data-setting='address'] [data-summary]").text).to eq("barbearia-do-ze.zubio.com.br")
      expect(document.at_css("[data-setting='services'] [data-summary]").text).to eq("3 cadastrados, 1 desativado")
      expect(document.at_css("[data-setting='sign-out']").at_css(%(form[action="#{owner_session_path}"]) + " button").text).to eq(Components::Owner::Header::SIGN_OUT_LABEL)
    end

    it "shows the uploaded logo on the logo row instead of the initial" do
      create(:branding, :with_logo, tenant: tenant)
      sign_in_owner(owner)

      get owner_settings_path

      document = Nokogiri::HTML5(response.body)
      expect(document.at_css("[data-setting='logo'] [data-summary]").text).to eq(Views::Owner::Settings::Show::LOGO_UPLOADED)
      expect(document.at_css("[data-setting='logo']").at_css("img")["src"]).to include("/rails/active_storage/representations/proxy/")
    end

    it "reads a lone brand color in capitals with a single chip when there is no secondary color" do
      create(:branding, tenant: tenant, brand_600: "#7e22ce")
      sign_in_owner(owner)

      get owner_settings_path

      document = Nokogiri::HTML5(response.body)
      expect(document.at_css("[data-setting='colors'] [data-summary]").text).to eq("#7E22CE")
      expect(document.at_css("[data-setting='colors']").to_html).to include("bg-brand-600")
      expect(document.at_css("[data-setting='colors']").to_html).not_to include("bg-secondary-600")
    end

    it "reads the platform color for an establishment that never saved a brand" do
      sign_in_owner(owner)

      get owner_settings_path

      document = Nokogiri::HTML5(response.body)
      expect(document.at_css("[data-setting='colors'] [data-summary]").text).to eq(Branding::DEFAULT_BRAND_600)
    end

    it "counts a single registered service in the singular, with no disabled part" do
      create(:service, tenant: tenant)
      sign_in_owner(owner)

      get owner_settings_path

      document = Nokogiri::HTML5(response.body)
      expect(document.at_css("[data-setting='services'] [data-summary]").text).to eq("1 cadastrado")
    end

    it "counts disabled services in the plural" do
      create(:service, tenant: tenant, active: false)
      create(:service, tenant: tenant, active: false)
      sign_in_owner(owner)

      get owner_settings_path

      document = Nokogiri::HTML5(response.body)
      expect(document.at_css("[data-setting='services'] [data-summary]").text).to eq("2 cadastrados, 2 desativados")
    end

    it "says no service is registered when the catalog is empty" do
      sign_in_owner(owner)

      get owner_settings_path

      document = Nokogiri::HTML5(response.body)
      expect(document.at_css("[data-setting='services'] [data-summary]").text).to eq(Views::Owner::Settings::Show::NO_SERVICES)
    end

    it "offers the rows that have a screen and none for a destination without one" do
      sign_in_owner(owner)

      get owner_settings_path

      document = Nokogiri::HTML5(response.body)
      expect(document.css("[data-setting]").map { |row| row["data-setting"] })
        .to contain_exactly("name", "logo", "colors", "address", "services", "working_hours", "schedule_exceptions", "sign-out")
      expect(response.body).not_to include("Minha agenda")
      expect(response.body).not_to include("Meu link")
      expect(response.body).not_to include("Ajuda")
      expect(response.body).not_to include("Antecedência mínima")
      expect(response.body).not_to include("Meus dados")
      expect(response.body).not_to include("Refazer a configuração inicial")
    end

    it "takes the name, the logo and the colors to the brand screen, the services to the catalog, and leaves the address as reading only" do
      create(:branding, tenant: tenant)
      sign_in_owner(owner)

      get owner_settings_path

      document = Nokogiri::HTML5(response.body)
      expect(%w[name logo colors].map { |key| document.at_css("[data-setting='#{key}'] a")["href"] }).to eq([ edit_owner_brand_name_path, edit_owner_brand_logo_path, edit_owner_brand_colors_path ])
      expect(document.at_css("[data-setting='services'] a")["href"]).to eq(owner_services_path)
      expect(document.at_css("[data-setting='working_hours'] a")["href"]).to eq(edit_owner_working_hours_path)
      expect(document.at_css("[data-setting='address'] a")).to be_nil
    end

    it "summarizes the weekly schedule on the working-hours row" do
      professional = create(:professional, tenant: tenant, user: owner)
      ActsAsTenant.with_tenant(tenant) { professional.replace_working_hours!((2..6).index_with { [ [ "09:00", "18:00" ] ] }) }
      sign_in_owner(owner)

      get owner_settings_path

      document = Nokogiri::HTML5(response.body)
      expect(document.at_css("[data-setting='working_hours'] [data-summary]").text).to eq("Ter a Sáb, 09:00–18:00")
      expect(document.at_css("[data-setting='working_hours'] a")["href"]).to eq(edit_owner_working_hours_path)
    end

    it "reads nothing defined when the owner has a professional but no hours" do
      create(:professional, tenant: tenant, user: owner)
      sign_in_owner(owner)

      get owner_settings_path

      document = Nokogiri::HTML5(response.body)
      expect(document.at_css("[data-setting='working_hours'] [data-summary]").text).to eq(WorkingHour::Summary::NO_HOURS)
    end

    it "still reads nothing defined for an owner without a professional" do
      sign_in_owner(owner)

      get owner_settings_path

      document = Nokogiri::HTML5(response.body)
      expect(document.at_css("[data-setting='working_hours'] [data-summary]").text).to eq(WorkingHour::Summary::NO_HOURS)
    end

    it "lists holidays and time off under the service group, with a count and a chevron" do
      professional = ActsAsTenant.with_tenant(tenant) { create(:professional, tenant: tenant, user: owner) }
      ActsAsTenant.with_tenant(tenant) do
        create(:schedule_exception, tenant: tenant, professional: professional, occurs_on: Date.current.next_week(:monday))
        create(:schedule_exception, tenant: tenant, professional: professional, occurs_on: Date.current.next_week(:tuesday))
      end
      sign_in_owner(owner)

      get owner_settings_path

      document = Nokogiri::HTML5(response.body)
      expect(document.at_css("[data-setting='schedule_exceptions'] a")["href"]).to eq(owner_schedule_exceptions_path)
      expect(document.at_css("[data-setting='schedule_exceptions'] [data-summary]").text).to eq("2 próximas")
      expect(document.at_css("[data-setting='schedule_exceptions']").to_html).to include(Views::Owner::Settings::Show::CHEVRON_PATH)
    end

    it "summarizes holidays as none when there is nothing upcoming" do
      ActsAsTenant.with_tenant(tenant) { create(:professional, tenant: tenant, user: owner) }
      sign_in_owner(owner)

      get owner_settings_path

      document = Nokogiri::HTML5(response.body)
      expect(document.at_css("[data-setting='schedule_exceptions'] [data-summary]").text).to eq(Views::Owner::Settings::Show::NO_EXCEPTIONS)
    end

    it "sends an anonymous visitor to the login" do
      create(:branding, tenant: tenant)
      host! "#{tenant.subdomain}.zubio.com.br"

      get owner_settings_path

      expect(response).to redirect_to(new_owner_session_path)
    end

    it "names nothing of the establishment on the login an anonymous visitor lands on" do
      create(:branding, tenant: tenant)
      host! "#{tenant.subdomain}.zubio.com.br"

      get owner_settings_path
      follow_redirect!

      expect(response.body).to include(%(action="#{owner_session_path}"))
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
      sign_in_owner(aurora_owner)

      get owner_settings_path

      document = Nokogiri::HTML5(response.body)
      expect(document.at_css("[data-setting='name'] [data-summary]").text).to eq("Estúdio Aurora")
      expect(document.at_css("[data-setting='colors'] [data-summary]").text).to eq("#7E22CE")
      expect(document.at_css("[data-setting='services'] [data-summary]").text).to eq("1 cadastrado")
      expect(document.at_css("[data-setting='working_hours'] [data-summary]").text).to eq(WorkingHour::Summary::NO_HOURS)
      expect(response.body).not_to include("Barbearia do Zé")
      expect(response.body).not_to include("#2C6CB0")
      expect(response.body).not_to include("#E8493C")
      expect(response.body).not_to include("3 cadastrados")
    end
  end
end
