require "rails_helper"

RSpec.describe "Owner brand logo", type: :system, js: true do
  def establishment
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    create(:branding, tenant: tenant)

    [ tenant, create(:user, tenant: tenant, email: "owner@example.com") ]
  end

  def open(tenant, owner)
    sign_in_owner(tenant, owner)
    visit "http://#{tenant.subdomain}.zubio.com.br#{edit_owner_brand_logo_path}"
  end

  it "swaps the preview to the newly chosen image" do
    tenant, owner = establishment
    open(tenant, owner)

    find("input[type=file]", visible: :all, match: :first).attach_file(Rails.root.join("spec/fixtures/files/logo.png"))

    expect(page).to have_css("img[data-logo-target='preview']:not([hidden])")
    expect(find("img[data-logo-target='preview']")[:src]).to start_with("blob:")
    expect(page).to have_css("img[data-logo-target='preview']") { |preview| preview.evaluate_script("this.naturalWidth") > 0 }
    expect(page).to have_css("[data-logo-target='placeholder'][hidden]", visible: :all)
  end

  it "refuses an oversized file and clears the field" do
    tenant, owner = establishment
    open(tenant, owner)
    oversized = Tempfile.new([ "huge", ".png" ])
    oversized.write("0" * (Branding::LOGO_MAX_BYTES + 1))
    oversized.rewind

    find("input[type=file]", visible: :all, match: :first).attach_file(oversized.path)

    expect(page).to have_content("não foi aceita")
    expect(page).to have_css("img[data-logo-target='preview'][hidden]", visible: :all)
  end

  it "refuses a file whose type is not in the allowlist and clears the field" do
    tenant, owner = establishment
    open(tenant, owner)

    find("input[type=file]", visible: :all, match: :first).attach_file(Rails.root.join("spec/fixtures/files/not-an-image.txt"))

    expect(page).to have_content("não foi aceita")
    expect(page).to have_css("img[data-logo-target='preview'][hidden]", visible: :all)
  end
end
