require "rails_helper"

RSpec.describe "Owner branding accent", type: :system, js: true do
  def sign_in(tenant, owner)
    visit "http://#{tenant.subdomain}.zubio.com.br#{new_owner_session_path}"
    fill_in "E-mail", with: owner.email
    fill_in "Senha", with: "s3cr3t123"
    click_on "Entrar"

    expect(page).to have_content(tenant.name)
  end

  it "keeps a vivid brand color legible on the accent in both color schemes" do
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    owner = create(:user, tenant: tenant, email: "owner@example.com", password: "s3cr3t123")
    create(:branding, tenant: tenant, brand_600: "#ff00bb")

    %w[light dark].each do |scheme|
      emulate_color_scheme(scheme)
      sign_in(tenant, owner)

      expect(opaque?("span.bg-brand-accent")).to be true
      expect(contrast_ratio("span.bg-brand-accent")).to be >= Branding::ColorScale::MIN_CONTRAST
    end
  end

  it "puts the action in the brand and the current section in the secondary on the same screen, both legible, in both color schemes" do
    tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
    owner = create(:user, tenant: tenant, email: "owner@example.com", password: "s3cr3t123")
    create(:branding, tenant: tenant, brand_600: "#BE123C", brand_secondary_600: "#1E60C4")

    %w[light dark].each do |scheme|
      emulate_color_scheme(scheme)
      sign_in(tenant, owner)
      visit "http://#{tenant.subdomain}.zubio.com.br#{edit_owner_branding_path}"

      expect(computed("input[type=submit]", "backgroundColor")).not_to eq(computed("a.bg-secondary-accent", "backgroundColor"))
      expect(contrast_ratio("input[type=submit]")).to be >= Branding::ColorScale::MIN_CONTRAST
      expect(contrast_ratio("a.bg-secondary-accent")).to be >= Branding::ColorScale::MIN_CONTRAST
    end
  end
end
