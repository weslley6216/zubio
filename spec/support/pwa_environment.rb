module PwaEnvironment
  IPHONE_USER_AGENT = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1".freeze
  ANDROID_USER_AGENT = "Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36".freeze
  DESKTOP_USER_AGENT = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36".freeze

  def emulate_android
    emulate_device(user_agent: ANDROID_USER_AGENT, mobile: true, standalone: false, coarse_pointer: true)
  end

  def emulate_iphone
    emulate_device(user_agent: IPHONE_USER_AGENT, mobile: nil, standalone: false, coarse_pointer: true)
  end

  def emulate_installed_app
    emulate_device(user_agent: ANDROID_USER_AGENT, mobile: true, standalone: true, coarse_pointer: true)
  end

  def emulate_desktop
    emulate_device(user_agent: DESKTOP_USER_AGENT, mobile: false, standalone: false, coarse_pointer: false)
  end

  def fire_before_install_prompt
    page.execute_script(<<~JS)
      const event = new Event("beforeinstallprompt")
      event.prompt = () => { window.__pwaPromptCalled = true }
      window.dispatchEvent(event)
    JS
  end

  def fire_app_installed
    page.execute_script('window.dispatchEvent(new Event("appinstalled"))')
  end

  def install_prompt_called?
    page.evaluate_script("window.__pwaPromptCalled === true")
  end

  private

  def emulate_device(user_agent:, mobile:, standalone:, coarse_pointer:)
    user_agent_data = mobile.nil? ? "undefined" : "({ mobile: #{mobile} })"
    page.driver.browser.page.command(
      "Page.addScriptToEvaluateOnNewDocument",
      source: <<~JS
        Object.defineProperty(navigator, "userAgent", { get: () => #{user_agent.to_json} })
        Object.defineProperty(navigator, "userAgentData", { get: () => #{user_agent_data} })
        Object.defineProperty(navigator, "standalone", { get: () => #{standalone} })
        const nativeMatchMedia = window.matchMedia.bind(window)
        const stub = (matches, query) => ({
          matches, media: query, onchange: null,
          addEventListener() {}, removeEventListener() {},
          addListener() {}, removeListener() {}, dispatchEvent() { return false }
        })
        window.matchMedia = (query) => {
          if (query === "(display-mode: standalone)") return stub(#{standalone}, query)
          if (query === "(pointer: coarse)") return stub(#{coarse_pointer}, query)
          return nativeMatchMedia(query)
        }
      JS
    )
  end
end

RSpec.configure do |config|
  config.include PwaEnvironment, type: :system
end
