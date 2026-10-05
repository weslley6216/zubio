require "rails_helper"

RSpec.describe "Owner branding on one screen", type: :system, js: true do
  it "fits each brand question on a phone screen without scrolling" do
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    create(:branding, tenant: tenant, brand_600: "#4F46E5")
    page.driver.resize(430, 800)
    sign_in_owner(create(:user, tenant: tenant))

    taller_than_screen = [ edit_owner_brand_colors_path, edit_owner_brand_name_path, edit_owner_brand_logo_path ].to_h do |path|
      visit "http://estudio-aurora.zubio.com.br#{path}"
      find_button(Views::Owner::BrandQuestions::Edit::SUBMIT_LABEL)
      [ path, page.evaluate_script("document.documentElement.scrollHeight > window.innerHeight") ]
    end

    expect(taller_than_screen).to eq(
      edit_owner_brand_colors_path => false,
      edit_owner_brand_name_path => false,
      edit_owner_brand_logo_path => false
    )
  end

  it "keeps the brand row inside the narrowest phone" do
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    create(:branding, tenant: tenant, brand_600: "#4F46E5")
    page.driver.resize(320, 800)
    sign_in_owner(create(:user, tenant: tenant))

    visit "http://estudio-aurora.zubio.com.br#{edit_owner_brand_colors_path}"

    expect(page.evaluate_script("document.documentElement.scrollWidth")).to eq(320)
  end

  { "light" => 600, "dark" => 400 }.each do |scheme, step|
    it "repaints the two-color preview live as a swatch is chosen, in #{scheme}" do
      tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
      create(:branding, tenant: tenant, brand_600: "#4F46E5")
      emulate_color_scheme(scheme)
      sign_in_owner(create(:user, tenant: tenant))
      visit "http://estudio-aurora.zubio.com.br#{edit_owner_brand_colors_path}"

      within(%(fieldset[aria-label="Cor principal"])) { find(%([data-row-option] [data-swatch="#BE123C"])).click }

      expect(computed_hex("[data-color-swatch-target='preview'] .bg-brand-accent", "backgroundColor"))
        .to eq(Branding::ColorScale.new("#BE123C").tokens.fetch(step).upcase)
    end
  end
end
