require "rails_helper"

RSpec.describe "Owner branding repaint", type: :system, js: true do
  it "repaints the destination screen in the new color and confirms, with no manual reload" do
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    create(:branding, tenant: tenant, brand_600: "#4F46E5")
    emulate_color_scheme("light")
    sign_in_owner(create(:user, tenant: tenant))
    visit "http://estudio-aurora.zubio.com.br#{edit_owner_brand_colors_path}"

    within(%(fieldset[aria-label="Cor principal"])) { find(%([data-row-option] [data-swatch="#BE123C"])).click }
    click_on Views::Owner::BrandQuestions::Edit::SUBMIT_LABEL

    expect(page).to have_content(Owner::BrandQuestionsController::NOTICE)
    expect(computed_hex("span.bg-brand-accent", "backgroundColor")).to eq("#BE123C")
  end

  it "keeps the save button in the Zubio color while the owner picks a color" do
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    create(:branding, tenant: tenant, brand_600: "#0F766E")
    emulate_color_scheme("light")
    sign_in_owner(create(:user, tenant: tenant))
    visit "http://estudio-aurora.zubio.com.br#{edit_owner_brand_colors_path}"
    submit_button = %(input[type="submit"][value="#{Views::Owner::BrandQuestions::Edit::SUBMIT_LABEL}"])

    within(%(fieldset[aria-label="Cor principal"])) { find(%([data-row-option] [data-swatch="#BE123C"])).click }

    expect(page).to have_css(%([data-preview-brand="#BE123C"] #{submit_button}))
    expect(computed_hex(submit_button, "backgroundColor")).to eq("#4F46E5")
  end

  it "keeps the save button of the other brand questions in the Zubio color" do
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    create(:branding, tenant: tenant, brand_600: "#0F766E")
    emulate_color_scheme("light")
    sign_in_owner(create(:user, tenant: tenant))

    visit "http://estudio-aurora.zubio.com.br#{edit_owner_brand_name_path}"

    expect(computed_hex(%(input[type="submit"][value="#{Views::Owner::BrandQuestions::Edit::SUBMIT_LABEL}"]), "backgroundColor")).to eq("#4F46E5")
  end
end
