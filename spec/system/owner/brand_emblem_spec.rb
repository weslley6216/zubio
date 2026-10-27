require "rails_helper"

RSpec.describe "Owner panel brand emblem", type: :system, js: true do
  it "fills the header emblem with the logo cover-cropped at 36px with the canvas radius on a phone" do
    tenant = create(:tenant, subdomain: "mary-sombracelhas", name: "Mary Sombracelhas")
    create(:branding, :with_wide_logo, tenant: tenant)
    sign_in_owner(create(:user, tenant: tenant))

    visit "http://#{tenant.subdomain}.zubio.com.br#{owner_appointments_path}"

    emblem = find("[data-brand-logo]")
    expect(emblem.evaluate_script("getComputedStyle(this).objectFit")).to eq("cover")
    expect(emblem.evaluate_script("this.getBoundingClientRect().width")).to be_within(0.5).of(36)
    expect(emblem.evaluate_script("getComputedStyle(this).borderTopLeftRadius")).to eq("10px")
  end

  it "keeps the same cover crop and radius in the desktop band" do
    tenant = create(:tenant, subdomain: "mary-sombracelhas", name: "Mary Sombracelhas")
    create(:branding, :with_wide_logo, tenant: tenant)
    sign_in_owner(create(:user, tenant: tenant))
    emulate_desktop_screen(width: 1280)

    visit "http://#{tenant.subdomain}.zubio.com.br#{owner_appointments_path}"

    emblem = find("[data-brand-logo]")
    expect(emblem.evaluate_script("getComputedStyle(this).objectFit")).to eq("cover")
    expect(emblem.evaluate_script("this.getBoundingClientRect().width")).to be_within(0.5).of(36)
    expect(emblem.evaluate_script("getComputedStyle(this).borderTopLeftRadius")).to eq("10px")
  end
end
