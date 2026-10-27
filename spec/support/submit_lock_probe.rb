module SubmitLockProbe
  def submit_lock_state(button_selector, action_js)
    JSON.parse(page.evaluate_script(<<~JS))
      (function() {
        const button = document.querySelector(#{button_selector.to_json})
        #{action_js}
        return JSON.stringify({ disabled: button.disabled, label: button.textContent })
      })()
    JS
  end
end

RSpec.configure do |config|
  config.include SubmitLockProbe, type: :system
end
