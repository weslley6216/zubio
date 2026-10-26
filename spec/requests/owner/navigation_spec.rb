require "rails_helper"

RSpec.describe "Owner panel navigation", type: :request do
  let(:tenant) { create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora") }
  let(:owner) { create(:user, :with_professional, tenant: tenant, name: "Ana Lima", email: "ana@example.com", password: "s3cr3t123") }

  it "marks the agenda tab current on the panel, not the brand link" do
    create(:branding, tenant: tenant)
    sign_in_owner(owner)

    get owner_appointments_path

    document = Nokogiri::HTML5(response.body)
    expect(document.at_css("[data-owner-band] nav a[href='#{owner_appointments_path}']")["aria-current"]).to eq("page")
    expect(document.at_css("[data-owner-band] > a[href='#{owner_appointments_path}']")["aria-current"]).to be_nil
    expect(document.at_css("[data-owner-band] a[href='#{owner_settings_path}']")["aria-current"]).to be_nil
  end

  it "marks serviços on the catalog and the service form" do
    create(:branding, tenant: tenant)
    sign_in_owner(owner)

    documents = [ owner_services_path, new_owner_service_path ].map do |path|
      get path
      Nokogiri::HTML5(response.body)
    end

    expect(documents.map { |document| document.at_css("[data-owner-band] nav a[href='#{owner_services_path}']")["aria-current"] }).to all(eq("page"))
    expect(documents.map { |document| document.at_css("[data-owner-band] a[href='#{owner_settings_path}']")["aria-current"] }).to all(be_nil)
  end

  it "marks horários on the expediente and on the folgas" do
    create(:branding, tenant: tenant)
    sign_in_owner(owner)

    [ edit_owner_working_hours_path, owner_schedule_exceptions_path ].each do |path|
      get path

      current_links = Nokogiri::HTML5(response.body).css("[data-owner-band] a[aria-current='page']")
      expect(current_links.map { |link| link["href"] }).to eq([ edit_owner_working_hours_path ])
    end
  end

  it "keeps configurações current on the three brand screens" do
    create(:branding, tenant: tenant)
    sign_in_owner(owner)

    documents = [ edit_owner_brand_colors_path, edit_owner_brand_name_path, edit_owner_brand_logo_path ].map do |path|
      get path
      Nokogiri::HTML5(response.body)
    end

    documents.each do |document|
      pill = document.at_css("[data-owner-band] a[href='#{owner_settings_path}']")
      expect(pill["aria-current"]).to eq("page")
      expect(pill["class"]).to eq("#{Components::Owner::Header::PILL_CLASS} #{Components::Owner::Header::PILL_CURRENT_CLASS}")
    end
  end

  it "drops the band and the menu on the settings hub" do
    create(:branding, tenant: tenant)
    sign_in_owner(owner)

    get owner_settings_path

    document = Nokogiri::HTML5(response.body)
    expect(document.at_css("a[href='#{owner_appointments_path}']")).to be_present
    expect(document.at_css("header nav")).to be_nil
    expect(document.at_css("header details")).to be_nil
    expect(response.body).not_to include(Components::Owner::Menu::LABEL)
  end

  it "keeps sair out of the band and only in the menu" do
    create(:branding, tenant: tenant)
    sign_in_owner(owner)

    get owner_appointments_path

    document = Nokogiri::HTML5(response.body)
    expect(document.at_css("[data-owner-band]").to_s).not_to include(%(action="#{owner_session_path}"))
    expect(response.body.scan(%(action="#{owner_session_path}")).size).to eq(1)
  end

  it "keeps serviços and horários out of the phone menu" do
    create(:branding, tenant: tenant)
    sign_in_owner(owner)

    get owner_appointments_path

    document = Nokogiri::HTML5(response.body)
    expect(document.at_css("header details a[href='#{owner_services_path}']")).to be_nil
    expect(document.at_css("header details a[href='#{edit_owner_working_hours_path}']")).to be_nil
    expect(document.at_css("header details a[href='#{owner_clients_path}']")).to be_present
    expect(document.at_css("header details a[href='#{owner_settings_path}']")).to be_present
  end

  it "folds the theme switch into the band and the menu" do
    create(:branding, tenant: tenant)
    sign_in_owner(owner)

    get owner_appointments_path

    expect(response.body.scan(%(data-action="theme#toggle")).size).to eq(2)
  end

  it "shows no destination to an anonymous visitor sent to the login" do
    create(:branding, tenant: tenant)
    host! "#{tenant.subdomain}.zubio.com.br"

    get owner_appointments_path
    follow_redirect!

    expect(response.body).to include(%(action="#{owner_session_path}"))
    expect(response.body).not_to include(Components::Owner::Header::SETTINGS_LABEL)
    expect(response.body).not_to include(Components::Owner::Menu::LABEL)
    expect(response.body).not_to include(%(aria-current="page"))
  end

  it "names the current section under the establishment name" do
    create(:branding, tenant: tenant)
    sign_in_owner(owner)

    expectations = {
      owner_appointments_path => "Agenda",
      owner_services_path => "Serviços",
      edit_owner_working_hours_path => "Horários",
      owner_schedule_exceptions_path => "Horários · Exceções",
      edit_owner_brand_name_path => "Minha marca"
    }

    expectations.each do |path, subtitle|
      get path
      expect(Nokogiri::HTML5(response.body).at_css("[data-panel-subtitle]").text).to eq(subtitle)
    end
  end

  it "names the establishment in the host on the navigation and never another one" do
    other_tenant = create(:tenant, subdomain: "salon-b", name: "Barbearia do Zé")
    create(:branding, :with_logo, tenant: other_tenant, brand_600: "#DC2626")
    create(:branding, tenant: tenant)
    sign_in_owner(owner)

    get owner_appointments_path

    expect(response.body).to include("Estúdio Aurora")
    expect(response.body).not_to include("Barbearia do Zé")
    expect(response.body).not_to include("/rails/active_storage/representations/proxy/")
  end
end
