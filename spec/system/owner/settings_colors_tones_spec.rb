require "rails_helper"

RSpec.describe "Owner brand colors tones selector", type: :system, js: true do
  it "offers the swatches, the plus and the customize card, colored tones and no native picker, fitting the phone" do
    tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
    create(:branding, :with_background, tenant: tenant)
    sign_in_owner(create(:user, tenant: tenant))

    visit "http://barbearia-do-ze.zubio.com.br#{edit_owner_brand_colors_path}"

    accent = find(%(fieldset[aria-label="#{Components::Owner::BrandQuestion::Colors::ACCENT_LABEL}"]))
    first_tone = accent.first("[data-tone]", visible: :all)["value"]
    expect(page).to have_css(%(fieldset[aria-label="#{Components::Owner::BrandQuestion::Colors::BACKGROUND_LABEL}"] [data-swatch-row] [data-swatch]), count: Branding::Palette::BACKGROUNDS.size)
    expect(accent).to have_css("[data-swatch-row] [data-swatch]", count: Branding::Palette::ACCENTS.size)
    expect(accent).to have_text(Components::Form::ColorSwatches::CUSTOM_SUMMARY)
    expect(accent).to have_css("input[value='custom']", visible: :all)
    expect(page).to have_no_css("input[type=color]", visible: :all)
    expect(computed_hex(%(turbo-frame#tones-brand_600 [data-swatch="#{first_tone}"]), "backgroundColor")).to eq(first_tone)
    expect(page).to fit_the_phone_width
  end

  it "saves the pink background with the plum accent exactly as chosen from the swatches" do
    tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
    create(:branding, :with_background, tenant: tenant)
    sign_in_owner(create(:user, tenant: tenant))
    visit "http://barbearia-do-ze.zubio.com.br#{edit_owner_brand_colors_path}"

    within(%(fieldset[aria-label="#{Components::Owner::BrandQuestion::Colors::BACKGROUND_LABEL}"])) { choose(option: "#F6EEF2", allow_label_click: true) }
    expect(page).to have_css("turbo-frame#accent-swatches[complete]")
    within(%(fieldset[aria-label="#{Components::Owner::BrandQuestion::Colors::ACCENT_LABEL}"])) { choose(option: "#8E4B6B", allow_label_click: true) }
    click_on Views::Owner::BrandQuestions::Edit::SUBMIT_LABEL

    expect(page).to have_text(Owner::BrandQuestionsController::NOTICE)
    ActsAsTenant.with_tenant(tenant) do
      expect(tenant.reload.branding.brand_background).to eq("#F6EEF2")
      expect(tenant.branding.brand_600).to eq("#8E4B6B")
    end
  end

  it "turns a typed red over a blue background into the nearest valid tone, says so and paints it on the preview" do
    tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
    create(:branding, tenant: tenant, brand_background: "#0000FF", brand_600: "#F2B33D")
    adjusted = Branding::Tones.new(role: :brand_600, background: "#0000FF").nearest_valid("#FF0000")
    sign_in_owner(create(:user, tenant: tenant))
    visit "http://barbearia-do-ze.zubio.com.br#{edit_owner_brand_colors_path}"

    within(%(fieldset[aria-label="#{Components::Owner::BrandQuestion::Colors::ACCENT_LABEL}"])) do
      find("[data-more-toggle]", visible: :all).ancestor("label").click
      choose(option: Branding::CUSTOM_COLOR_CHOICE, allow_label_click: true)
      fill_in "branding[brand_600_custom]", with: "#FF0000"
    end

    expect(adjusted).not_to eq("#FF0000")
    expect(page).to have_field("branding[brand_600_custom]", with: adjusted)
    expect(page).to have_css("[data-tone-advice]", text: Components::Form::ColorTones::ADVICE_MESSAGE)
    expect(page).to have_css(%([data-color-swatch-target="preview"][data-preview-accent="#{adjusted}"]))
    expect(computed_hex("[data-preview-role='book']", "backgroundColor")).to eq(adjusted)
  end

  it "reajusts the chosen accent when the background turns light, keeping the samples, and saves without error" do
    tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
    create(:branding, :with_background, tenant: tenant)
    reajusted = Branding::Palette.accent_suggestions(background: "#F4F6F8").first
    sign_in_owner(create(:user, tenant: tenant))
    visit "http://barbearia-do-ze.zubio.com.br#{edit_owner_brand_colors_path}"

    within(%(fieldset[aria-label="#{Components::Owner::BrandQuestion::Colors::BACKGROUND_LABEL}"])) { choose(option: "#F4F6F8", allow_label_click: true) }
    expect(page).to have_css(%(turbo-frame#accent-swatches input[value="#{reajusted}"]:checked), visible: :all)
    click_on Views::Owner::BrandQuestions::Edit::SUBMIT_LABEL

    expect(reajusted).not_to eq("#F0617A")
    expect(page).to have_css("turbo-frame#accent-swatches [data-swatch]", count: Branding::Palette::ACCENTS.size)
    expect(page).to have_text(Owner::BrandQuestionsController::NOTICE)
    ActsAsTenant.with_tenant(tenant) { expect(tenant.reload.branding.brand_600).to eq(reajusted) }
  end

  it "finds the chosen accent again after a second background change" do
    tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
    create(:branding, :with_background, tenant: tenant)
    reajusted = Branding::Palette.accent_suggestions(background: "#F4F6F8").first
    sign_in_owner(create(:user, tenant: tenant))
    visit "http://barbearia-do-ze.zubio.com.br#{edit_owner_brand_colors_path}"
    within(%(fieldset[aria-label="#{Components::Owner::BrandQuestion::Colors::BACKGROUND_LABEL}"])) { choose(option: "#F4F6F8", allow_label_click: true) }
    expect(page).to have_css(%(turbo-frame#accent-swatches input[value="#{reajusted}"]:checked), visible: :all)

    within(%(fieldset[aria-label="#{Components::Owner::BrandQuestion::Colors::BACKGROUND_LABEL}"])) { choose(option: "#16324A", allow_label_click: true) }

    expect(page).to have_css(%(turbo-frame#accent-swatches input[value="#F0617A"]:checked), visible: :all)
    expect(page).to have_css(%([data-color-swatch-target="preview"][data-preview-accent="#F0617A"]))
  end
end
