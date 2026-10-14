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
end
