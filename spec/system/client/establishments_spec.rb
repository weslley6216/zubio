require "rails_helper"

RSpec.describe "Public establishment showcase appearance", type: :system, js: true do
  it "spans the header the full width and centers the sheet on a desktop screen" do
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    create(:service, tenant: tenant, name: "Corte feminino")
    emulate_desktop_screen(width: 1280)

    visit "http://#{tenant.subdomain}.zubio.com.br/"

    expect(page.evaluate_script("document.querySelector('header').getBoundingClientRect().width === window.innerWidth")).to be(true)
    expect(page.evaluate_script(<<~JS)).to be(true)
      (() => {
        const main = document.querySelector('main').getBoundingClientRect();
        return main.left >= 0 && main.right <= window.innerWidth && main.width <= 672;
      })()
    JS
  end

  it "fits the phone width with every service card a touch target" do
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    create(:service, tenant: tenant, name: "Corte feminino")

    visit "http://#{tenant.subdomain}.zubio.com.br/"

    expect(page).to fit_the_phone_width
    expect(page.evaluate_script("document.querySelector('[data-catalog] li').getBoundingClientRect().height")).to be >= 44
  end

  it "fills the showcase emblem with the logo cover-cropped at 56px with the canvas radius" do
    tenant = create(:tenant, subdomain: "mary-sombracelhas", name: "Mary Sombracelhas")
    create(:branding, :with_wide_logo, tenant: tenant)
    create(:service, tenant: tenant, name: "Design de sobrancelhas")

    visit "http://#{tenant.subdomain}.zubio.com.br/"

    emblem = find("[data-brand-logo]")
    expect(emblem.evaluate_script("getComputedStyle(this).objectFit")).to eq("cover")
    expect(emblem.evaluate_script("this.getBoundingClientRect().width")).to be_within(0.5).of(56)
    expect(emblem.evaluate_script("this.getBoundingClientRect().height")).to be_within(0.5).of(56)
    expect(emblem.evaluate_script("getComputedStyle(this).borderTopLeftRadius")).to eq("16px")
  end
end
