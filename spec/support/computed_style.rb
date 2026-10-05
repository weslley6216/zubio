module ComputedStyle
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

  def computed_hex(selector, property)
    "#" + computed(selector, property).scan(/\d+/).first(3).map { |channel| channel.to_i.to_s(16).rjust(2, "0") }.join.upcase
  end

  def contrast_ratio(selector)
    foreground = Branding::ColorScale.new(computed_hex(selector, "color"))
    background = Branding::ColorScale.new(computed_hex(selector, "backgroundColor"))

    foreground.contrast_against(background)
  end

  def border_contrast_ratio(selector)
    border = Branding::ColorScale.new(computed_hex(selector, "borderTopColor"))
    background = Branding::ColorScale.new(computed_hex(selector, "backgroundColor"))

    border.contrast_against(background)
  end

  def opaque?(selector)
    computed(selector, "backgroundColor").start_with?("rgb(")
  end
end

RSpec.configure do |config|
  config.include ComputedStyle, type: :system
end
