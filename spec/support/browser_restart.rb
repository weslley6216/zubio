module BrowserRestart
  def discard_session_cookies
    browser_page = page.driver.browser.page
    cookies = browser_page.command("Network.getAllCookies").fetch("cookies", [])
    cookies.select { |cookie| cookie["session"] }.each do |cookie|
      browser_page.command("Network.deleteCookies", name: cookie["name"], domain: cookie["domain"], path: cookie["path"])
    end
  end
end

RSpec.configure do |config|
  config.include BrowserRestart, type: :system
end
