require "rails_helper"

RSpec.describe "Owner handoff", type: :request do
  let(:tenant) { create(:tenant, subdomain: "joes-barbershop") }
  let(:owner) { create(:user, tenant: tenant, role: "owner") }

  before { host! "#{tenant.subdomain}.zubio.com.br" }

  describe "GET /owner/handoff" do
    it "opens the owner session and lands on the dashboard" do
      get owner_handoff_path(token: owner.generate_token_for(:owner_handoff))

      expect(response).to redirect_to(owner_dashboard_path)
    end

    it "reaches the dashboard without asking for the password again" do
      get owner_handoff_path(token: owner.generate_token_for(:owner_handoff))

      follow_redirect!

      expect(response.body).to include("Painel")
    end

    it "sends a malformed token back to the login form" do
      get owner_handoff_path(token: "not-a-real-token")

      expect(response).to redirect_to(new_owner_session_path)
    end

    it "sends an expired token back to the login form" do
      token = travel_to(1.hour.ago) { owner.generate_token_for(:owner_handoff) }

      get owner_handoff_path(token: token)

      expect(response).to redirect_to(new_owner_session_path)
    end

    it "explains why the login form was shown when the token no longer works" do
      get owner_handoff_path(token: "not-a-real-token")

      follow_redirect!

      expect(response.body).to include("Este link expirou")
    end

    it "refuses a token minted for a user who is not an owner" do
      professional = create(:user, tenant: tenant, role: "professional")

      get owner_handoff_path(token: professional.generate_token_for(:owner_handoff))

      expect(response).to redirect_to(new_owner_session_path)
    end

    it "refuses a token minted for the owner of another tenant" do
      other_owner = create(:user, tenant: create(:tenant, subdomain: "salon-b"), role: "owner")

      get owner_handoff_path(token: other_owner.generate_token_for(:owner_handoff))

      expect(response).to redirect_to(new_owner_session_path)
    end

    it "accepts a token minted for the owner of the tenant in the host" do
      create(:user, tenant: create(:tenant, subdomain: "salon-b"), role: "owner")

      get owner_handoff_path(token: owner.generate_token_for(:owner_handoff))

      expect(response).to redirect_to(owner_dashboard_path)
    end
  end
end
