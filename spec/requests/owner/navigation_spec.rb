require "rails_helper"

RSpec.describe "Owner panel navigation", type: :request do
  let(:tenant) { create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora") }
  let(:owner) { create(:user, tenant: tenant, name: "Ana Lima", email: "ana@example.com", password: "s3cr3t123") }

  def sign_in
    host! "#{tenant.subdomain}.zubio.com.br"
    post owner_session_path, params: { email: owner.email, password: "s3cr3t123" }
  end

  def band_item(href)
    %(<a href="#{href}" class="#{Components::Owner::Header::ITEM_CLASS} #{Components::Owner::Header::RESTING_CLASS}">)
  end

  def current_band_item(href)
    %(<a href="#{href}" aria-current="page" class="#{Components::Owner::Header::ITEM_CLASS} #{Components::Owner::Header::CURRENT_CLASS}">)
  end

  def menu_item(href)
    %(<a href="#{href}" class="#{Components::Menu::ITEM_CLASS} #{Components::Menu::RESTING_CLASS}">)
  end

  def current_menu_item(href)
    %(<a href="#{href}" aria-current="page" class="#{Components::Menu::ITEM_CLASS} #{Components::Menu::CURRENT_CLASS}">)
  end

  def current_identity = %(<a href="#{owner_dashboard_path}" aria-current="page")

  it "offers settings from the panel, in the band and in the menu, with the identity as the current page" do
    create(:branding, tenant: tenant)
    sign_in

    get owner_dashboard_path

    expect(response.body).to include(current_identity)
    expect(response.body).to include(band_item(owner_settings_path))
    expect(response.body).to include(menu_item(owner_settings_path))
  end

  it "marks settings as current on the settings screen, in the band and in the menu, and the identity no longer" do
    create(:branding, tenant: tenant)
    sign_in

    get owner_settings_path

    expect(response.body).to include(current_band_item(owner_settings_path))
    expect(response.body).to include(current_menu_item(owner_settings_path))
    expect(response.body).not_to include(current_identity)
  end

  it "keeps settings current on the catalog, the service form and the three brand screens, which settings leads to" do
    create(:branding, tenant: tenant)
    sign_in

    bodies = [ owner_services_path, new_owner_service_path, edit_owner_brand_colors_path, edit_owner_brand_name_path, edit_owner_brand_logo_path ].map do |path|
      get path
      response.body
    end

    expect(bodies).to all(include(current_band_item(owner_settings_path)))
    expect(bodies).to all(include(current_menu_item(owner_settings_path)))
    expect(bodies).not_to include(a_string_including(current_identity))
  end

  it "leaves the old sections and every destination without a screen out of the band and the menu" do
    create(:branding, tenant: tenant)
    sign_in

    get owner_dashboard_path

    expect(response.body).to include(band_item(owner_settings_path))
    expect(response.body).to include(%(action="#{owner_session_path}"))
    expect(response.body).not_to include(%(href="#{owner_services_path}"))
    expect(response.body).not_to include(%(href="#{edit_owner_brand_colors_path}"))
    [ "Minha agenda", "Meu link", "Ajuda" ].each { |label| expect(response.body).not_to include(label) }
  end

  it "folds the theme switch and the way out into the menu, where the band has no room" do
    create(:branding, tenant: tenant)
    sign_in

    get owner_dashboard_path

    expect(response.body).to include(Components::Menu::LABEL)
    expect(response.body.scan(%(data-action="theme#toggle")).size).to eq(2)
    expect(response.body.scan(%(action="#{owner_session_path}")).size).to eq(2)
  end

  it "shows the destinations to the owner and none of them to an anonymous visitor" do
    create(:branding, tenant: tenant)
    sign_in
    get owner_dashboard_path
    signed_in_body = response.body

    reset!
    host! "#{tenant.subdomain}.zubio.com.br"
    get owner_dashboard_path
    follow_redirect!

    expect(signed_in_body).to include(Components::Owner::Header::SETTINGS_LABEL)
    expect(response.body).not_to include(Components::Owner::Header::SETTINGS_LABEL)
    expect(response.body).not_to include(Components::Menu::LABEL)
    expect(response.body).not_to include(%(aria-current="page"))
  end

  it "names the establishment in the host on the navigation and never another one" do
    other_tenant = create(:tenant, subdomain: "salon-b", name: "Barbearia do Zé")
    create(:branding, :with_logo, tenant: other_tenant, brand_600: "#DC2626")
    create(:branding, tenant: tenant)
    sign_in

    get owner_dashboard_path

    expect(response.body).to include("Estúdio Aurora")
    expect(response.body).not_to include("Barbearia do Zé")
    expect(response.body).not_to include("/rails/active_storage/representations/proxy/")
  end
end
