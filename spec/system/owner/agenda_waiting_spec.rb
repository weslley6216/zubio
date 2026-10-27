require "rails_helper"

RSpec.describe "Owner agenda skeleton", type: :system, js: true do
  it "replaces the agenda rows with a skeleton while the day loads" do
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    professional_user = create(:user, :with_professional, tenant: tenant, name: "Ana Lima")
    service = create(:service, tenant: tenant, duration_minutes: 45)
    client = create(:client, tenant: tenant)
    ActsAsTenant.with_tenant(tenant) do
      create(:appointment, tenant: tenant, professional: professional_user.professional, service: service, client: client, starts_at: Date.current.in_time_zone.change(hour: 9, min: 45))
    end
    sign_in_owner(professional_user)

    page.execute_script("document.getElementById('agenda_day').setAttribute('busy', '')")

    expect(page).to have_css("#agenda_day [data-skeleton]", visible: :visible)
    expect(page).to have_no_css("#agenda_day [data-appointment-id]", visible: :visible)
    expect(page).to fit_the_phone_width
  end

  it "shows the detail skeleton on desktop while the appointment loads" do
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    professional_user = create(:user, :with_professional, tenant: tenant, name: "Ana Lima")
    service = create(:service, tenant: tenant, duration_minutes: 45)
    client = create(:client, tenant: tenant)
    ActsAsTenant.with_tenant(tenant) do
      create(:appointment, tenant: tenant, professional: professional_user.professional, service: service, client: client, starts_at: Date.current.in_time_zone.change(hour: 9, min: 45))
    end
    emulate_desktop_screen
    sign_in_owner(professional_user)

    page.execute_script("document.getElementById('appointment_detail').setAttribute('busy', '')")

    expect(page).to have_css("#appointment_detail [data-skeleton]", visible: :visible)
  end

  %w[phone desktop].each do |screen|
    it "draws only whole skeleton rows as tall as an agenda row on the #{screen}" do
      tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
      professional_user = create(:user, :with_professional, tenant: tenant, name: "Ana Lima")
      service = create(:service, tenant: tenant, duration_minutes: 45)
      client = create(:client, tenant: tenant)
      ActsAsTenant.with_tenant(tenant) do
        create(:appointment, tenant: tenant, professional: professional_user.professional, service: service, client: client, starts_at: Date.current.in_time_zone.change(hour: 9, min: 45))
        create(:appointment, tenant: tenant, professional: professional_user.professional, service: service, client: client, starts_at: Date.current.in_time_zone.change(hour: 11, min: 0))
      end
      emulate_desktop_screen if screen == "desktop"
      sign_in_owner(professional_user)
      row_height = first("#agenda_day [data-appointment-id]").evaluate_script("this.getBoundingClientRect().height")
      page.execute_script("document.getElementById('agenda_day').setAttribute('busy', '')")
      find("#agenda_day > * [data-skeleton]", match: :first, visible: :visible)

      pieces = JSON.parse(page.evaluate_script(<<~JS))
        (function() {
          const skeleton = document.querySelector("#agenda_day main [data-skeleton]")
          const bottom = skeleton.getBoundingClientRect().bottom
          return JSON.stringify(Array.from(skeleton.children).map((piece) => piece.getBoundingClientRect())
            .filter((box) => box.height > 0).map((box) => ({ height: box.height, clipped: box.bottom > bottom + 0.5 })))
        })()
      JS

      expect(pieces.size).to eq(2)
      expect(pieces).to all(include("height" => row_height, "clipped" => false))
    end
  end

  it "keeps the open appointment sheet on screen while the agenda frame is busy" do
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    professional_user = create(:user, :with_professional, tenant: tenant, name: "Ana Lima")
    service = create(:service, tenant: tenant, duration_minutes: 45)
    client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro")
    ActsAsTenant.with_tenant(tenant) do
      create(:appointment, tenant: tenant, professional: professional_user.professional, service: service, client: client, starts_at: Date.current.in_time_zone.change(hour: 9, min: 45))
    end
    sign_in_owner(professional_user)
    click_on "Ana Paula Ribeiro"
    find_link("Chamar no WhatsApp")

    page.execute_script("document.getElementById('agenda_day').setAttribute('busy', '')")

    expect(page).to have_css("#agenda_day main [data-skeleton]", visible: :visible)
    expect(computed("#appointment_detail [data-frame-content]", "transitionDelay")).to eq("0s, 0s")
    expect(page).to have_link("Chamar no WhatsApp")
  end
end
