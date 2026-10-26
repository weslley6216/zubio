require "rails_helper"

RSpec.describe "Owner clients", type: :request do
  let(:tenant) { create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora") }
  let(:owner) { create(:user, :with_professional, tenant: tenant, name: "Ana Lima", email: "ana@example.com", password: "s3cr3t123") }

  describe "GET /owner/clients" do
    it "shows 'Suas clientes', the count and one row per client with initials and name" do
      travel_to Time.zone.local(2026, 9, 8, 7, 0) do
        create(:client, tenant: tenant, name: "Ana Paula Ribeiro")
        create(:client, tenant: tenant, name: "Bruna Salles")
        create(:client, tenant: tenant, name: "Camila Nunes")
        sign_in_owner(owner)

        get owner_clients_path

        document = Nokogiri::HTML5(response.body)
        expect(document.text).to include("Suas clientes")
        expect(document.text).to include("3")
        expect(document.text).to include("Ana Paula Ribeiro").and include("AP")
        expect(document.text).to include("Bruna Salles").and include("BS")
        expect(document.text).to include("Camila Nunes").and include("CN")
      end
    end

    it "shows the next appointment for a client who has one" do
      travel_to Time.zone.local(2026, 9, 8, 7, 0) do
        client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro")
        ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, client: client, status: "confirmed", starts_at: Time.zone.local(2026, 9, 8, 9, 45)) }
        sign_in_owner(owner)

        get owner_clients_path

        expect(response.body).to include("Próxima: ter, 8 set · 09:45")
      end
    end

    it "shows the last visit and the visit count for a client with no future appointment" do
      travel_to Time.zone.local(2026, 9, 8, 7, 0) do
        client = create(:client, tenant: tenant, name: "Camila Nunes")
        ActsAsTenant.with_tenant(tenant) do
          create(:appointment, :completed, tenant: tenant, client: client, starts_at: Time.zone.local(2026, 8, 1, 10, 0))
          create(:appointment, :completed, tenant: tenant, client: client, starts_at: Time.zone.local(2026, 8, 5, 10, 0))
          create(:appointment, :completed, tenant: tenant, client: client, starts_at: Time.zone.local(2026, 8, 10, 10, 0))
          create(:appointment, :completed, tenant: tenant, client: client, starts_at: Time.zone.local(2026, 8, 15, 10, 0))
          create(:appointment, :completed, tenant: tenant, client: client, starts_at: Time.zone.local(2026, 8, 22, 10, 0))
        end
        sign_in_owner(owner)

        get owner_clients_path

        expect(response.body).to include("Última visita 22 ago · 5 visitas")
      end
    end

    it "does not count a cancelled appointment as a visit" do
      travel_to Time.zone.local(2026, 9, 8, 7, 0) do
        client = create(:client, tenant: tenant, name: "Camila Nunes")
        ActsAsTenant.with_tenant(tenant) do
          create(:appointment, :completed, tenant: tenant, client: client, starts_at: Time.zone.local(2026, 8, 1, 10, 0))
          create(:appointment, :completed, tenant: tenant, client: client, starts_at: Time.zone.local(2026, 8, 5, 10, 0))
          create(:appointment, :cancelled, tenant: tenant, client: client, starts_at: Time.zone.local(2026, 8, 10, 10, 0))
        end
        sign_in_owner(owner)

        get owner_clients_path

        expect(response.body).to include("2 visitas")
      end
    end

    it "filters by name" do
      create(:client, tenant: tenant, name: "Camila Nunes")
      create(:client, tenant: tenant, name: "Bruna Salles")
      sign_in_owner(owner)

      get owner_clients_path(q: "camila")

      expect(response.body).to include("Camila Nunes")
      expect(response.body).not_to include("Bruna Salles")
    end

    it "filters by phone" do
      create(:client, tenant: tenant, name: "Camila Nunes", phone: "11977668899")
      create(:client, tenant: tenant, name: "Bruna Salles", phone: "11912340000")
      sign_in_owner(owner)

      get owner_clients_path(q: "97766")

      expect(response.body).to include("Camila Nunes")
      expect(response.body).not_to include("Bruna Salles")
    end

    it "shows an empty message when the search matches nobody" do
      create(:client, tenant: tenant, name: "Camila Nunes")
      sign_in_owner(owner)

      get owner_clients_path(q: "zzz")

      expect(response.body).to include("Nenhuma cliente com esse nome ou telefone.")
      expect(response.body).not_to include("Camila Nunes")
    end

    it "puts a WhatsApp link with the client's number on the row" do
      client = create(:client, tenant: tenant, name: "Camila Nunes")
      sign_in_owner(owner)

      get owner_clients_path

      document = Nokogiri::HTML5(response.body)
      expect(document.at_css(%(a[href="#{client.whatsapp_url}"]))).to be_present
    end

    it "renders the desktop table columns" do
      create(:client, tenant: tenant, name: "Camila Nunes")
      sign_in_owner(owner)

      get owner_clients_path

      expect(response.body).to include("Cliente").and include("Celular").and include("Visita").and include("Visitas")
    end

    it "offers the public link when there is no client yet" do
      sign_in_owner(owner)

      get owner_clients_path

      expect(response.body).to include(tenant.canonical_host)
      expect(response.body).to include(Components::Owner::ShareLink::WHATSAPP_LABEL)
    end

    it "redirects an anonymous visitor to the login and leaks no name or phone" do
      client = create(:client, tenant: tenant, name: "Juliana Prado", phone: "11991234455")
      host! "#{tenant.subdomain}.zubio.com.br"

      get owner_clients_path

      expect(response).to redirect_to(new_owner_session_path)
      expect(response.body).not_to include(client.name)
      expect(response.body).not_to include(client.phone_display)
    end

    it "keeps another tenant's clients out of the list" do
      other = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
      create(:client, tenant: other, name: "Juliana Prado")
      create(:client, tenant: tenant, name: "Ana Paula Ribeiro")
      sign_in_owner(owner)

      get owner_clients_path

      expect(response.body).to include("Ana Paula Ribeiro")
      expect(response.body).not_to include("Juliana Prado")
    end

    it "queries the database the same number of times for many clients as for one" do
      client = create(:client, tenant: tenant)
      ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, client: client, status: "confirmed", starts_at: 1.week.from_now) }
      sign_in_owner(owner)

      single = count_queries { get owner_clients_path }

      ActsAsTenant.with_tenant(tenant) do
        4.times do
          other_client = create(:client, tenant: tenant)
          create(:appointment, tenant: tenant, client: other_client, status: "confirmed", starts_at: 1.week.from_now)
        end
      end
      many = count_queries { get owner_clients_path }

      expect(single).to be_positive
      expect(many).to eq(single)
    end

    it "labels the search field for screen readers" do
      sign_in_owner(owner)

      get owner_clients_path

      expect(Nokogiri::HTML5(response.body).at_css("input[name='q']")["aria-label"]).to eq("Buscar cliente por nome ou telefone")
    end

    it "marks Clientes as the current nav section" do
      sign_in_owner(owner)

      get owner_clients_path

      document = Nokogiri::HTML5(response.body)
      expect(document.at_css("a[aria-current='page']").text).to include("Clientes")
    end
  end
end
