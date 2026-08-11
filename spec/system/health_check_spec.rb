require "rails_helper"

RSpec.describe "Health check", type: :system do
  it "loads over rack_test by default" do
    visit "/up"

    expect(page).to have_css("body[style*='background-color: green']")
  end

  it "loads through a real headless browser", js: true do
    visit "/up"

    expect(page).to have_css("body[style*='background-color: green']")
  end
end
