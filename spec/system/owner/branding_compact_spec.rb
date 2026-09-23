require "rails_helper"

RSpec.describe "Owner branding on one screen", type: :system, js: true do
  let(:phone_screen) { [ 430, 800 ] }
  let(:narrow_screen) { [ 320, 800 ] }

  def establishment
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    create(:branding, tenant: tenant, brand_600: "#4F46E5")

    [ tenant, create(:user, tenant: tenant, email: "owner@example.com") ]
  end

  def open(tenant, owner, path, screen: phone_screen)
    page.driver.resize(*screen)
    sign_in_owner(tenant, owner)
    visit "http://#{tenant.subdomain}.zubio.com.br#{path}"
  end

  def taller_than_screen?
    page.evaluate_script("document.documentElement.scrollHeight > window.innerHeight")
  end

  def scroll_width = page.evaluate_script("document.documentElement.scrollWidth")

  def ramp(hex) = Branding.ramp_variables("brand", Branding::ColorScale.new(hex))

  def role(hex, name) = ramp(hex)[/--#{name}:(#\h{6});/, 1]

  def rgb(hex) = "rgb(#{hex.delete('#').scan(/../).map { |channel| channel.to_i(16) }.join(', ')})"

  it "fits each brand question on a phone screen without scrolling" do
    tenant, owner = establishment

    [ edit_owner_brand_colors_path, edit_owner_brand_name_path, edit_owner_brand_logo_path ].each do |path|
      open(tenant, owner, path)

      expect(page).to have_button(Views::Owner::BrandQuestions::Edit::SUBMIT_LABEL)
      expect(taller_than_screen?).to be(false)
    end
  end

  it "keeps the brand row inside the narrowest phone" do
    open(*establishment, edit_owner_brand_colors_path, screen: narrow_screen)

    expect(scroll_width).to eq(narrow_screen.first)
  end

  it "repaints the two-color preview live as a swatch is chosen, in both color schemes" do
    tenant, owner = establishment

    %w[light dark].each do |scheme|
      emulate_color_scheme(scheme)
      sign_in_owner(tenant, owner)
      visit "http://#{tenant.subdomain}.zubio.com.br#{edit_owner_brand_colors_path}"
      within(%(fieldset[aria-label="#{Components::Owner::BrandQuestion::Colors::BRAND_LABEL}"])) do
        find(%([data-row-option] [data-swatch="#BE123C"])).click
      end

      step = scheme == "light" ? "brand-600" : "brand-400"
      expect(computed("[data-color-swatch-target='preview'] .bg-brand-accent", "backgroundColor")).to eq(rgb(role("#BE123C", step)))
    end
  end
end
