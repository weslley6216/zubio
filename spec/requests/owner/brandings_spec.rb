require "rails_helper"

RSpec.describe "Owner branding", type: :request do
  let(:tenant) { create(:tenant, subdomain: "joes-barbershop", name: "Joe's Barbershop") }
  let(:owner) { create(:user, tenant: tenant, email: "owner@example.com", password: "s3cr3t123") }

  before do
    host! "#{tenant.subdomain}.zubio.com.br"
    post owner_session_path, params: { email: owner.email, password: "s3cr3t123" }
  end

  describe "GET /owner/branding/edit" do
    it "renders the current tenant's branding form" do
      create(:branding, tenant: tenant, brand_600: "#2F6FED")

      get edit_owner_branding_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("#2F6FED")
    end

    it "shows the current logo and a removal option when one is attached" do
      create(:branding, :with_logo, tenant: tenant, brand_600: "#4F46E5")

      get edit_owner_branding_path

      expect(response.body).to include("Remover logotipo atual")
      expect(response.body).to include("/rails/active_storage/representations/proxy/")
      expect(response.body).not_to include("/rails/active_storage/blobs/proxy/")
    end

    it "renders the authenticated header with a way back to the panel, a way out of the session, the brand on the emblem and the secondary on the current section" do
      create(:branding, tenant: tenant, brand_600: "#2F6FED")

      get edit_owner_branding_path

      expect(response.body).to include(%(href="#{owner_dashboard_path}"))
      expect(response.body).to include(%(action="#{owner_session_path}"))
      expect(response.body).to include(%(value="delete"))
      expect(response.body).to include("bg-brand-accent")
      expect(response.body).to include(Components::Owner::Header::CURRENT_CLASS)
      expect(Components::Owner::Header::CURRENT_CLASS).to include("bg-secondary-accent")
    end

    it "shows the whole palette as a grid, with the current color marked, without opening any dialog" do
      create(:branding, tenant: tenant, brand_600: Branding::Palette.swatches.first)

      get edit_owner_branding_path

      expect(response.body).not_to include("<datalist")
      Branding::Palette.swatches.each { |hex| expect(response.body).to include(%(data-swatch="#{hex}")) }
      expect(response.body).to include(%(value="#{Branding::Palette.swatches.first}" checked))
    end

    it "pulls in the sheet that paints the swatches, versioned by its own content" do
      create(:branding, tenant: tenant, brand_600: "#2F6FED")

      get edit_owner_branding_path

      expect(response.body).to include(palette_stylesheet_path(v: Branding::Palette.stylesheet_digest))
    end

    it "opens the customization and carries the code when the stored color is not on the palette" do
      create(:branding, tenant: tenant, brand_600: "#2F6FED")

      get edit_owner_branding_path

      expect(response.body).to include("<details open>")
      expect(response.body).to include(%(name="branding[brand_600_custom]"))
      expect(response.body).to include("#2F6FED")
    end

    it "offers a second color group that starts on the brand when none is stored" do
      create(:branding, tenant: tenant, brand_600: "#2F6FED")

      get edit_owner_branding_path

      expect(response.body).to include(%(name="branding[brand_secondary_600]"))
      expect(response.body).to include(Views::Owner::Brandings::Edit::SECONDARY_BLANK_LABEL)
      expect(response.body).to include(%(value="" checked))
    end
  end

  describe "PATCH /owner/branding" do
    it "updates the brand color" do
      create(:branding, tenant: tenant, brand_600: "#4F46E5")

      patch owner_branding_path, params: { tenant: { name: tenant.name }, branding: { brand_600: "#2F6FED" } }

      expect(response).to redirect_to(edit_owner_branding_path)
      ActsAsTenant.with_tenant(tenant) { expect(tenant.reload.branding.brand_600).to eq("#2F6FED") }
    end

    it "rejects a color without sufficient contrast and does not persist it" do
      create(:branding, tenant: tenant, brand_600: "#4F46E5")

      patch owner_branding_path, params: { tenant: { name: tenant.name }, branding: { brand_600: "#7A7A7A" } }

      expect(response).to have_http_status(:unprocessable_entity)
      ActsAsTenant.with_tenant(tenant) { expect(tenant.reload.branding.brand_600).to eq("#4F46E5") }
    end

    it "rejects a malformed color without crashing the page chrome and does not persist it" do
      create(:branding, tenant: tenant, brand_600: "#4F46E5")

      patch owner_branding_path, params: { tenant: { name: tenant.name }, branding: { brand_600: "not-a-hex" } }

      expect(response).to have_http_status(:unprocessable_entity)
      ActsAsTenant.with_tenant(tenant) { expect(tenant.reload.branding.brand_600).to eq("#4F46E5") }
    end

    it "saves a valid logo upload and enqueues variant precomputation in the background" do
      create(:branding, tenant: tenant, brand_600: "#4F46E5")
      logo = Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/logo.png"), "image/png")

      expect {
        patch owner_branding_path, params: { tenant: { name: tenant.name }, branding: { brand_600: "#4F46E5", logo: logo } }
      }.to have_enqueued_job(Branding::PrecomputeVariantsJob).with(tenant.id)

      expect(response).to redirect_to(edit_owner_branding_path)
      ActsAsTenant.with_tenant(tenant) { expect(tenant.reload.branding.logo).to be_attached }
    end

    it "rejects an unsupported logo file type without attaching it" do
      create(:branding, tenant: tenant, brand_600: "#4F46E5")
      pdf_file = Tempfile.new([ "logo", ".pdf" ])
      pdf_file.write("%PDF-1.4 fake pdf content")
      pdf_file.rewind

      patch owner_branding_path, params: {
        tenant: { name: tenant.name },
        branding: { brand_600: "#4F46E5", logo: Rack::Test::UploadedFile.new(pdf_file.path, "application/pdf") }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      ActsAsTenant.with_tenant(tenant) { expect(tenant.reload.branding.logo).not_to be_attached }
    ensure
      pdf_file.close!
    end

    it "rejects a logo above the size limit without attaching it" do
      create(:branding, tenant: tenant, brand_600: "#4F46E5")
      oversized = Tempfile.new([ "oversized_logo", ".png" ])
      oversized.write("a" * (Branding::LOGO_MAX_BYTES + 1))
      oversized.rewind

      patch owner_branding_path, params: {
        tenant: { name: tenant.name },
        branding: { brand_600: "#4F46E5", logo: Rack::Test::UploadedFile.new(oversized.path, "image/png") }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      ActsAsTenant.with_tenant(tenant) { expect(tenant.reload.branding.logo).not_to be_attached }
    ensure
      oversized.close!
    end

    it "updates the establishment name" do
      create(:branding, tenant: tenant, brand_600: "#4F46E5")

      patch owner_branding_path, params: { tenant: { name: "Studio Aurora" }, branding: { brand_600: "#4F46E5" } }

      ActsAsTenant.with_tenant(tenant) { expect(tenant.reload.name).to eq("Studio Aurora") }
    end

    it "removes the current logo when remove_logo is checked and no new file is sent" do
      create(:branding, :with_logo, tenant: tenant, brand_600: "#4F46E5")

      perform_enqueued_jobs do
        patch owner_branding_path, params: { tenant: { name: tenant.name }, branding: { brand_600: "#4F46E5", remove_logo: "1" } }
      end

      ActsAsTenant.with_tenant(tenant) { expect(tenant.reload.branding.logo).not_to be_attached }
    end

    it "does not update another tenant's branding" do
      other_tenant = create(:tenant, subdomain: "other-salon", name: "Other Salon")
      create(:branding, tenant: other_tenant, brand_600: "#000000")

      patch owner_branding_path, params: { tenant: { name: "Hijacked" }, branding: { brand_600: "#2F6FED" } }

      expect(other_tenant.reload.name).to eq("Other Salon")
      ActsAsTenant.with_tenant(other_tenant) { expect(other_tenant.branding.reload.brand_600).to eq("#000000") }
    end

    it "renders field errors through the shared component, in the danger token" do
      create(:branding, tenant: tenant, brand_600: "#4F46E5")

      patch owner_branding_path, params: { tenant: { name: "" }, branding: { brand_600: "#4F46E5" } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("text-danger")
      expect(response.body).not_to include("text-red-700")
    end

    it "confirms on the destination screen when the change lands, and states the refusal in the danger tone when it does not" do
      create(:branding, tenant: tenant, brand_600: "#4F46E5")

      patch owner_branding_path, params: { tenant: { name: tenant.name }, branding: { brand_600: "#2F6FED" } }
      follow_redirect!

      expect(response.body).to include("Marca atualizada.")
      expect(response.body).to include("bg-success-surface")
      expect(response.body).to include(%(<div role="status"))
      expect(response.body).not_to include("bg-danger-surface")
    end

    it "states the refusal in the danger tone on the same screen" do
      create(:branding, tenant: tenant, brand_600: "#4F46E5")

      patch owner_branding_path, params: { tenant: { name: "" }, branding: { brand_600: "#4F46E5" } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include(Owner::BrandingsController::REFUSED)
      expect(response.body).to include("bg-danger-surface")
      expect(response.body).not_to include("bg-success-surface")
    end

    it "stores the chosen swatch without any typed code" do
      create(:branding, tenant: tenant, brand_600: "#4F46E5")

      patch owner_branding_path, params: {
        tenant: { name: tenant.name },
        branding: { brand_600: Branding::Palette.swatches.last, brand_600_custom: "" }
      }

      expect(response).to redirect_to(edit_owner_branding_path)
      ActsAsTenant.with_tenant(tenant) { expect(tenant.reload.branding.brand_600).to eq(Branding::Palette.swatches.last) }
    end

    it "stores the typed code when the custom choice is the one selected" do
      create(:branding, tenant: tenant, brand_600: "#4F46E5")

      patch owner_branding_path, params: {
        tenant: { name: tenant.name },
        branding: { brand_600: Branding::CUSTOM_COLOR_CHOICE, brand_600_custom: "#2F6FED" }
      }

      ActsAsTenant.with_tenant(tenant) { expect(tenant.reload.branding.brand_600).to eq("#2F6FED") }
    end

    it "refuses a typed code without contrast with the message it has always used" do
      create(:branding, tenant: tenant, brand_600: "#4F46E5")

      patch owner_branding_path, params: {
        tenant: { name: tenant.name },
        branding: { brand_600: Branding::CUSTOM_COLOR_CHOICE, brand_600_custom: "#7A7A7A" }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include(Branding::CONTRAST_MESSAGE)
      ActsAsTenant.with_tenant(tenant) { expect(tenant.reload.branding.brand_600).to eq("#4F46E5") }
    end

    it "stores the secondary color the owner chose" do
      create(:branding, tenant: tenant, brand_600: "#4F46E5")

      patch owner_branding_path, params: {
        tenant: { name: tenant.name },
        branding: { brand_600: "#4F46E5", brand_secondary_600: "#1E60C4" }
      }

      ActsAsTenant.with_tenant(tenant) { expect(tenant.reload.branding.brand_secondary_600).to eq("#1E60C4") }
    end

    it "keeps the establishment valid and clears the secondary color when the owner asks for none" do
      create(:branding, :with_secondary, tenant: tenant, brand_600: "#4F46E5")

      patch owner_branding_path, params: {
        tenant: { name: tenant.name },
        branding: { brand_600: "#4F46E5", brand_secondary_600: "" }
      }

      expect(response).to redirect_to(edit_owner_branding_path)
      ActsAsTenant.with_tenant(tenant) { expect(tenant.reload.branding.brand_secondary_600).to be_nil }
    end

    it "leaves both colors untouched when the request carries no color at all" do
      create(:branding, :with_secondary, tenant: tenant, brand_600: "#4F46E5")

      patch owner_branding_path, params: { tenant: { name: tenant.name }, branding: { remove_logo: "0" } }

      expect(response).to redirect_to(edit_owner_branding_path)
      ActsAsTenant.with_tenant(tenant) do
        expect(tenant.reload.branding.brand_600).to eq("#4F46E5")
        expect(tenant.branding.brand_secondary_600).to eq("#1E60C4")
      end
    end

    it "refuses a secondary code without contrast and keeps the stored one" do
      create(:branding, :with_secondary, tenant: tenant, brand_600: "#4F46E5")

      patch owner_branding_path, params: {
        tenant: { name: tenant.name },
        branding: {
          brand_600: "#4F46E5",
          brand_secondary_600: Branding::CUSTOM_COLOR_CHOICE,
          brand_secondary_600_custom: "#7A7A7A"
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      ActsAsTenant.with_tenant(tenant) { expect(tenant.reload.branding.brand_secondary_600).to eq("#1E60C4") }
    end
  end
end
