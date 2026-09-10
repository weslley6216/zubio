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

      expect(opaque?("a.bg-brand-accent")).to be true
      expect(contrast_ratio("a.bg-brand-accent")).to be >= Branding::ColorScale::MIN_CONTRAST
    end
  end

  it "offers the suggested colors to the color input on the branding form" do
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    owner = create(:user, tenant: tenant, email: "owner@example.com", password: "s3cr3t123")
    create(:branding, tenant: tenant, brand_600: "#ff00bb")

    sign_in(tenant, owner)
    visit "http://#{tenant.subdomain}.zubio.com.br#{edit_owner_branding_path}"

    listed = page.evaluate_script(
      "Array.from(document.querySelectorAll('datalist#brand-color-suggestions option')).map(node => node.value)"
    )

    expect(listed).to eq(Branding::SUGGESTED_COLORS)
    expect(page.evaluate_script("document.querySelector('input[type=color]').getAttribute('list')")).to eq("brand-color-suggestions")
  end
end
