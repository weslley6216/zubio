require "rails_helper"

RSpec.describe "Registration footer", type: :system, js: true do
  it "rests the signup footer at the bottom of a phone screen, with no band below it" do
    page.driver.resize(390, 800)

    visit new_signup_url(host: Tenant::PLATFORM_HOST)

    expect(page.evaluate_script("document.documentElement.scrollHeight > window.innerHeight")).to be(false)
    expect(page.evaluate_script("document.querySelector('footer').getBoundingClientRect().bottom"))
      .to be_within(2).of(page.evaluate_script("window.innerHeight"))
  end

  it "rests the login link request footer at the bottom of a phone screen, with no band below it" do
    page.driver.resize(390, 800)

    visit new_login_link_url(host: Tenant::PLATFORM_HOST)

    expect(page.evaluate_script("document.documentElement.scrollHeight > window.innerHeight")).to be(false)
    expect(page.evaluate_script("document.querySelector('footer').getBoundingClientRect().bottom"))
      .to be_within(2).of(page.evaluate_script("window.innerHeight"))
  end
end
