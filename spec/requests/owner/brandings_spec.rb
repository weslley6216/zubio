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
    end
  end

  describe "PATCH /owner/branding" do
    it "updates the brand color" do
      create(:branding, tenant: tenant, brand_600: "#4F46E5")

      patch owner_branding_path, params: { tenant: { name: tenant.name }, branding: { brand_600: "#2F6FED" } }

      expect(response).to redirect_to(edit_owner_branding_path)
      expect(tenant.reload.branding.brand_600).to eq("#2F6FED")
    end

    it "rejects a color without sufficient contrast and does not persist it" do
      create(:branding, tenant: tenant, brand_600: "#4F46E5")

      patch owner_branding_path, params: { tenant: { name: tenant.name }, branding: { brand_600: "#F5F5F5" } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(tenant.reload.branding.brand_600).to eq("#4F46E5")
    end

    it "rejects a malformed color without crashing the page chrome and does not persist it" do
      create(:branding, tenant: tenant, brand_600: "#4F46E5")

      patch owner_branding_path, params: { tenant: { name: tenant.name }, branding: { brand_600: "not-a-hex" } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(tenant.reload.branding.brand_600).to eq("#4F46E5")
    end

    it "saves a valid logo upload and enqueues icon variant precomputation in the background" do
      create(:branding, tenant: tenant, brand_600: "#4F46E5")
      logo = Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/logo.png"), "image/png")

      expect {
        patch owner_branding_path, params: { tenant: { name: tenant.name }, branding: { brand_600: "#4F46E5", logo: logo } }
      }.to have_enqueued_job(Branding::PrecomputeIconVariantsJob).with(tenant.id)

      expect(response).to redirect_to(edit_owner_branding_path)
      expect(tenant.reload.branding.logo).to be_attached
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
      expect(tenant.reload.branding.logo).not_to be_attached
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
      expect(tenant.reload.branding.logo).not_to be_attached
    ensure
      oversized.close!
    end

    it "updates the establishment name" do
      create(:branding, tenant: tenant, brand_600: "#4F46E5")

      patch owner_branding_path, params: { tenant: { name: "Studio Aurora" }, branding: { brand_600: "#4F46E5" } }

      expect(tenant.reload.name).to eq("Studio Aurora")
    end

    it "removes the current logo when remove_logo is checked and no new file is sent" do
      create(:branding, :with_logo, tenant: tenant, brand_600: "#4F46E5")

      perform_enqueued_jobs do
        patch owner_branding_path, params: { tenant: { name: tenant.name }, branding: { brand_600: "#4F46E5", remove_logo: "1" } }
      end

      expect(tenant.reload.branding.logo).not_to be_attached
    end

    it "does not update another tenant's branding" do
      other_tenant = create(:tenant, subdomain: "other-salon", name: "Other Salon")
      create(:branding, tenant: other_tenant, brand_600: "#000000")

      patch owner_branding_path, params: { tenant: { name: "Hijacked" }, branding: { brand_600: "#2F6FED" } }

      expect(other_tenant.reload.name).to eq("Other Salon")
      expect(other_tenant.branding.reload.brand_600).to eq("#000000")
    end
  end
end
