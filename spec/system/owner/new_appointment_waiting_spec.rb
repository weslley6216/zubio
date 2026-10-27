require "rails_helper"

RSpec.describe "Owner new appointment submit lock", type: :system, js: true do
  it "locks the mark button and shows Marcando…" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    owner = create(:user, :with_professional, tenant: tenant, name: "Mary Sombracelhas", email: "mary@example.com", password: "s3cr3t123")
    service = create(:service, tenant: tenant, name: "Design com henna", duration_minutes: 60)
    create(:working_hour, tenant: tenant, professional: owner.professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
    create(:client, tenant: tenant, name: "Juliana Prado", phone: "11991234455")
    sign_in_owner(owner)
    visit new_owner_appointment_url(host: "#{tenant.subdomain}.zubio.com.br", service_id: service.id)
    fill_in "phone", with: "11991234455"
    find("[data-client-id]", match: :first).click
    find("[data-slot]", match: :first).click

    state = submit_lock_state("[data-slot-selector-target='submit']", "button.click(); button.click();")

    expect(state["disabled"]).to be(true)
    expect(state["label"]).to eq("Marcando…")
  end
end
