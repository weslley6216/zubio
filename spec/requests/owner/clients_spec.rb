require "rails_helper"

RSpec.describe "Owner clients", type: :request do
  let(:tenant) { create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora") }
  let(:owner) { create(:user, :with_professional, tenant: tenant, name: "Ana Lima", email: "ana@example.com", password: "s3cr3t123") }

  describe "GET /owner/clients" do
    it "shows the matched client with 'já é sua cliente'" do
      create(:client, tenant: tenant, name: "Juliana Prado", phone: "11991234455")
      sign_in_owner(owner)

      get owner_clients_path(phone: "(11) 99123")

      expect(response.body).to include("Juliana Prado")
      expect(response.body).to include("já é sua cliente")
    end

    it "offers 'Cliente nova com este telefone' and asks for the name when nothing matches" do
      sign_in_owner(owner)

      get owner_clients_path(phone: "(11) 97000-1111")

      expect(response.body).to include("Cliente nova com este telefone")
      expect(response.body).not_to include("já é sua cliente")
    end

    it "returns an empty frame below four digits" do
      create(:client, tenant: tenant, name: "Juliana Prado", phone: "11991234455")
      sign_in_owner(owner)

      get owner_clients_path(phone: "119")

      expect(response.body).not_to include("já é sua cliente")
      expect(response.body).not_to include("Cliente nova com este telefone")
    end

    it "treats another tenant's phone as a new client and leaks no name" do
      other = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
      create(:client, tenant: other, name: "Juliana Prado", phone: "11991234455")
      own = create(:client, tenant: tenant, name: "Bruna Salles", phone: "11991234455")
      sign_in_owner(owner)

      get owner_clients_path(phone: "11991234455")

      expect(response.body).to include(own.name)
      expect(response.body).not_to include("Juliana Prado")
    end
  end
end
