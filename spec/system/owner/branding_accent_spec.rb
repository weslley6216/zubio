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

    it "underlines the current section with the accent mark and never the support color, in #{scheme}" do
      tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
      branding = create(:branding, tenant: tenant, brand_600: "#2C6CB0", brand_secondary_600: "#E8493C")
      emulate_desktop_screen(width: 1200, height: 800)
      emulate_color_scheme(scheme)
      sign_in_owner(create(:user, tenant: tenant))

      visit "http://barbearia-do-ze.zubio.com.br#{owner_services_path}"

      expect(computed_hex("nav a[aria-current='page']", "borderBottomColor")).to eq(branding.css_variables[/--brand-mark-#{scheme}:(#\h{6});/, 1].upcase)
      expect(computed_hex("nav a[aria-current='page']", "color")).to eq(branding.css_variables[/--brand-ink-#{scheme}:(#\h{6});/, 1].upcase)
      expect(computed_hex("nav a[aria-current='page']", "borderBottomColor")).not_to eq("#E8493C")
      expect(computed("nav a[aria-current='page']", "backgroundColor")).to eq("rgba(0, 0, 0, 0)")
    end

    it "keeps a light accent's underline visible on the band, in #{scheme}" do
      tenant = create(:tenant, subdomain: "bicho-feliz-pet", name: "Bicho Feliz Pet")
      create(:branding, tenant: tenant, brand_600: "#F2B33D", brand_background: "#1F4D3A")
      emulate_desktop_screen(width: 1200, height: 800)
      emulate_color_scheme(scheme)
      sign_in_owner(create(:user, tenant: tenant))

      visit "http://bicho-feliz-pet.zubio.com.br#{owner_services_path}"

      underline = computed_hex("nav a[aria-current='page']", "borderBottomColor")
      band = computed_hex("[data-owner-band]", "backgroundColor")

      expect(underline).not_to eq("#F2B33D")
      expect(Branding::ColorScale.new(underline).contrast_against(Branding::ColorScale.new(band))).to be >= Branding::ColorScale::MIN_NON_TEXT_CONTRAST
    end

    it "lights the current section in the brand inside the phone menu, in #{scheme}" do
      tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
      branding = create(:branding, tenant: tenant, brand_600: "#2C6CB0", brand_secondary_600: "#E8493C")
      emulate_phone(width: 375, height: 667)
      emulate_color_scheme(scheme)
      sign_in_owner(create(:user, tenant: tenant))
      visit "http://barbearia-do-ze.zubio.com.br#{edit_owner_brand_colors_path}"
      expect(page).to fit_the_phone_width

      find("details summary").click

      expect(computed_hex("details a[aria-current='page']", "backgroundColor")).to eq(branding.css_variables[/--brand-soft-#{scheme}:(#\h{6});/, 1].upcase)
      expect(computed_hex("details a[aria-current='page']", "color")).to eq(branding.css_variables[/--brand-soft-ink-#{scheme}:(#\h{6});/, 1].upcase)
      expect(contrast_ratio("details a[aria-current='page']")).to be >= Branding::ColorScale::MIN_CONTRAST
    end
  end
end
