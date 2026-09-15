require "rails_helper"

RSpec.describe "Owner branding accent", type: :system, js: true do
  def role(branding, name) = branding.css_variables[/--#{name}:(#\h{6});/, 1]

  def rgb(hex) = "rgb(#{hex.delete('#').scan(/../).map { |channel| channel.to_i(16) }.join(', ')})"

  it "keeps a vivid brand color legible on the accent in both color schemes" do
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    owner = create(:user, tenant: tenant, email: "owner@example.com", password: "s3cr3t123")
    create(:branding, tenant: tenant, brand_600: "#ff00bb")

    %w[light dark].each do |scheme|
      emulate_color_scheme(scheme)
      sign_in_owner(tenant, owner)

      expect(opaque?("span.bg-brand-accent")).to be true
      expect(contrast_ratio("span.bg-brand-accent")).to be >= Branding::ColorScale::MIN_CONTRAST
    end
  end

  it "labels the current section in the brand and underlines it in the secondary on a wide screen, and lights it in the brand on a phone, in both color schemes" do
    tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
    owner = create(:user, tenant: tenant, email: "owner@example.com", password: "s3cr3t123")
    branding = create(:branding, tenant: tenant, brand_600: "#2C6CB0", brand_secondary_600: "#E8493C")

    %w[light dark].each do |scheme|
      page.driver.resize(1200, 800)
      emulate_color_scheme(scheme)
      sign_in_owner(tenant, owner)
      visit "http://#{tenant.subdomain}.zubio.com.br#{owner_settings_path}"

      expect(computed("nav a[aria-current='page']", "color")).to eq(rgb(role(branding, "brand-ink-#{scheme}")))
      expect(computed("nav a[aria-current='page']", "borderBottomColor")).to eq(rgb(role(branding, "secondary-mark-#{scheme}")))
      expect(computed("nav a[aria-current='page']", "backgroundColor")).to eq("rgba(0, 0, 0, 0)")

      page.driver.resize(375, 667)
      find("details summary").click

      expect(computed("details a[aria-current='page']", "backgroundColor")).to eq(rgb(role(branding, "brand-soft-#{scheme}")))
      expect(computed("details a[aria-current='page']", "color")).to eq(rgb(role(branding, "brand-soft-ink-#{scheme}")))
      expect(contrast_ratio("details a[aria-current='page']")).to be >= Branding::ColorScale::MIN_CONTRAST
    end
  end
end
