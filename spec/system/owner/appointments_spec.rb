require "rails_helper"

RSpec.describe "Owner appointments", type: :system, js: true do
  %w[light dark].each do |scheme|
    it "renders the populated agenda fitting the phone width, in #{scheme}" do
      tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
      create(:branding, tenant: tenant)
      professional_user = create(:user, :with_professional, tenant: tenant, name: "Ana Lima")
      service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45)
      client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro", phone: "11988771234")
      ActsAsTenant.with_tenant(tenant) do
        create(:appointment, tenant: tenant, professional: professional_user.professional, service: service, client: client, starts_at: Date.current.in_time_zone.change(hour: 9, min: 45))
      end
      emulate_color_scheme(scheme)

      sign_in_owner(professional_user)

      expect(page).to fit_the_phone_width
      expect(page).to have_text("Ana Paula Ribeiro")
    end
  end
end
