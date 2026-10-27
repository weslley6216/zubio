require "rails_helper"

RSpec.describe "Turbo progress bar", type: :system, js: true do
  it "paints the progress bar with the tenant brand color at 2px" do
    tenant = create(:tenant, subdomain: "mary", name: "Mary Sombracelhas")
    create(:branding, tenant: tenant, brand_600: "#8E4B6B")

    visit "http://#{tenant.subdomain}.zubio.com.br#{establishment_path}"
    page.execute_script('document.body.insertAdjacentHTML("beforeend", "<div class=\"turbo-progress-bar\"></div>")')

    expect(computed_hex(".turbo-progress-bar", "backgroundColor")).to eq("#8E4B6B")
    expect(computed(".turbo-progress-bar", "height")).to eq("2px")
  end

  it "waits 800ms before showing the bar" do
    tenant = create(:tenant, subdomain: "mary", name: "Mary Sombracelhas")
    create(:branding, tenant: tenant, brand_600: "#8E4B6B")

    visit "http://#{tenant.subdomain}.zubio.com.br#{establishment_path}"

    expect(page.evaluate_script("Turbo.config.drive.progressBarDelay")).to eq(800)
  end

  it "uses each tenant's own brand color" do
    mary = create(:tenant, subdomain: "mary", name: "Mary Sombracelhas")
    create(:branding, tenant: mary, brand_600: "#8E4B6B")
    ze = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
    create(:branding, tenant: ze, brand_600: "#2C6CB0")

    visit "http://#{ze.subdomain}.zubio.com.br#{establishment_path}"
    page.execute_script('document.body.insertAdjacentHTML("beforeend", "<div class=\"turbo-progress-bar\"></div>")')

    expect(computed_hex(".turbo-progress-bar", "backgroundColor")).to eq("#2C6CB0")
    expect(computed_hex(".turbo-progress-bar", "backgroundColor")).not_to eq("#8E4B6B")
  end
end
