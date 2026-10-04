require "rails_helper"

RSpec.describe "Registration footer", type: :system, js: true do
  def footer_bottom = page.evaluate_script("document.querySelector('footer').getBoundingClientRect().bottom")

  def inner_height = page.evaluate_script("window.innerHeight")

  def taller_than_screen? = page.evaluate_script("document.documentElement.scrollHeight > window.innerHeight")

  {
    "signup" => "new_signup_url",
    "login link request" => "new_login_link_url"
  }.each do |screen, helper|
    it "rests the #{screen} footer at the bottom of a phone screen, with no band below it" do
      page.driver.resize(390, 800)
      visit send(helper, host: Tenant::PLATFORM_HOST)

      expect(taller_than_screen?).to be(false)
      expect(footer_bottom).to be_within(2).of(inner_height)
    end
  end
end
