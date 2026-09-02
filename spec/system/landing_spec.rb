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

  def faq_summary_heights_script
    <<~JS
      Array.from(document.querySelectorAll("#faq summary")).map(
        (element) => element.getBoundingClientRect().height
      )
    JS
  end

  def control_cursors_script
    <<~JS
      Array.from(document.querySelectorAll("button, summary")).map(
        (element) => getComputedStyle(element).cursor
      )
    JS
  end

  def clipped_details_script
    <<~JS
      Array.from(document.querySelectorAll("[data-agenda-detail]")).some(
        (element) => element.scrollWidth > element.clientWidth
      )
    JS
  end

  def color_scale(rgb)
    channels = rgb.scan(/\d+/).first(3).map { |channel| channel.to_i.to_s(16).rjust(2, "0") }

    Branding::ColorScale.new("##{channels.join}")
  end

  it "loads the platform typeface" do
    visit "http://zubio.com.br/"

    expect(page).to have_css("[data-landing-root]")
    expect(computed("body", "fontFamily")).to include("Plus Jakarta Sans")
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

  it "draws a branded focus ring for whoever navigates by keyboard" do
    emulate_color_scheme("light")
    visit "http://zubio.com.br/"

    find("body").send_keys(:tab)

    expect(page.evaluate_script(%(document.activeElement.matches("a, button, summary")))).to be true
    expect(page.evaluate_script("getComputedStyle(document.activeElement).outlineColor")).to eq("rgb(79, 70, 229)")
  end

  it "gives every FAQ question a target a thumb can hit" do
    visit "http://zubio.com.br/"

    heights = page.evaluate_script(faq_summary_heights_script)
    expect(heights.size).to eq(Views::Pages::Home::Faq::QUESTIONS.size)
    expect(heights.min).to be >= 44
  end

  it "points the cursor at every control, which the framework reset does not do for buttons" do
    visit "http://zubio.com.br/"

    cursors = page.evaluate_script(control_cursors_script)
    expect(cursors).not_to be_empty
    expect(cursors.uniq).to eq([ "pointer" ])
  end

  it "repaints the page in the other theme when the visitor asks for it" do
    emulate_color_scheme("dark")
    visit "http://zubio.com.br/"

    expect(computed("html", "backgroundColor")).to eq("rgb(11, 17, 23)")

    click_button Views::Pages::Home::SiteHeader::TOGGLE_LABEL

    expect(computed("html", "backgroundColor")).to eq("rgb(244, 246, 248)")
  end

  it "keeps the chosen theme on the next visit, against the system preference" do
    emulate_color_scheme("dark")
    visit "http://zubio.com.br/"
    click_button Views::Pages::Home::SiteHeader::TOGGLE_LABEL

    visit "http://zubio.com.br/"

    expect(page.evaluate_script("document.documentElement.dataset.theme")).to eq("light")
    expect(computed("html", "backgroundColor")).to eq("rgb(244, 246, 248)")
  end

  it "never pushes the page sideways on a small phone" do
    page.driver.resize(375, 667)

    visit "http://zubio.com.br/"

    overflow = page.evaluate_script("document.documentElement.scrollWidth - document.documentElement.clientWidth")
    expect(overflow).to be <= 0
  end

  it "shows every appointment description in full on a small phone" do
    page.driver.resize(375, 667)

    visit "http://zubio.com.br/"

    details = page.all("[data-agenda-detail]", visible: :all)
    expect(details.size).to eq(Views::Pages::Home::DashboardPreview::APPOINTMENTS.size)
    expect(page.evaluate_script(clipped_details_script)).to be false
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
