require "rails_helper"

RSpec.describe "Owner custom domain", type: :request do
  let(:tenant) { create(:tenant, subdomain: "joes-barbershop", name: "Joe's Barbershop") }
  let(:owner) { create(:user, tenant: tenant, email: "owner@example.com", password: "s3cr3t123") }

  before do
    host! "#{tenant.subdomain}.zubio.com.br"
    post owner_session_path, params: { email: owner.email, password: "s3cr3t123" }
  end

  describe "PATCH /owner/domain" do
    it "registers a pending custom domain and stores the verification record" do
      stub_request(:post, "https://api.cloudflare.com/client/v4/zones/#{ENV['CLOUDFLARE_ZONE_ID']}/custom_hostnames")
        .to_return(
          status: 200,
          body: {
            result: {
              id: "cf-hostname-id",
              status: "pending",
              ownership_verification: { name: "_cf-custom-hostname.barbeariadoze.com.br", value: "cf-verification-token" }
            }
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      patch owner_domain_path, params: { domain: { custom_domain: "barbeariadoze.com.br" } }

      expect(response).to redirect_to(edit_owner_domain_path)
      expect(tenant.reload).to have_attributes(
        custom_domain: "barbeariadoze.com.br",
        custom_domain_cloudflare_id: "cf-hostname-id",
        custom_domain_verification_txt_name: "_cf-custom-hostname.barbeariadoze.com.br",
        custom_domain_verification_txt_value: "cf-verification-token",
        custom_domain_verified_at: nil
      )
    end

    it "rejects a custom domain already active on another tenant without calling Cloudflare" do
      create(:tenant, custom_domain: "outrodominio.com.br")

      patch owner_domain_path, params: { domain: { custom_domain: "outrodominio.com.br" } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(WebMock).not_to have_requested(:post, %r{api\.cloudflare\.com})
      expect(tenant.reload.custom_domain).to be_nil
    end

    it "does not update another tenant's custom domain" do
      other_tenant = create(:tenant, :with_verified_custom_domain, subdomain: "other-salon", custom_domain: "dominiodooutro.com.br")
      stub_request(:post, "https://api.cloudflare.com/client/v4/zones/#{ENV['CLOUDFLARE_ZONE_ID']}/custom_hostnames")
        .to_return(
          status: 200,
          body: { result: { id: "cf-new", status: "pending", ownership_verification: { name: "n", value: "v" } } }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      patch owner_domain_path, params: { domain: { custom_domain: "novodominio.com.br" } }

      expect(other_tenant.reload.custom_domain).to eq("dominiodooutro.com.br")
    end

    it "removes the custom domain and deletes the Cloudflare hostname" do
      tenant.update!(
        custom_domain: "barbeariadoze.com.br",
        custom_domain_cloudflare_id: "cf-hostname-id",
        custom_domain_verification_txt_name: "_cf-custom-hostname.barbeariadoze.com.br",
        custom_domain_verification_txt_value: "cf-verification-token",
        custom_domain_verified_at: Time.current
      )
      delete_stub = stub_request(:delete, "https://api.cloudflare.com/client/v4/zones/#{ENV['CLOUDFLARE_ZONE_ID']}/custom_hostnames/cf-hostname-id")
        .to_return(status: 200, body: { result: { id: "cf-hostname-id" } }.to_json, headers: { "Content-Type" => "application/json" })

      patch owner_domain_path, params: { domain: { remove_domain: "1" } }

      expect(response).to redirect_to(edit_owner_domain_path)
      expect(tenant.reload.custom_domain).to be_nil
      expect(delete_stub).to have_been_requested
    end
  end

  describe "GET /owner/domain/edit" do
    it "shows the TXT verification instructions while pending" do
      tenant.update!(
        custom_domain: "barbeariadoze.com.br",
        custom_domain_cloudflare_id: "cf-hostname-id",
        custom_domain_verification_txt_name: "_cf-custom-hostname.barbeariadoze.com.br",
        custom_domain_verification_txt_value: "cf-verification-token"
      )

      get edit_owner_domain_path

      expect(response.body).to include("_cf-custom-hostname.barbeariadoze.com.br")
      expect(response.body).to include("cf-verification-token")
    end

    it "shows the active notice once the domain is verified" do
      tenant.update!(custom_domain: "barbeariadoze.com.br", custom_domain_verified_at: Time.current)

      get edit_owner_domain_path

      expect(response.body).to include("Domínio ativo.")
    end
  end
end
