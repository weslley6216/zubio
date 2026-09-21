require "rails_helper"

RSpec.describe "Direct uploads", type: :request do
  let(:tenant) { create(:tenant, :onboarding, subdomain: "abc123def456") }

  def blob_params
    {
      blob: {
        filename: "logo.png",
        byte_size: 1024,
        checksum: Digest::MD5.base64digest("logo"),
        content_type: "image/png"
      }
    }
  end

  it "refuses a visitor with no session" do
    host! "#{tenant.subdomain}.zubio.com.br"

    post authenticated_direct_uploads_path, params: blob_params, as: :json

    expect(response).to have_http_status(:unauthorized)
    expect(ActiveStorage::Blob.count).to eq(0)
  end

  it "signs an upload for a signed-in owner" do
    owner = create(:user, tenant: tenant, name: "Ana Lima", email: "ana@example.com", password: "s3cr3t123")
    host! "#{tenant.subdomain}.zubio.com.br"
    post owner_session_path, params: { email: owner.email, password: "s3cr3t123" }

    post authenticated_direct_uploads_path, params: blob_params, as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to include("signed_id", "direct_upload")
  end
end
