require "rails_helper"

RSpec.describe "Login links", type: :request do
  before { host! "zubio.com.br" }

  describe "GET /login_link/new" do
    it "renders the email form outside any tenant subdomain" do
      get new_login_link_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(<section aria-labelledby="#{Components::Panel::HEADING_ID}"))
      expect(response.body).to include("E-mail")
      expect(response.body).to include(%(type="email"))
    end

    it "asks only for the email, never for a password" do
      get new_login_link_path

      expect(response.body).not_to include(%(type="password"))
    end

    it "sends the form back to the platform host when reached on a tenant subdomain" do
      host! "joes-barbershop.zubio.com.br"

      get new_login_link_path

      expect(response).to redirect_to(new_login_link_url(host: Tenant::PLATFORM_HOST))
    end
  end

  describe "POST /login_link" do
    it "enqueues the login-link email for a known owner's address" do
      tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
      create(:user, tenant: tenant, email: "ze@example.com", role: "owner")

      expect { post login_link_path, params: { email: "ze@example.com" } }
        .to have_enqueued_mail(OwnerMailer, :login_links).with("ze@example.com")
    end

    it "sends a known address back to the form" do
      tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
      create(:user, tenant: tenant, email: "ze@example.com", role: "owner")

      post login_link_path, params: { email: "ze@example.com" }

      expect(response).to redirect_to(new_login_link_path)
    end

    it "confirms the send for a known address" do
      tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
      create(:user, tenant: tenant, email: "ze@example.com", role: "owner")

      post login_link_path, params: { email: "ze@example.com" }
      follow_redirect!

      expect(response.body).to include(LoginLinksController::CONFIRMATION)
    end

    it "enqueues nothing for an unknown address" do
      expect { post login_link_path, params: { email: "nobody@example.com" } }
        .not_to have_enqueued_mail(OwnerMailer, :login_links)
    end

    it "shows the same confirmation for an unknown address" do
      post login_link_path, params: { email: "nobody@example.com" }
      follow_redirect!

      expect(response.body).to include(LoginLinksController::CONFIRMATION)
    end

    it "enqueues nothing for a blank email" do
      expect { post login_link_path, params: { email: "" } }
        .not_to have_enqueued_mail(OwnerMailer, :login_links)
    end

    it "still confirms for a blank email" do
      post login_link_path, params: { email: "" }
      follow_redirect!

      expect(response.body).to include(LoginLinksController::CONFIRMATION)
    end

    it "blocks further attempts after the rate limit is exceeded" do
      5.times { post login_link_path, params: { email: "nobody@example.com" } }

      post login_link_path, params: { email: "nobody@example.com" }

      expect(response).to redirect_to(new_login_link_path)
    end

    it "tells the visitor to try again later once the rate limit is exceeded" do
      5.times { post login_link_path, params: { email: "nobody@example.com" } }

      post login_link_path, params: { email: "nobody@example.com" }
      follow_redirect!

      expect(response.body).to include("Muitas tentativas. Tente novamente mais tarde.")
    end

    it "does not name another owner's establishment when sending a known owner's links" do
      ze_tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
      ana_tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
      create(:user, tenant: ze_tenant, email: "ze@example.com", role: "owner")
      create(:user, tenant: ana_tenant, email: "ana@example.com", role: "owner")

      perform_enqueued_jobs { post login_link_path, params: { email: "ze@example.com" } }

      delivery = ActionMailer::Base.deliveries.last
      expect(delivery.body.to_s).to include("Barbearia do Zé")
      expect(delivery.body.to_s).not_to include("Estúdio Aurora")
    end
  end
end
