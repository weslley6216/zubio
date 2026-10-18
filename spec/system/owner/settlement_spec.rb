require "rails_helper"

RSpec.describe "Owner appointment settlement", type: :system, js: true do
  it "marks the row completed from the detail" do
    travel_to Time.zone.local(2026, 9, 8, 19, 0)
    tenant = create(:tenant, subdomain: "mary-sombracelhas", name: "Mary Sombracelhas")
    create(:branding, tenant: tenant, brand_600: "#8E4B6B")
    owner = create(:user, :with_professional, tenant: tenant, name: "Mary")
    service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45, price_cents: 6000)
    client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro", phone: "11988771234")
    appointment = ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: owner.professional, service: service, client: client, starts_at: Time.zone.local(2026, 9, 8, 9, 45)) }
    sign_in_owner(owner)

    click_on "Ana Paula Ribeiro"
    click_button "Atendi"
    find("turbo-frame#appointment_detail section", text: "Concluído")
    click_on "Voltar para a agenda"

    expect(page).to have_css("[data-appointment-id='#{appointment.id}']", text: /Concluído/i)
    expect(page).to have_no_css(".line-through", text: "Ana Paula Ribeiro")
    expect(page).to fit_the_phone_width
    expect(ActsAsTenant.with_tenant(tenant) { appointment.reload }).to be_completed
  end

  it "marks the row as a no-show and leaves only the correction" do
    travel_to Time.zone.local(2026, 9, 8, 19, 0)
    tenant = create(:tenant, subdomain: "mary-sombracelhas", name: "Mary Sombracelhas")
    create(:branding, tenant: tenant, brand_600: "#8E4B6B")
    owner = create(:user, :with_professional, tenant: tenant, name: "Mary")
    service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45, price_cents: 6000)
    client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro", phone: "11988771234")
    appointment = ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: owner.professional, service: service, client: client, starts_at: Time.zone.local(2026, 9, 8, 9, 45)) }
    sign_in_owner(owner)

    click_on "Ana Paula Ribeiro"
    click_button "Não veio"
    find("turbo-frame#appointment_detail section", text: "Falta")

    expect(page).to have_button("Atendi")
    expect(page).to have_no_button("Não veio")
    expect(ActsAsTenant.with_tenant(tenant) { appointment.reload }).to be_no_show
  end

  it "corrects a no-show to completed from the detail" do
    travel_to Time.zone.local(2026, 9, 8, 19, 0)
    tenant = create(:tenant, subdomain: "mary-sombracelhas", name: "Mary Sombracelhas")
    create(:branding, tenant: tenant, brand_600: "#8E4B6B")
    owner = create(:user, :with_professional, tenant: tenant, name: "Mary")
    service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45, price_cents: 6000)
    client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro", phone: "11988771234")
    appointment = ActsAsTenant.with_tenant(tenant) { create(:appointment, :no_show, tenant: tenant, professional: owner.professional, service: service, client: client, starts_at: Time.zone.local(2026, 9, 8, 9, 45)) }
    sign_in_owner(owner)

    click_on "Ana Paula Ribeiro"
    click_button "Atendi"
    find("turbo-frame#appointment_detail section", text: "Concluído")

    expect(page).to fit_the_phone_width
    expect(ActsAsTenant.with_tenant(tenant) { appointment.reload }).to be_completed
  end

  it "shows the completed and no-show badges legibly in light" do
    travel_to Time.zone.local(2026, 9, 8, 19, 0)
    tenant = create(:tenant, subdomain: "mary-sombracelhas", name: "Mary Sombracelhas")
    create(:branding, tenant: tenant, brand_600: "#8E4B6B")
    owner = create(:user, :with_professional, tenant: tenant, name: "Mary")
    sobrancelhas = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45, price_cents: 6000)
    henna = create(:service, tenant: tenant, name: "Design com henna", duration_minutes: 60)
    ana = create(:client, tenant: tenant, name: "Ana Paula Ribeiro", phone: "11988771234")
    juliana = create(:client, tenant: tenant, name: "Juliana Prado", phone: "11991234455")
    ActsAsTenant.with_tenant(tenant) { create(:appointment, :completed, tenant: tenant, professional: owner.professional, service: sobrancelhas, client: ana, starts_at: Time.zone.local(2026, 9, 8, 9, 45)) }
    ActsAsTenant.with_tenant(tenant) { create(:appointment, :no_show, tenant: tenant, professional: owner.professional, service: henna, client: juliana, starts_at: Time.zone.local(2026, 9, 8, 14, 0)) }
    emulate_color_scheme("light")

    sign_in_owner(owner)

    expect(contrast_ratio("turbo-frame#agenda_day main .bg-success-soft")).to be >= Branding::ColorScale::MIN_CONTRAST
    expect(contrast_ratio("turbo-frame#agenda_day main .bg-danger-soft")).to be >= Branding::ColorScale::MIN_CONTRAST
    expect(computed_hex("turbo-frame#agenda_day main .bg-success-soft", "backgroundColor")).to eq("#ECFDF3")
    expect(computed_hex("turbo-frame#agenda_day main .bg-danger-soft", "backgroundColor")).to eq("#FEF3F2")
    expect(computed_hex("turbo-frame#agenda_day main .bg-danger-soft", "color")).to eq("#B42318")
  end

  it "shows the completed and no-show badges legibly in dark" do
    travel_to Time.zone.local(2026, 9, 8, 19, 0)
    tenant = create(:tenant, subdomain: "mary-sombracelhas", name: "Mary Sombracelhas")
    create(:branding, tenant: tenant, brand_600: "#8E4B6B")
    owner = create(:user, :with_professional, tenant: tenant, name: "Mary")
    sobrancelhas = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45, price_cents: 6000)
    henna = create(:service, tenant: tenant, name: "Design com henna", duration_minutes: 60)
    ana = create(:client, tenant: tenant, name: "Ana Paula Ribeiro", phone: "11988771234")
    juliana = create(:client, tenant: tenant, name: "Juliana Prado", phone: "11991234455")
    ActsAsTenant.with_tenant(tenant) { create(:appointment, :completed, tenant: tenant, professional: owner.professional, service: sobrancelhas, client: ana, starts_at: Time.zone.local(2026, 9, 8, 9, 45)) }
    ActsAsTenant.with_tenant(tenant) { create(:appointment, :no_show, tenant: tenant, professional: owner.professional, service: henna, client: juliana, starts_at: Time.zone.local(2026, 9, 8, 14, 0)) }
    emulate_color_scheme("dark")

    sign_in_owner(owner)

    expect(contrast_ratio("turbo-frame#agenda_day main .bg-success-soft")).to be >= Branding::ColorScale::MIN_CONTRAST
    expect(contrast_ratio("turbo-frame#agenda_day main .bg-danger-soft")).to be >= Branding::ColorScale::MIN_CONTRAST
    expect(computed_hex("turbo-frame#agenda_day main .bg-success-soft", "backgroundColor")).to eq("#0C2A1E")
    expect(computed_hex("turbo-frame#agenda_day main .bg-danger-soft", "backgroundColor")).to eq("#3A1D1C")
    expect(computed_hex("turbo-frame#agenda_day main .bg-danger-soft", "color")).to eq("#FDA29B")
  end
end
