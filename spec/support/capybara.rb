require "capybara/rspec"
require "capybara/cuprite"

# Capybara's own RSpec integration sets `Capybara.current_driver =
# Capybara.javascript_driver if example.metadata[:js]` on every example —
# defaulting javascript_driver here keeps `:js` specs on Cuprite regardless
# of RSpec hook registration order.
Capybara.javascript_driver = :cuprite

# `driven_by` on a `type: :system` group runs through
# ActionDispatch::SystemTestCase.driven_by, which re-registers :cuprite
# itself (see actionpack's SystemTesting::Driver#register) — any
# Capybara.register_driver(:cuprite) block defined here would be silently
# overwritten. Browser flags must go through the `options:` kwarg instead.
RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  # process_timeout is a ceiling, not a wait: a fast browser boot never pays it.
  # 15s was tight enough for Chrome to miss it on a loaded CI runner while four
  # test processes competed for CPU, failing the suite with no defect behind it.
  config.before(:each, type: :system, js: true) do
    driven_by :cuprite, screen_size: [ 1200, 800 ], options: {
      process_timeout: 60,
      browser_options: {
        "no-sandbox" => nil,
        "disable-gpu" => nil
      }
    }
  end
end
