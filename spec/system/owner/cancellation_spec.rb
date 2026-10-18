require "rails_helper"

RSpec.describe "Owner appointment cancellation", type: :system, js: true do
  it "fits the confirmation sheet in the phone width" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    create(:branding, tenant: tenant, brand_600: "#8E4B6B")
    professional_user = create(:user, :with_professional, tenant: tenant, name: "Ana Lima")
    service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45, price_cents: 6000)
    client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro", phone: "11988771234")
    ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional_user.professional, service: service, client: client, starts_at: Time.zone.local(2026, 9, 8, 9, 45)) }
    sign_in_owner(professional_user)

    click_on "Ana Paula Ribeiro"
    click_button "Desmarcar este horário"

    expect(page).to have_css("dialog[open]", text: "Desmarcar terça, 8 set, às 09:45?")
    expect(page).to fit_the_phone_width
  end

  it "asks before cancelling and keeps the appointment when the owner gives up" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    create(:branding, tenant: tenant, brand_600: "#8E4B6B")
    professional_user = create(:user, :with_professional, tenant: tenant, name: "Ana Lima")
    service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45, price_cents: 6000)
    client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro", phone: "11988771234")
    appointment = ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional_user.professional, service: service, client: client, starts_at: Time.zone.local(2026, 9, 8, 9, 45)) }
    sign_in_owner(professional_user)

    click_on "Ana Paula Ribeiro"
    click_button "Desmarcar este horário"
    find("dialog[open]")
    click_button "Manter agendamento"

    expect(page).to have_no_css("dialog[open]")
    expect(page).to have_button("Desmarcar este horário")
    expect(ActsAsTenant.with_tenant(tenant) { appointment.reload }).to be_confirmed
  end

  it "strikes the row from the agenda when the owner confirms" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    create(:branding, tenant: tenant, brand_600: "#8E4B6B")
    professional_user = create(:user, :with_professional, tenant: tenant, name: "Ana Lima")
    service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45, price_cents: 6000)
    client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro", phone: "11988771234")
    appointment = ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional_user.professional, service: service, client: client, starts_at: Time.zone.local(2026, 9, 8, 9, 45)) }
    sign_in_owner(professional_user)

    click_on "Ana Paula Ribeiro"
    click_button "Desmarcar este horário"
    click_button "Sim, desmarcar"
    find("turbo-frame#appointment_detail section", text: "Desmarcado")
    click_on "Voltar para a agenda"

    expect(page).to have_css(".line-through", text: "Ana Paula Ribeiro")
    expect(page).to fit_the_phone_width
    expect(ActsAsTenant.with_tenant(tenant) { appointment.reload }).to be_cancelled
  end
end
