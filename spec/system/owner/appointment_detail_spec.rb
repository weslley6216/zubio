require "rails_helper"

RSpec.describe "Owner appointment detail", type: :system, js: true do
  %w[light dark].each do |scheme|
    it "opens the detail full screen from the agenda row fitting the phone width, in #{scheme}" do
      travel_to Time.zone.local(2026, 9, 8, 7, 0)
      tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
      create(:branding, tenant: tenant)
      professional_user = create(:user, :with_professional, tenant: tenant, name: "Ana Lima")
      service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45, price_cents: 6000)
      client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro", phone: "11988771234")
      current = ActsAsTenant.with_tenant(tenant) do
        create(:appointment, tenant: tenant, professional: professional_user.professional, service: service, client: client, starts_at: Time.zone.local(2026, 8, 11, 9, 45))
        create(:appointment, tenant: tenant, professional: professional_user.professional, service: service, client: client, starts_at: Time.zone.local(2026, 8, 25, 9, 45))
        create(:appointment, tenant: tenant, professional: professional_user.professional, service: service, client: client, starts_at: Time.zone.local(2026, 9, 8, 9, 45))
      end
      emulate_color_scheme(scheme)
      sign_in_owner(professional_user)

      click_on "Ana Paula Ribeiro"

      expect(page).to have_link("Chamar no WhatsApp", href: "https://wa.me/5511988771234")
      expect(page).to have_link("Ligar", href: "tel:+5511988771234")
      expect(page).to have_text("3ª visita")
      expect(page).to fit_the_phone_width
      expect(page).to have_current_path(owner_appointment_path(current))
      viewport = page.evaluate_script("({ width: window.innerWidth, height: window.innerHeight })")
      detail_box = page.evaluate_script(<<~JS)
        (() => {
          const box = document.querySelector('turbo-frame#appointment_detail section').getBoundingClientRect();
          return { width: box.width, height: box.height };
        })()
      JS
      expect([ detail_box["width"], detail_box["height"] ]).to eq([ viewport["width"], viewport["height"] ])
    end
  end

  it "opens the detail from the agenda on the phone" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    create(:branding, tenant: tenant)
    professional_user = create(:user, :with_professional, tenant: tenant, name: "Ana Lima")
    service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45)
    ana = create(:client, tenant: tenant, name: "Ana Paula Ribeiro", phone: "11988771234")
    juliana = create(:client, tenant: tenant, name: "Juliana Prado")
    ActsAsTenant.with_tenant(tenant) do
      create(:appointment, tenant: tenant, professional: professional_user.professional, service: service, client: ana, starts_at: Time.zone.local(2026, 9, 8, 9, 45))
      create(:appointment, tenant: tenant, professional: professional_user.professional, service: service, client: juliana, starts_at: Time.zone.local(2026, 9, 8, 14, 0))
    end
    sign_in_owner(professional_user)

    click_on "Ana Paula Ribeiro"

    expect(page).to have_link("Chamar no WhatsApp")
  end

  it "goes back to the agenda from the detail on the phone" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    create(:branding, tenant: tenant)
    professional_user = create(:user, :with_professional, tenant: tenant, name: "Ana Lima")
    service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45)
    ana = create(:client, tenant: tenant, name: "Ana Paula Ribeiro", phone: "11988771234")
    juliana = create(:client, tenant: tenant, name: "Juliana Prado")
    ActsAsTenant.with_tenant(tenant) do
      create(:appointment, tenant: tenant, professional: professional_user.professional, service: service, client: ana, starts_at: Time.zone.local(2026, 9, 8, 9, 45))
      create(:appointment, tenant: tenant, professional: professional_user.professional, service: service, client: juliana, starts_at: Time.zone.local(2026, 9, 8, 14, 0))
    end
    sign_in_owner(professional_user)
    click_on "Ana Paula Ribeiro"

    click_on "Voltar para a agenda"

    expect(page).not_to have_link("Chamar no WhatsApp")
    expect(page).to have_text("Juliana Prado")
  end

  it "opens the detail beside the still-visible list on a 1280px desktop" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    create(:branding, tenant: tenant)
    professional_user = create(:user, :with_professional, tenant: tenant, name: "Ana Lima")
    service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45)
    ana = create(:client, tenant: tenant, name: "Ana Paula Ribeiro", phone: "11988771234")
    juliana = create(:client, tenant: tenant, name: "Juliana Prado")
    ActsAsTenant.with_tenant(tenant) do
      create(:appointment, tenant: tenant, professional: professional_user.professional, service: service, client: ana, starts_at: Time.zone.local(2026, 9, 8, 9, 45))
      create(:appointment, tenant: tenant, professional: professional_user.professional, service: service, client: juliana, starts_at: Time.zone.local(2026, 9, 8, 14, 0))
    end
    emulate_desktop_screen
    sign_in_owner(professional_user)

    click_on "Ana Paula Ribeiro"

    expect(page).to have_css("turbo-frame#appointment_detail section", text: "Chamar no WhatsApp")
    main_right = page.evaluate_script("document.querySelector('main').getBoundingClientRect().right")
    detail_left = page.evaluate_script("document.querySelector('turbo-frame#appointment_detail section').getBoundingClientRect().left")
    juliana_right = page.evaluate_script("[...document.querySelectorAll('main a')].find((link) => link.textContent.includes('Juliana Prado')).getBoundingClientRect().right")
    expect(detail_left).to be >= main_right
    expect(juliana_right).to be <= main_right
  end

  it "marks the tapped row active and keeps the list node when a detail opens" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    create(:branding, tenant: tenant)
    professional_user = create(:user, :with_professional, tenant: tenant, name: "Ana Lima")
    service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45)
    ana = create(:client, tenant: tenant, name: "Ana Paula Ribeiro", phone: "11988771234")
    juliana = create(:client, tenant: tenant, name: "Juliana Prado")
    ActsAsTenant.with_tenant(tenant) do
      create(:appointment, tenant: tenant, professional: professional_user.professional, service: service, client: ana, starts_at: Time.zone.local(2026, 9, 8, 9, 45))
      create(:appointment, tenant: tenant, professional: professional_user.professional, service: service, client: juliana, starts_at: Time.zone.local(2026, 9, 8, 14, 0))
    end
    sign_in_owner(professional_user)
    page.execute_script("window.__list = document.querySelector('main')")

    click_on "Juliana Prado"

    expect(page).to have_link("Chamar no WhatsApp")
    expect(page.evaluate_script("document.contains(window.__list)")).to be(true)
    active_links = page.all("a[aria-current='true']").map(&:text)
    expect(active_links).to eq([ "Juliana Prado" ])
  end

  it "clears the active row and keeps the list node when the detail closes" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    create(:branding, tenant: tenant)
    professional_user = create(:user, :with_professional, tenant: tenant, name: "Ana Lima")
    service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45)
    ana = create(:client, tenant: tenant, name: "Ana Paula Ribeiro", phone: "11988771234")
    ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional_user.professional, service: service, client: ana, starts_at: Time.zone.local(2026, 9, 8, 9, 45)) }
    sign_in_owner(professional_user)
    click_on "Ana Paula Ribeiro"
    page.execute_script("window.__list = document.querySelector('main')")
    expect(page).to have_css("a[aria-current='true']", text: "Ana Paula Ribeiro")

    click_on "Voltar para a agenda"

    expect(page).to have_no_css("[aria-current='true']")
    expect(page.evaluate_script("document.contains(window.__list)")).to be(true)
  end

  it "advances the url with the day and the appointment and returns to the day without a detail on back" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    create(:branding, tenant: tenant)
    professional_user = create(:user, :with_professional, tenant: tenant, name: "Ana Lima")
    service = create(:service, tenant: tenant)
    tuesday_client = create(:client, tenant: tenant, name: "Ana Terça", phone: "11988771234")
    wednesday_client = create(:client, tenant: tenant, name: "Bia Quarta")
    tuesday = Date.new(2026, 9, 8)
    wednesday = tuesday + 1
    tuesday_appointment = nil
    ActsAsTenant.with_tenant(tenant) do
      create(:appointment, tenant: tenant, professional: professional_user.professional, service: service, client: wednesday_client, starts_at: wednesday.in_time_zone.change(hour: 9))
      tuesday_appointment = create(:appointment, tenant: tenant, professional: professional_user.professional, service: service, client: tuesday_client, starts_at: tuesday.in_time_zone.change(hour: 9))
    end
    sign_in_owner(professional_user)
    visit "http://#{tenant.subdomain}.zubio.com.br#{owner_appointments_path(day: tuesday.iso8601)}"

    find("a", text: "Ana Terça").click

    expect(page).to have_current_path(owner_appointment_path(tuesday_appointment))
    sleep 0.3
    page.go_back

    expect(page).to have_current_path(owner_appointments_path(day: tuesday.iso8601))
    expect(page).to have_text("Ana Terça")
    expect(page).to have_no_link("Chamar no WhatsApp")
  end

  it "hides the call button on a 1280px desktop, keeping WhatsApp" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    create(:branding, tenant: tenant)
    professional_user = create(:user, :with_professional, tenant: tenant, name: "Ana Lima")
    service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45)
    client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro", phone: "11988771234")
    ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional_user.professional, service: service, client: client, starts_at: Time.zone.local(2026, 9, 8, 9, 45)) }
    emulate_desktop_screen
    sign_in_owner(professional_user)

    click_on "Ana Paula Ribeiro"

    expect(page).to have_link("Chamar no WhatsApp")
    expect(page).to have_no_link("Ligar")
  end

  it "shows the select hint beside the list before any appointment is chosen on a 1280px desktop" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    create(:branding, tenant: tenant)
    professional_user = create(:user, :with_professional, tenant: tenant, name: "Ana Lima")
    service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45)
    ana = create(:client, tenant: tenant, name: "Ana Paula Ribeiro", phone: "11988771234")
    ActsAsTenant.with_tenant(tenant) do
      create(:appointment, tenant: tenant, professional: professional_user.professional, service: service, client: ana, starts_at: Time.zone.local(2026, 9, 8, 9, 45))
    end
    emulate_desktop_screen

    sign_in_owner(professional_user)

    expect(page).to have_text("Selecione um agendamento para ver os detalhes.")
    expect(page).to have_no_css("turbo-frame#appointment_detail section")
  end
end
