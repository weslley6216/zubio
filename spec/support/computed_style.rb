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

  def contrast_ratio(selector)
    foreground = color_scale(computed(selector, "color"))
    background = color_scale(computed(selector, "backgroundColor"))

    foreground.contrast_against(background)
  end

  def opaque?(selector)
    computed(selector, "backgroundColor").start_with?("rgb(")
  end

  def color_scale(rgb)
    channels = rgb.scan(/\d+/).first(3).map { |channel| channel.to_i.to_s(16).rjust(2, "0") }

    Branding::ColorScale.new("##{channels.join}")
  end
end

RSpec.configure do |config|
  config.include ComputedStyle, type: :system
end
