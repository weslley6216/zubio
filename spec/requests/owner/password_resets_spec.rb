require "rails_helper"

RSpec.describe "Owner password reset", type: :request do
  let(:tenant) { create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé") }
  let(:owner) { create(:user, tenant: tenant, email: "ze@example.com", password: "s3cr3t123", role: "owner") }

  before { host! "#{tenant.subdomain}.zubio.com.br" }

  describe "GET /owner/password_reset/new" do
    it "renders the email form on the establishment host" do
      get new_owner_password_reset_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(type="email"))
      expect(response.body).to include("Recuperar senha")
    end

    it "asks only for the email, never for a password" do
      get new_owner_password_reset_path

      expect(response.body).not_to include(%(type="password"))
    end
  end

  describe "POST /owner/password_reset" do
    it "enqueues the reset email for a known owner's address" do
      owner

      expect { post owner_password_reset_path, params: { email: "ze@example.com" } }
        .to have_enqueued_mail(OwnerMailer, :password_reset).with(tenant.id, owner.id, a_kind_of(String))
    end

    it "enqueues the reset email when the address arrives in another case" do
      owner

      expect { post owner_password_reset_path, params: { email: "ZE@example.com" } }
        .to have_enqueued_mail(OwnerMailer, :password_reset)
    end

    it "confirms the send for a known address" do
      owner

      post owner_password_reset_path, params: { email: "ze@example.com" }
      follow_redirect!

      expect(response.body).to include(Owner::PasswordResetsController::CONFIRMATION)
    end

    it "enqueues nothing for an unknown address" do
      expect { post owner_password_reset_path, params: { email: "ninguem@example.com" } }
        .not_to have_enqueued_mail(OwnerMailer, :password_reset)
    end

    it "shows the same confirmation for an unknown address" do
      post owner_password_reset_path, params: { email: "ninguem@example.com" }
      follow_redirect!

      expect(response.body).to include(Owner::PasswordResetsController::CONFIRMATION)
    end

    it "enqueues nothing for a blank email" do
      expect { post owner_password_reset_path, params: { email: "" } }
        .not_to have_enqueued_mail(OwnerMailer, :password_reset)
    end

    it "enqueues nothing for a user of the establishment who is not an owner" do
      create(:user, tenant: tenant, email: "barbeiro@example.com", role: "professional")

      expect { post owner_password_reset_path, params: { email: "barbeiro@example.com" } }
        .not_to have_enqueued_mail(OwnerMailer, :password_reset)
    end

    it "sends the email only to the owner of the establishment in the host" do
      aurora = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
      create(:user, tenant: aurora, email: "ana@example.com", role: "owner")

      expect { post owner_password_reset_path, params: { email: "ana@example.com" } }
        .not_to have_enqueued_mail(OwnerMailer, :password_reset)
    end

    it "blocks further attempts after the rate limit is exceeded" do
      5.times { post owner_password_reset_path, params: { email: "ninguem@example.com" } }

      post owner_password_reset_path, params: { email: "ninguem@example.com" }
      follow_redirect!

      expect(response.body).to include("Muitas tentativas. Tente novamente mais tarde.")
    end
  end

  describe "GET /owner/password_reset/edit" do
    it "opens the new password form from the emailed link" do
      token = ActsAsTenant.with_tenant(tenant) { owner.issue_password_reset_token! }

      get edit_owner_password_reset_path(token: token)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(type="password"))
      expect(response.body).to include("Escolher nova senha")
    end

    it "carries the token into the form that sets the new password" do
      token = ActsAsTenant.with_tenant(tenant) { owner.issue_password_reset_token! }

      get edit_owner_password_reset_path(token: token)

      expect(response.body).to include(%(value="#{token}"))
    end

    it "asks for the new password only once" do
      token = ActsAsTenant.with_tenant(tenant) { owner.issue_password_reset_token! }

      get edit_owner_password_reset_path(token: token)

      expect(response.body.scan(%(type="password")).size).to eq(1)
    end

    it "sends a link already used back to the login form" do
      token = ActsAsTenant.with_tenant(tenant) { owner.issue_password_reset_token! }
      patch owner_password_reset_path, params: { token: token, password: "an0th3rpass" }

      get edit_owner_password_reset_path(token: token)

      expect(response).to redirect_to(new_owner_session_path)
    end

    it "warns on the login form that the link expired" do
      get edit_owner_password_reset_path(token: "not-a-real-token")
      follow_redirect!

      expect(response.body).to include(Owner::PasswordResetsController::REFUSED)
    end

    it "sends an expired link back to the login form" do
      token = ActsAsTenant.with_tenant(tenant) { travel_to(3.hours.ago) { owner.issue_password_reset_token! } }

      get edit_owner_password_reset_path(token: token)

      expect(response).to redirect_to(new_owner_session_path)
    end

    it "sends the link of an earlier request back to the login form once a newer one was sent" do
      first_token = ActsAsTenant.with_tenant(tenant) { owner.issue_password_reset_token! }
      post owner_password_reset_path, params: { email: "ze@example.com" }

      get edit_owner_password_reset_path(token: first_token)

      expect(response).to redirect_to(new_owner_session_path)
    end

    it "sends a malformed token back to the login form" do
      get edit_owner_password_reset_path(token: "not-a-real-token")

      expect(response).to redirect_to(new_owner_session_path)
    end

    it "sends a missing token back to the login form" do
      get edit_owner_password_reset_path

      expect(response).to redirect_to(new_owner_session_path)
    end

    it "sends a token that arrives as a list back to the login form" do
      get edit_owner_password_reset_path, params: { token: [ "not-a-real-token" ] }

      expect(response).to redirect_to(new_owner_session_path)
    end

    it "refuses a token minted for a user who is not an owner" do
      professional = create(:user, tenant: tenant, role: "professional")
      token = ActsAsTenant.with_tenant(tenant) { professional.issue_password_reset_token! }

      get edit_owner_password_reset_path(token: token)

      expect(response).to redirect_to(new_owner_session_path)
    end

    it "refuses a token minted for the owner of another establishment" do
      aurora = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
      aurora_owner = create(:user, tenant: aurora, role: "owner")
      token = ActsAsTenant.with_tenant(aurora) { aurora_owner.issue_password_reset_token! }

      get edit_owner_password_reset_path(token: token)

      expect(response).to redirect_to(new_owner_session_path)
    end
  end

  describe "PATCH /owner/password_reset" do
    it "opens the owner session and lands on the dashboard" do
      token = ActsAsTenant.with_tenant(tenant) { owner.issue_password_reset_token! }

      patch owner_password_reset_path, params: { token: token, password: "an0th3rpass" }

      expect(response).to redirect_to(owner_appointments_path)
    end

    it "reaches the dashboard without asking for the password again" do
      token = ActsAsTenant.with_tenant(tenant) { owner.issue_password_reset_token! }
      patch owner_password_reset_path, params: { token: token, password: "an0th3rpass" }

      follow_redirect!

      expect(response).to have_http_status(:ok)
    end

    it "lets the onboarding gate send an owner still onboarding to setup" do
      onboarding_tenant = create(:tenant, :onboarding, subdomain: "salon-c")
      onboarding_owner = create(:user, tenant: onboarding_tenant, role: "owner")
      token = ActsAsTenant.with_tenant(onboarding_tenant) { onboarding_owner.issue_password_reset_token! }
      host! "#{onboarding_tenant.subdomain}.zubio.com.br"
      patch owner_password_reset_path, params: { token: token, password: "an0th3rpass" }

      follow_redirect!

      expect(response).to redirect_to(owner_onboarding_path)
    end

    it "lets the owner sign in with the new password" do
      token = ActsAsTenant.with_tenant(tenant) { owner.issue_password_reset_token! }
      patch owner_password_reset_path, params: { token: token, password: "an0th3rpass" }

      post owner_session_path, params: { email: "ze@example.com", password: "an0th3rpass" }

      expect(response).to redirect_to(owner_appointments_path)
    end

    it "refuses the previous password after the change" do
      token = ActsAsTenant.with_tenant(tenant) { owner.issue_password_reset_token! }
      patch owner_password_reset_path, params: { token: token, password: "an0th3rpass" }

      post owner_session_path, params: { email: "ze@example.com", password: "s3cr3t123" }

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "keeps the owner on the form with the error next to the field when the password is too short" do
      token = ActsAsTenant.with_tenant(tenant) { owner.issue_password_reset_token! }

      patch owner_password_reset_path, params: { token: token, password: "short" }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("é muito curto (mínimo: 8 caracteres)")
      expect(response.body).to include(%(value="#{token}"))
    end

    it "keeps the previous password when the new one is too short" do
      token = ActsAsTenant.with_tenant(tenant) { owner.issue_password_reset_token! }
      patch owner_password_reset_path, params: { token: token, password: "short" }

      post owner_session_path, params: { email: "ze@example.com", password: "s3cr3t123" }

      expect(response).to redirect_to(owner_appointments_path)
    end

    it "keeps the link usable after a password that is too short" do
      token = ActsAsTenant.with_tenant(tenant) { owner.issue_password_reset_token! }
      patch owner_password_reset_path, params: { token: token, password: "short" }

      patch owner_password_reset_path, params: { token: token, password: "an0th3rpass" }

      expect(response).to redirect_to(owner_appointments_path)
    end

    it "refuses a blank password without opening a session" do
      token = ActsAsTenant.with_tenant(tenant) { owner.issue_password_reset_token! }

      patch owner_password_reset_path, params: { token: token, password: "" }

      expect(response).to have_http_status(:unprocessable_content)
      expect(session[:user_id]).to be_nil
    end

    it "refuses a password that arrives as a list without opening a session" do
      token = ActsAsTenant.with_tenant(tenant) { owner.issue_password_reset_token! }

      patch owner_password_reset_path, params: { token: token, password: [ "an0th3rpass" ] }

      expect(response).to have_http_status(:unprocessable_content)
      expect(session[:user_id]).to be_nil
    end

    it "sends an expired link back to the login form and keeps the previous password" do
      token = ActsAsTenant.with_tenant(tenant) { travel_to(3.hours.ago) { owner.issue_password_reset_token! } }
      patch owner_password_reset_path, params: { token: token, password: "an0th3rpass" }

      expect(response).to redirect_to(new_owner_session_path)
      expect(ActsAsTenant.with_tenant(tenant) { owner.reload.authenticate("s3cr3t123") }).to eq(owner)
    end

    it "does not open a session in another establishment with its owner's token" do
      aurora = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
      aurora_owner = create(:user, tenant: aurora, password: "s3cr3t123", role: "owner")
      token = ActsAsTenant.with_tenant(aurora) { aurora_owner.issue_password_reset_token! }

      patch owner_password_reset_path, params: { token: token, password: "an0th3rpass" }

      expect(response).to redirect_to(new_owner_session_path)
      expect(ActsAsTenant.with_tenant(aurora) { aurora_owner.reload.authenticate("s3cr3t123") }).to eq(aurora_owner)
    end
  end
end
