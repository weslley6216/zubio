require "rails_helper"

RSpec.describe "Owner branding accent", type: :system, js: true do
  %w[light dark].each do |scheme|
    it "keeps a vivid brand color legible on the accent, in #{scheme}" do
      tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
      create(:branding, tenant: tenant, brand_600: "#ff00bb")
      emulate_color_scheme(scheme)

      sign_in_owner(create(:user, tenant: tenant))

      expect(opaque?("span.bg-brand-accent")).to be true
      expect(contrast_ratio("span.bg-brand-accent")).to be >= Branding::ColorScale::MIN_CONTRAST
    end

    it "labels the current section in the brand and underlines it in the secondary on a wide screen, in #{scheme}" do
      tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
      branding = create(:branding, tenant: tenant, brand_600: "#2C6CB0", brand_secondary_600: "#E8493C")
      page.driver.resize(1200, 800)
      emulate_color_scheme(scheme)
      sign_in_owner(create(:user, tenant: tenant))

      visit "http://barbearia-do-ze.zubio.com.br#{owner_services_path}"

      expect(computed_hex("nav a[aria-current='page']", "color")).to eq(branding.css_variables[/--brand-ink-#{scheme}:(#\h{6});/, 1].upcase)
      expect(computed_hex("nav a[aria-current='page']", "borderBottomColor")).to eq(branding.css_variables[/--secondary-mark-#{scheme}:(#\h{6});/, 1].upcase)
      expect(computed("nav a[aria-current='page']", "backgroundColor")).to eq("rgba(0, 0, 0, 0)")
    end

    it "lights the current section in the brand inside the phone menu, in #{scheme}" do
      tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
      branding = create(:branding, tenant: tenant, brand_600: "#2C6CB0", brand_secondary_600: "#E8493C")
      page.driver.resize(375, 667)
      emulate_color_scheme(scheme)
      sign_in_owner(create(:user, tenant: tenant))
      visit "http://barbearia-do-ze.zubio.com.br#{owner_services_path}"

      find("details summary").click

      expect(computed_hex("details a[aria-current='page']", "backgroundColor")).to eq(branding.css_variables[/--brand-soft-#{scheme}:(#\h{6});/, 1].upcase)
      expect(computed_hex("details a[aria-current='page']", "color")).to eq(branding.css_variables[/--brand-soft-ink-#{scheme}:(#\h{6});/, 1].upcase)
      expect(contrast_ratio("details a[aria-current='page']")).to be >= Branding::ColorScale::MIN_CONTRAST
    end
  end
end
