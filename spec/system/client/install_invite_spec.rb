require "rails_helper"

RSpec.describe "Client install invite", type: :system, js: true do
  let(:tenant) { create(:tenant, subdomain: "titiko-croche", name: "Titiko Crochê") }

  before { create(:branding, tenant: tenant) }

  it "offers the Android install action on the receipt" do
    appointment = create(:appointment, tenant: tenant)
    emulate_android
    sign_in_client(appointment.client)

    visit "http://#{tenant.subdomain}.zubio.com.br#{client_receipt_path(appointment.cancel_token)}"
    wait_until { fire_before_install_prompt; page.has_css?("[data-pwa-install-target='action']:not([hidden])", wait: 0) }

    expect(page).to have_text("Tenha a Titiko Crochê na tela inicial")
    expect(page).to have_button(Components::InstallInvite::INSTALL_LABEL)
    expect(page).to fit_the_phone_width
  end

  it "gives an iPhone the two Safari steps on the receipt, with no install button" do
    appointment = create(:appointment, tenant: tenant)
    emulate_iphone
    sign_in_client(appointment.client)

    visit "http://#{tenant.subdomain}.zubio.com.br#{client_receipt_path(appointment.cancel_token)}"

    expect(page).to have_css("[data-pwa-install-target='instructions']:not([hidden])")
    expect(page).to have_text("Compartilhar")
    expect(page).to have_text("Adicionar à Tela de Início")
    expect(page).to have_no_button(Components::InstallInvite::INSTALL_LABEL)
  end

  it "hides the invite on a first visit to the showcase, then shows it after a receipt visit" do
    create(:service, tenant: tenant, name: "Corte")
    emulate_android

    visit "http://#{tenant.subdomain}.zubio.com.br#{establishment_path}"
    expect(page).to have_css("[data-controller='pwa-install'][hidden]", visible: :all)

    appointment = create(:appointment, tenant: tenant)
    visit "http://#{tenant.subdomain}.zubio.com.br#{client_receipt_path(appointment.cancel_token)}"
    visit "http://#{tenant.subdomain}.zubio.com.br#{establishment_path}"

    wait_until { fire_before_install_prompt; page.has_css?("[data-pwa-install-target='action']:not([hidden])", wait: 0) }
    expect(page).to have_button(Components::InstallInvite::INSTALL_LABEL)
  end

  it "snoozes the invite for seven days after Agora não, then brings it back" do
    create(:service, tenant: tenant, name: "Corte")
    client = create(:client, tenant: tenant)
    emulate_android
    sign_in_client(client)
    visit "http://#{tenant.subdomain}.zubio.com.br#{establishment_path}"
    wait_until { fire_before_install_prompt; page.has_css?("[data-pwa-install-target='action']:not([hidden])", wait: 0) }

    click_on "Agora não"
    expect(page).to have_css("[data-controller='pwa-install'][hidden]", visible: :all)

    page.execute_script("localStorage.setItem('pwa-install-snooze:client', String(Date.now() - 1000))")
    visit "http://#{tenant.subdomain}.zubio.com.br#{establishment_path}"
    wait_until { fire_before_install_prompt; page.has_css?("[data-pwa-install-target='action']:not([hidden])", wait: 0) }

    expect(page).to have_button(Components::InstallInvite::INSTALL_LABEL)
  end

  it "closes the invite when installation completes in the browser" do
    create(:service, tenant: tenant, name: "Corte")
    client = create(:client, tenant: tenant)
    sign_in_client(client)
    emulate_android
    visit "http://#{tenant.subdomain}.zubio.com.br#{establishment_path}"
    wait_until { fire_before_install_prompt; page.has_css?("[data-pwa-install-target='action']:not([hidden])", wait: 0) }

    fire_app_installed

    expect(page).to have_css("[data-controller='pwa-install'][hidden]", visible: :all)
  end

  it "stays hidden in standalone mode and records the installation for the account" do
    create(:service, tenant: tenant, name: "Corte")
    client = create(:client, tenant: tenant)
    sign_in_client(client)
    emulate_installed_app

    visit "http://#{tenant.subdomain}.zubio.com.br#{establishment_path}"

    expect(page).to have_css("[data-controller='pwa-install'][hidden]", visible: :all)
    wait_until { client.reload.app_installed_at.present? }
  end

  it "closes the invite forever on the receipt when the client taps Já instalei" do
    appointment = create(:appointment, tenant: tenant)
    emulate_iphone
    sign_in_client(appointment.client)
    visit "http://#{tenant.subdomain}.zubio.com.br#{client_receipt_path(appointment.cancel_token)}"
    expect(page).to have_css("[data-pwa-install-target='instructions']:not([hidden])")

    click_on Components::InstallInvite::INSTALLED_LABEL
    expect(page).to have_css("[data-controller='pwa-install'][hidden]", visible: :all)

    visit page.current_url
    expect(page).to have_css("[data-controller='pwa-install'][hidden]", visible: :all)
  end

  it "offers nothing and reserves no space on a desktop receipt" do
    appointment = create(:appointment, tenant: tenant)
    emulate_desktop
    sign_in_client(appointment.client)

    visit "http://#{tenant.subdomain}.zubio.com.br#{client_receipt_path(appointment.cancel_token)}"
    fire_before_install_prompt
    page.evaluate_async_script("setTimeout(arguments[0], 0)")

    expect(page).to have_css("[data-controller='pwa-install'][hidden]", visible: :all)
    expect(page).to have_no_css("[data-pwa-install-target='action']", visible: true)
  end
end
