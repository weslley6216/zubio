require "rails_helper"

RSpec.describe "Owner branding repaint", type: :system, js: true do
  def save_brand_color(tenant, hex)
    visit "http://#{tenant.subdomain}.zubio.com.br#{edit_owner_brand_colors_path}"
    within(%(fieldset[aria-label="#{Components::Owner::BrandQuestion::Colors::BRAND_LABEL}"])) do
      find(%([data-row-option] [data-swatch="#{hex}"])).click
    end
    click_on Views::Owner::BrandQuestions::Edit::SUBMIT_LABEL
  end

  it "repaints the destination screen in the new color and confirms, with no manual reload" do
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    owner = create(:user, tenant: tenant, email: "owner@example.com", password: "s3cr3t123")
    create(:branding, tenant: tenant, brand_600: "#4F46E5")

    emulate_color_scheme("light")
    sign_in_owner(tenant, owner)
    save_brand_color(tenant, "#BE123C")

    expect(page).to have_content(Owner::BrandQuestionsController::NOTICE)
    expect(computed("span.bg-brand-accent", "backgroundColor")).to eq("rgb(190, 18, 60)")
  end
end
