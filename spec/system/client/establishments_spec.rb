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
end
