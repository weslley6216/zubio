require "rails_helper"

RSpec.describe "Owner share link", type: :system, js: true do
  it "confirms the copy by swapping the button label" do
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    owner = create(:user, tenant: tenant, email: "owner@example.com", password: "s3cr3t123")
    create(:branding, tenant: tenant)
    sign_in_owner(tenant, owner)

    page.execute_script(<<~JS)
      Object.defineProperty(navigator, "clipboard", {
        configurable: true,
        value: { writeText: () => Promise.resolve() }
      })
    JS
    click_button Components::Owner::ShareLink::COPY_LABEL

    expect(page).to have_content(Components::Owner::ShareLink::COPIED_LABEL)
  end

  it "keeps the address visible and raises no error without a clipboard" do
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    owner = create(:user, tenant: tenant, email: "owner@example.com", password: "s3cr3t123")
    create(:branding, tenant: tenant)
    sign_in_owner(tenant, owner)

    click_button Components::Owner::ShareLink::COPY_LABEL

    expect(page).to have_content("estudio-aurora.zubio.com.br")
    expect(page).to have_button(Components::Owner::ShareLink::COPY_LABEL)
  end
end
