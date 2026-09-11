require "rails_helper"

RSpec.describe "Owner branding on one screen", type: :system, js: true do
  let(:phone_screen) { [ 430, 800 ] }
  let(:narrow_screen) { [ 320, 800 ] }
  let(:stored_color) { "#FF5A5F" }
  let(:picked_color) { "#BE123C" }
  let(:off_palette_color) { "#8E4B6B" }

  def open_branding(tenant, owner, screen: phone_screen)
    page.driver.resize(*screen)
    sign_in_owner(tenant, owner)
    visit "http://#{tenant.subdomain}.zubio.com.br#{edit_owner_branding_path}"
  end

  def establishment(brand_600: stored_color)
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    create(:branding, tenant: tenant, brand_600: brand_600)

    [ tenant, create(:user, tenant: tenant, email: "owner@example.com") ]
  end

  def scroll_width = page.evaluate_script("document.documentElement.scrollWidth")

  def taller_than_screen?
    page.evaluate_script("document.documentElement.scrollHeight > window.innerHeight")
  end

  it "fits the name, both colors, the logo and the action on a phone screen without scrolling" do
    open_branding(*establishment)

    expect(page).to have_button(Views::Owner::Brandings::Edit::SUBMIT_LABEL)
    expect(taller_than_screen?).to be false
  end

  it "keeps the widest row inside the narrowest phone, with the typed code unfolded" do
    open_branding(*establishment(brand_600: off_palette_color), screen: narrow_screen)

    expect(page).to have_css(%(input[name="branding[brand_600_custom]"][value="#{off_palette_color}"]))
    expect(scroll_width).to eq(narrow_screen.first)
  end

  it "shows the whole palette at once, with no swatch left out of the grid" do
    open_branding(*establishment)

    within_fieldset(Views::Owner::Brandings::Edit::BRAND_LABEL) do
      expect(page).to have_css("[data-swatch]", count: Branding::Palette.swatches.size)
    end
  end

  it "unfolds the second palette only when the owner asks for a color of its own" do
    open_branding(*establishment)

    within_fieldset(Views::Owner::Brandings::Edit::SECONDARY_LABEL) do
      expect(page).to have_no_css("[data-swatch]")

      click_on Components::Form::ColorSwatches::OWN_LABEL

      expect(page).to have_css("[data-swatch]", count: Branding::Palette.swatches.size)

      choose Views::Owner::Brandings::Edit::SECONDARY_LINKED_LABEL, allow_label_click: true

      expect(page).to have_no_css("[data-swatch]")
    end
  end

  it "reads the picked color back as a code beside the grid" do
    open_branding(*establishment)

    within_fieldset(Views::Owner::Brandings::Edit::BRAND_LABEL) do
      expect(page).to have_content(stored_color)

      find(%([data-swatch="#{picked_color}"])).click

      expect(page).to have_content(picked_color)
      expect(page).to have_no_content(stored_color)
    end
  end
end
