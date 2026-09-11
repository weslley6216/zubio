require "rails_helper"

RSpec.describe "Owner branding repaint", type: :system, js: true do
  def save_brand_color(tenant, hex)
    visit "http://#{tenant.subdomain}.zubio.com.br#{edit_owner_branding_path}"
    within_fieldset(Views::Owner::Brandings::Edit::BRAND_LABEL) { find(%([data-swatch="#{hex}"])).click }
    click_on Views::Owner::Brandings::Edit::SUBMIT_LABEL
  end

  it "repaints the destination screen in the new color and confirms the change, with no manual reload" do
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    owner = create(:user, tenant: tenant, email: "owner@example.com", password: "s3cr3t123")
    create(:branding, tenant: tenant, brand_600: "#4F46E5")

    emulate_color_scheme("light")
    sign_in_owner(tenant, owner)
    save_brand_color(tenant, "#BE123C")

    expect(page).to have_content("Marca atualizada.")
    expect(computed("span.bg-brand-accent", "backgroundColor")).to eq("rgb(190, 18, 60)")
    expect(computed("span.bg-brand-accent", "backgroundColor")).not_to eq("rgb(79, 70, 229)")
  end

  it "keeps the confirmation legible on the success tone in both color schemes" do
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    owner = create(:user, tenant: tenant, email: "owner@example.com", password: "s3cr3t123")
    create(:branding, tenant: tenant, brand_600: "#4F46E5")

    %w[light dark].each do |scheme|
      emulate_color_scheme(scheme)
      sign_in_owner(tenant, owner)
      save_brand_color(tenant, "#BE123C")

      expect(page).to have_css("[data-alert]")
      expect(contrast_ratio("[data-alert]")).to be >= Branding::ColorScale::MIN_CONTRAST
      expect(computed("[data-alert]", "borderTopColor")).not_to eq(computed("[data-alert]", "color"))
    end
  end
end
