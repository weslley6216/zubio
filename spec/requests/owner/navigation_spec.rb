require "rails_helper"

RSpec.describe "Owner panel navigation", type: :request do
  let(:tenant) { create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora") }
  let(:owner) { create(:user, tenant: tenant, name: "Ana Lima", email: "ana@example.com", password: "s3cr3t123") }

  it "offers settings from the panel, in the band and in the menu, with the identity as the current page" do
    create(:branding, tenant: tenant)
    sign_in_owner(owner)

    get owner_dashboard_path

    document = Nokogiri::HTML5(response.body)
    expect(document.at_css("header a[href='#{owner_dashboard_path}']")["aria-current"]).to eq("page")
    expect(document.at_css("header nav a[href='#{owner_settings_path}']")["aria-current"]).to be_nil
    expect(document.at_css("header nav a[href='#{owner_settings_path}']")["class"]).to eq("#{Components::Owner::Header::ITEM_CLASS} #{Components::Owner::Header::RESTING_CLASS}")
    expect(document.at_css("header details a[href='#{owner_settings_path}']")["aria-current"]).to be_nil
  end

  it "drops the band and the menu on the settings hub for a bar back to the panel" do
    create(:branding, tenant: tenant)
    sign_in_owner(owner)

    get owner_settings_path

    document = Nokogiri::HTML5(response.body)
    expect(document.at_css("a[href='#{owner_dashboard_path}']")).to be_present
    expect(document.at_css("header nav")).to be_nil
    expect(document.at_css("header details")).to be_nil
    expect(response.body).not_to include(Components::Owner::Menu::LABEL)
  end

  it "keeps settings current on the catalog, the service form and the three brand screens, which settings leads to" do
    create(:branding, tenant: tenant)
    sign_in_owner(owner)

    documents = [ owner_services_path, new_owner_service_path, edit_owner_brand_colors_path, edit_owner_brand_name_path, edit_owner_brand_logo_path ].map do |path|
      get path
      Nokogiri::HTML5(response.body)
    end

    expect(documents.map { |document| document.at_css("header nav a[href='#{owner_settings_path}']")["aria-current"] }).to all(eq("page"))
    expect(documents.map { |document| document.at_css("header nav a[href='#{owner_settings_path}']")["class"] }).to all(eq("#{Components::Owner::Header::ITEM_CLASS} #{Components::Owner::Header::CURRENT_CLASS}"))
    expect(documents.map { |document| document.at_css("header details a[href='#{owner_settings_path}']")["aria-current"] }).to all(eq("page"))
    expect(documents.map { |document| document.at_css("header a[href='#{owner_dashboard_path}']")["aria-current"] }).to all(be_nil)
  end

  it "leaves the old sections and every destination without a screen out of the band and the menu" do
    create(:branding, tenant: tenant)
    sign_in_owner(owner)

    get owner_dashboard_path

    expect(Nokogiri::HTML5(response.body).at_css("header nav a[href='#{owner_settings_path}']")).to be_present
    expect(response.body).to include(%(action="#{owner_session_path}"))
    expect(response.body).not_to include(%(href="#{owner_services_path}"))
    expect(response.body).not_to include(%(href="#{edit_owner_brand_colors_path}"))
    expect(response.body).not_to include("Minha agenda")
    expect(response.body).not_to include("Meu link")
    expect(response.body).not_to include("Ajuda")
  end

  it "folds the theme switch and the way out into the menu, where the band has no room" do
    create(:branding, tenant: tenant)
    sign_in_owner(owner)

    get owner_dashboard_path

    expect(response.body).to include(Components::Owner::Menu::LABEL)
    expect(response.body.scan(%(data-action="theme#toggle")).size).to eq(2)
    expect(response.body.scan(%(action="#{owner_session_path}")).size).to eq(2)
  end

  it "shows no destination to an anonymous visitor sent to the login" do
    create(:branding, tenant: tenant)
    host! "#{tenant.subdomain}.zubio.com.br"

    get owner_dashboard_path
    follow_redirect!

    expect(response.body).to include(%(action="#{owner_session_path}"))
    expect(response.body).not_to include(Components::Owner::Header::SETTINGS_LABEL)
    expect(response.body).not_to include(Components::Owner::Menu::LABEL)
    expect(response.body).not_to include(%(aria-current="page"))
  end

  it "names the establishment in the host on the navigation and never another one" do
    other_tenant = create(:tenant, subdomain: "salon-b", name: "Barbearia do Zé")
    create(:branding, :with_logo, tenant: other_tenant, brand_600: "#DC2626")
    create(:branding, tenant: tenant)
    sign_in_owner(owner)

    get owner_dashboard_path

    expect(response.body).to include("Estúdio Aurora")
    expect(response.body).not_to include("Barbearia do Zé")
    expect(response.body).not_to include("/rails/active_storage/representations/proxy/")
  end
end
