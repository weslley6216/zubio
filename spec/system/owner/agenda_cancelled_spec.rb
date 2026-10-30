require "rails_helper"

RSpec.describe "Owner agenda cancellations", type: :system, js: true do
  it "opens the collapsed group on tap, showing the struck cards with the badge" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    create(:branding, tenant: tenant)
    professional_user = create(:user, :with_professional, tenant: tenant, name: "Ana Lima")
    service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45)
    first_client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro")
    second_client = create(:client, tenant: tenant, name: "Bruna Salles")
    third_client = create(:client, tenant: tenant, name: "Camila Nunes")
    ActsAsTenant.with_tenant(tenant) do
      create(:appointment, :cancelled, tenant: tenant, professional: professional_user.professional, service: service, client: first_client, starts_at: Time.zone.local(2026, 9, 8, 9, 0))
      create(:appointment, :cancelled, tenant: tenant, professional: professional_user.professional, service: service, client: second_client, starts_at: Time.zone.local(2026, 9, 8, 10, 0))
      create(:appointment, :cancelled, tenant: tenant, professional: professional_user.professional, service: service, client: third_client, starts_at: Time.zone.local(2026, 9, 8, 11, 0))
    end
    sign_in_owner(professional_user)
    expect(page).to have_text("3 desmarcados")
    expect(page).to have_no_css(".line-through")

    find("summary", text: "desmarcado").click

    page_text = page.text
    expect(page_text.index("Ana Paula Ribeiro")).to be < page_text.index("Bruna Salles")
    expect(page_text.index("Bruna Salles")).to be < page_text.index("Camila Nunes")
    expect(page).to have_css(".line-through", text: "Ana Paula Ribeiro")
    expect(page).to have_css(".line-through", text: "Bruna Salles")
    expect(page).to have_css(".line-through", text: "Camila Nunes")
    expect(page).to have_text(/Desmarcado/i)
    expect(page).to fit_the_phone_width
  end

  it "keeps the group under the list and to the left of the detail on desktop" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    create(:branding, tenant: tenant)
    professional_user = create(:user, :with_professional, tenant: tenant, name: "Ana Lima")
    service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45)
    occupying_client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro")
    cancelled_client = create(:client, tenant: tenant, name: "Bruna Salles")
    ActsAsTenant.with_tenant(tenant) do
      create(:appointment, tenant: tenant, professional: professional_user.professional, service: service, client: occupying_client, starts_at: Time.zone.local(2026, 9, 8, 9, 0))
      create(:appointment, :cancelled, tenant: tenant, professional: professional_user.professional, service: service, client: cancelled_client, starts_at: Time.zone.local(2026, 9, 8, 10, 0))
    end
    emulate_desktop_screen
    sign_in_owner(professional_user)

    expect(page.evaluate_script(<<~JS)).to be(true)
      (() => {
        const frameContent = document.querySelector('[data-frame-content]');
        const list = frameContent.querySelector(':scope > div');
        const group = frameContent.querySelector(':scope > details');
        const detail = document.querySelector('turbo-frame#appointment_detail').getBoundingClientRect();
        const listBox = list.getBoundingClientRect();
        const groupBox = group.getBoundingClientRect();
        return groupBox.top >= listBox.bottom - 0.5 && groupBox.right <= detail.left + 0.5;
      })()
    JS
  end
end
