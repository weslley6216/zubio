require "rails_helper"

RSpec.describe "Owner base controller authentication", type: :request do
  let(:tenant) { create(:tenant, subdomain: "joes-barbershop") }

  before { host! "#{tenant.subdomain}.zubio.com.br" }

  it "redirects to login when there is no active session" do
    get owner_dashboard_path

    expect(response).to redirect_to(new_owner_session_path)
  end

  it "renders the dashboard for an authenticated owner" do
    owner = create(:user, tenant: tenant, email: "owner@example.com", password: "s3cr3t123")
    post owner_session_path, params: { email: owner.email, password: "s3cr3t123" }

    get owner_dashboard_path

    expect(response).to have_http_status(:ok)
  end
end
