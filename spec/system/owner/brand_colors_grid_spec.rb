require "rails_helper"

RSpec.describe "Owner brand colors without JavaScript", type: :system do
  it "reaches the full grid through the plus and saves a swatch from it" do
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    owner = create(:user, tenant: tenant, email: "owner@example.com", password: "s3cr3t123")
    create(:branding, tenant: tenant, brand_600: "#4F46E5")

    visit "http://#{tenant.subdomain}.zubio.com.br#{new_owner_session_path}"
    fill_in "E-mail", with: owner.email
    fill_in "Senha", with: "s3cr3t123"
    click_on "Entrar"
    visit "http://#{tenant.subdomain}.zubio.com.br#{edit_owner_brand_colors_path}"

    within(%(fieldset[aria-label="#{Components::Owner::BrandQuestion::Colors::BRAND_LABEL}"])) do
      find("summary", match: :first).click
      choose(option: "#7E22CE", allow_label_click: true)
    end
    click_on Views::Owner::BrandQuestions::Edit::SUBMIT_LABEL

    ActsAsTenant.with_tenant(tenant) { expect(tenant.reload.branding.brand_600).to eq("#7E22CE") }
  end
end
