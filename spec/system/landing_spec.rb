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

  def contrast_ratio(selector)
    foreground = color_scale(computed(selector, "color"))
    background = color_scale(computed(selector, "backgroundColor"))

    foreground.contrast_against(background)
  end

  # getComputedStyle reports an unpainted background as "rgba(0, 0, 0, 0)", which
  # would read as pure black and score a perfect ratio against white text.
  def opaque?(selector)
    computed(selector, "backgroundColor").start_with?("rgb(")
  end

  def color_scale(rgb)
    channels = rgb.scan(/\d+/).first(3).map { |channel| channel.to_i.to_s(16).rjust(2, "0") }

    Branding::ColorScale.new("##{channels.join}")
  end

  it "loads the platform typeface" do
    visit "http://zubio.com.br/"

    expect(page).to have_css("[data-landing-root]")
    expect(page.evaluate_script(%(document.fonts.check('1em "Plus Jakarta Sans"')))).to be true
  end

  it "paints the light surface tokens under a light color scheme" do
    emulate_color_scheme("light")

    visit "http://zubio.com.br/"

    expect(computed("html", "backgroundColor")).to eq("rgb(244, 246, 248)")
    expect(computed("html", "colorScheme")).to eq("light dark")
  end

  it "paints the dark surface tokens under a dark color scheme" do
    emulate_color_scheme("dark")

    visit "http://zubio.com.br/"

    expect(computed("html", "backgroundColor")).to eq("rgb(11, 17, 23)")
  end

  it "paints the previewed establishment in its own brand color, not a broken token" do
    visit "http://zubio.com.br/"

    expect(computed("[data-demo-bar]", "backgroundColor")).to eq("rgb(90, 63, 224)")
  end

  it "keeps the previewed establishment readable in both color schemes" do
    %w[light dark].each do |scheme|
      emulate_color_scheme(scheme)

      visit "http://zubio.com.br/"

      expect(opaque?("[data-demo-bar]")).to be true
      expect(contrast_ratio("[data-demo-bar]")).to be >= Branding::ColorScale::MIN_CONTRAST
    end
  end

  it "keeps the whole signup call to action inside the first screen on a small phone" do
    page.driver.resize(375, 667)

    visit "http://zubio.com.br/"

    bottom_edge = page.evaluate_script("document.getElementById('hero-cta').getBoundingClientRect().bottom")
    expect(bottom_edge).to be <= 667
  end

  it "swaps the previewed establishment when another identity is picked" do
    visit "http://zubio.com.br/"

    expect(page).to have_css('[data-demo-brand="salao"]')
    expect(page).to have_content("Studio Aurora")

    click_on "Barbearia"

    expect(page).to have_css('[data-demo-brand="barbearia"]')
    expect(page).to have_content("Barbearia Norte")
    expect(page).to have_css('button[aria-pressed="true"]', text: "Barbearia")
  end
end
