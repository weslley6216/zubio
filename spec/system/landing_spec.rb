require "rails_helper"

RSpec.describe "Landing page appearance", type: :system, js: true do
  def emulate_color_scheme(value)
    page.driver.browser.page.command(
      "Emulation.setEmulatedMedia",
      features: [ { name: "prefers-color-scheme", value: value } ]
    )
  end

  def computed(selector, property)
    page.evaluate_script(
      "getComputedStyle(document.querySelector(#{selector.to_json})).#{property}"
    )
  end

  it "loads the platform typeface" do
    visit "http://zubio.com.br/"

    expect(page).to have_css("[data-landing-root]")
    expect(page.evaluate_script(%(document.fonts.check('1em "Plus Jakarta Sans"')))).to be true
  end

  it "paints the light surface tokens under a light color scheme" do
    emulate_color_scheme("light")

    visit "http://zubio.com.br/"

    expect(computed("[data-landing-root]", "backgroundColor")).to eq("rgb(244, 246, 248)")
  end

  it "paints the dark surface tokens under a dark color scheme" do
    emulate_color_scheme("dark")

    visit "http://zubio.com.br/"

    expect(computed("[data-landing-root]", "backgroundColor")).to eq("rgb(11, 17, 23)")
  end
end
