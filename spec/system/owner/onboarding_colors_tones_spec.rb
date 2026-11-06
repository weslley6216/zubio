require "rails_helper"

RSpec.describe "Onboarding colors tones selector", type: :system, js: true do
  it "offers the same hue bar and valid tones while the onboarding gate is still open" do
    owner = create(:user, :with_professional, name: "Ana Lima", tenant: create(:tenant, :onboarding))
    expected = Branding::Tones.new(role: :brand_600, background: "#16324A").options(120)
    sign_in_owner(owner)
    click_on "Começar"
    within(%(fieldset[aria-label="#{Components::Owner::BrandQuestion::Colors::BACKGROUND_LABEL}"])) { choose(option: "#16324A", allow_label_click: true) }
    within(%(fieldset[aria-label="#{Components::Owner::BrandQuestion::Colors::ACCENT_LABEL}"])) do
      find("[data-more-toggle]", visible: :all).ancestor("label").click
      choose(option: Branding::CUSTOM_COLOR_CHOICE, allow_label_click: true)
    end
    page.driver.clear_network_traffic

    find("[data-onboarding-section='colors'] input[data-hue]").execute_script("this.value = 120; this.dispatchEvent(new Event('input', { bubbles: true }))")

    expect(page).to have_css("turbo-frame#tones-brand_600 [data-tone]", count: expected.size)
    expect(all("turbo-frame#tones-brand_600 [data-tone]", visible: :all).map { |tone| tone["value"] }).to eq(expected)
    expect(page.driver.network_traffic.find { |exchange| exchange.url&.include?("/owner/brand_color_tones") }.response.status).to eq(200)
    expect(page).to fit_the_phone_width
  end

  it "keeps the previous tones on screen while the new ones load" do
    owner = create(:user, :with_professional, name: "Ana Lima", tenant: create(:tenant, :onboarding))
    sign_in_owner(owner)
    click_on "Começar"
    within(%(fieldset[aria-label="#{Components::Owner::BrandQuestion::Colors::ACCENT_LABEL}"])) do
      find("[data-more-toggle]", visible: :all).ancestor("label").click
      choose(option: Branding::CUSTOM_COLOR_CHOICE, allow_label_click: true)
    end

    tones_during_load = page.evaluate_script(<<~JS)
      (() => {
        const hue = document.querySelector("[data-onboarding-section='colors'] input[data-hue]")
        hue.value = 200
        hue.dispatchEvent(new Event("input", { bubbles: true }))
        return document.querySelectorAll("#tones-brand_600 [data-tone]").length
      })()
    JS

    expect(tones_during_load).to be_positive
  end
end
