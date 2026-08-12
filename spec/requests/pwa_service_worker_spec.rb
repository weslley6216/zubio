require "rails_helper"

RSpec.describe "PWA service worker", type: :request do
  describe "GET /service-worker.js" do
    it "serves the service worker script at the root scope" do
      tenant = create(:tenant, subdomain: "joes-barbershop")

      host! "joes-barbershop.zubio.com.br"
      get "/service-worker.js"

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/javascript")
    end

    it "returns 404 for a subdomain with no tenant" do
      host! "does-not-exist.zubio.com.br"
      get "/service-worker.js"

      expect(response).to have_http_status(:not_found)
    end
  end
end
