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

  def menu_item(href)
    %(<a href="#{href}" class="#{Components::Menu::ITEM_CLASS} #{Components::Menu::RESTING_CLASS}">)
  end

  def current_menu_item(href)
    %(<a href="#{href}" aria-current="page" class="#{Components::Menu::ITEM_CLASS} #{Components::Menu::CURRENT_CLASS}">)
  end

  it "offers every destination from the panel, in the band and in the menu" do
    create(:branding, tenant: tenant)
    sign_in

    get owner_dashboard_path

    expect(response.body).to include(band_item(edit_owner_branding_path))
    expect(response.body).to include(%(<a href="#{owner_dashboard_path}" aria-current="page"))
    expect(response.body).to include(current_menu_item(owner_dashboard_path))
    expect(response.body).to include(menu_item(edit_owner_branding_path))
  end

  it "offers the same destinations from the brand screen, which is what persistent means" do
    create(:branding, tenant: tenant)
    sign_in

    get edit_owner_branding_path

    expect(response.body).to include(band_item(owner_dashboard_path))
    expect(response.body).to include(%(<a href="#{edit_owner_branding_path}" aria-current="page"))
    expect(response.body).to include(menu_item(owner_dashboard_path))
    expect(response.body).to include(current_menu_item(edit_owner_branding_path))
  end

  it "marks the panel as current on the panel, and marks nothing else" do
    create(:branding, tenant: tenant)
    sign_in

    get owner_dashboard_path

    expect(response.body).to include(%(<a href="#{owner_dashboard_path}" aria-current="page"))
    expect(response.body).not_to include(%(<a href="#{edit_owner_branding_path}" aria-current="page"))
  end

  it "marks the brand screen as current on the brand screen, and marks nothing else" do
    create(:branding, tenant: tenant)
    sign_in

    get edit_owner_branding_path

    expect(response.body).to include(%(<a href="#{edit_owner_branding_path}" aria-current="page"))
    expect(response.body).not_to include(%(<a href="#{owner_dashboard_path}" aria-current="page"))
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

    expect(signed_in_body).to include("Painel")
    expect(response.body).not_to include("Painel")
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
