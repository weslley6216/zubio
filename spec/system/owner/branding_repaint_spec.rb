require "rails_helper"

RSpec.describe "Owner branding repaint", type: :system, js: true do
  def sign_in(tenant, owner)
    visit "http://#{tenant.subdomain}.zubio.com.br#{new_owner_session_path}"
    fill_in "E-mail", with: owner.email
    fill_in "Senha", with: "s3cr3t123"
    click_on "Entrar"

    expect(page).to have_content(tenant.name)
  end

  def save_brand_color(tenant, hex)
    visit "http://#{tenant.subdomain}.zubio.com.br#{edit_owner_branding_path}"
    fill_in "Cor da marca", with: hex
    click_on "Salvar"
  end

  it "repaints the destination screen in the new color and confirms the change, with no manual reload" do
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    owner = create(:user, tenant: tenant, email: "owner@example.com", password: "s3cr3t123")
    create(:branding, tenant: tenant, brand_600: "#4F46E5")

    emulate_color_scheme("light")
    sign_in(tenant, owner)
    save_brand_color(tenant, "#B42318")

    expect(page).to have_content("Marca atualizada.")
    expect(computed("a.bg-brand-accent", "backgroundColor")).to eq("rgb(180, 35, 24)")
    expect(computed("a.bg-brand-accent", "backgroundColor")).not_to eq("rgb(79, 70, 229)")
  end

  it "keeps the confirmation legible on the success tone in both color schemes" do
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    owner = create(:user, tenant: tenant, email: "owner@example.com", password: "s3cr3t123")
    create(:branding, tenant: tenant, brand_600: "#4F46E5")

    %w[light dark].each do |scheme|
      emulate_color_scheme(scheme)
      sign_in(tenant, owner)
      save_brand_color(tenant, "#B42318")

      expect(page).to have_css("[data-alert]")
      expect(contrast_ratio("[data-alert]")).to be >= Branding::ColorScale::MIN_CONTRAST
      expect(computed("[data-alert]", "borderTopColor")).not_to eq(computed("[data-alert]", "color"))
    end
  end
end
