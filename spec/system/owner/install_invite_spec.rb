require "rails_helper"

RSpec.describe "Owner install invite", type: :system, js: true do
  let(:tenant) { create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora") }
  let(:owner) { create(:user, tenant: tenant, name: "Ana Lima") }
  let(:dashboard_url) { "http://#{tenant.subdomain}.zubio.com.br#{owner_appointments_path}" }

  it "shows the action card on a browser that offers installation" do
    create(:branding, tenant: tenant)
    emulate_android
    sign_in_owner(owner)
    visit dashboard_url

    wait_until { fire_before_install_prompt; page.has_css?("[data-pwa-install-target='action']:not([hidden])", wait: 0) }

    expect(page).to have_button(Components::Owner::InstallInvite::INSTALL_LABEL)
    expect(page).to have_css("[data-controller='pwa-install']:not([hidden])")
    expect(page).to fit_the_phone_width
  end

  it "fires the native prompt when the owner taps install" do
    create(:branding, tenant: tenant)
    emulate_android
    sign_in_owner(owner)
    visit dashboard_url
    wait_until { fire_before_install_prompt; page.has_css?("[data-pwa-install-target='action']:not([hidden])", wait: 0) }

    click_on Components::Owner::InstallInvite::INSTALL_LABEL

    expect(install_prompt_called?).to be(true)
  end

  it "gives an iPhone the two manual steps and no install action" do
    create(:branding, tenant: tenant)
    emulate_iphone
    sign_in_owner(owner)
    visit dashboard_url

    expect(page).to have_css("[data-pwa-install-target='instructions']:not([hidden])")
    expect(page).to have_text("Compartilhar")
    expect(page).to have_text("Adicionar à Tela de Início")
    expect(page).to have_no_button(Components::Owner::InstallInvite::INSTALL_LABEL)
  end

  it "gives an iPad that presents itself as a Mac the two manual steps" do
    create(:branding, tenant: tenant)
    emulate_ipad_in_desktop_mode
    sign_in_owner(owner)
    visit dashboard_url

    expect(page).to have_css("[data-pwa-install-target='instructions']:not([hidden])")
    expect(page).to have_no_button(Components::Owner::InstallInvite::INSTALL_LABEL)
  end

  it "stays away when the app is already installed, even with an install prompt waiting" do
    create(:branding, tenant: tenant)
    emulate_installed_app
    sign_in_owner(owner)
    visit dashboard_url

    fire_before_install_prompt
    page.evaluate_async_script("setTimeout(arguments[0], 0)")

    expect(page).to have_css("[data-controller='pwa-install'][hidden]", visible: :all)
    expect(page).to have_no_css("[data-pwa-install-target='action']", visible: true)
    expect(page).to have_no_css("[data-pwa-install-target='instructions']", visible: true)
  end

  it "stays dismissed after the owner taps later and moves around the panel" do
    create(:branding, tenant: tenant)
    emulate_android
    sign_in_owner(owner)
    visit dashboard_url
    wait_until { fire_before_install_prompt; page.has_css?("[data-pwa-install-target='action']:not([hidden])", wait: 0) }

    click_on Components::Owner::InstallInvite::DISMISS_LABEL
    visit "http://#{tenant.subdomain}.zubio.com.br#{owner_settings_path}"
    expect(page).to fit_the_phone_width
    visit dashboard_url
    fire_before_install_prompt
    page.evaluate_async_script("setTimeout(arguments[0], 0)")

    expect(page).to have_css("[data-controller='pwa-install'][hidden]", visible: :all)
  end

  it "closes the invite when installation completes" do
    create(:branding, tenant: tenant)
    emulate_android
    sign_in_owner(owner)
    visit dashboard_url
    wait_until { fire_before_install_prompt; page.has_css?("[data-pwa-install-target='action']:not([hidden])", wait: 0) }

    fire_app_installed

    expect(page).to have_css("[data-controller='pwa-install'][hidden]", visible: :all)
  end

  it "offers nothing and reserves no empty space on a desktop browser" do
    create(:branding, tenant: tenant)
    emulate_desktop
    sign_in_owner(owner)
    visit dashboard_url

    fire_before_install_prompt
    page.evaluate_async_script("setTimeout(arguments[0], 0)")

    expect(page).to have_css("[data-controller='pwa-install'][hidden]", visible: :all)
    expect(page).to have_no_css("[data-pwa-install-target='action']", visible: true)
  end
end
