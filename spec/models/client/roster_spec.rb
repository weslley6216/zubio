require "rails_helper"

RSpec.describe Client::Roster, type: :model do
  describe "#entries" do
    it "reports the nearest future confirmed appointment as the next visit" do
      travel_to Time.zone.local(2026, 9, 8, 7, 0) do
        tenant = create(:tenant)
        client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro")
        create(:appointment, tenant: tenant, client: client, status: "confirmed", starts_at: Time.zone.local(2026, 9, 8, 9, 45))

        entry = ActsAsTenant.with_tenant(tenant) { Client::Roster.new.entries.first }

        expect(entry.next_visit_at).to eq(Time.zone.local(2026, 9, 8, 9, 45))
        expect(entry.last_visit_at).to be_nil
        expect(entry.visit_count).to eq(0)
      end
    end

    it "counts only past appointments that are neither cancelled nor no_show as visits" do
      travel_to Time.zone.local(2026, 9, 8, 7, 0) do
        tenant = create(:tenant)
        client = create(:client, tenant: tenant, name: "Camila Nunes")
        create(:appointment, :completed, tenant: tenant, client: client, starts_at: Time.zone.local(2026, 8, 1, 10, 0))
        create(:appointment, :completed, tenant: tenant, client: client, starts_at: Time.zone.local(2026, 8, 5, 10, 0))
        create(:appointment, :completed, tenant: tenant, client: client, starts_at: Time.zone.local(2026, 8, 10, 10, 0))
        create(:appointment, :completed, tenant: tenant, client: client, starts_at: Time.zone.local(2026, 8, 15, 10, 0))
        create(:appointment, :completed, tenant: tenant, client: client, starts_at: Time.zone.local(2026, 8, 22, 10, 0))
        create(:appointment, :cancelled, tenant: tenant, client: client, starts_at: Time.zone.local(2026, 8, 30, 10, 0))
        create(:appointment, :no_show, tenant: tenant, client: client, starts_at: Time.zone.local(2026, 8, 25, 10, 0))

        entry = ActsAsTenant.with_tenant(tenant) { Client::Roster.new.entries.first }

        expect(entry.visit_count).to eq(5)
        expect(entry.last_visit_at).to eq(Time.zone.local(2026, 8, 22, 10, 0))
        expect(entry.next_visit_at).to be_nil
      end
    end

    it "orders clients with a next visit first, then by most recent last visit, then those with neither" do
      travel_to Time.zone.local(2026, 9, 8, 7, 0) do
        tenant = create(:tenant)
        client_a = create(:client, tenant: tenant, name: "Ana Paula Ribeiro")
        client_b = create(:client, tenant: tenant, name: "Bruna Salles")
        client_c = create(:client, tenant: tenant, name: "Camila Nunes")
        client_d = create(:client, tenant: tenant, name: "Daniela Fonseca")
        client_e = create(:client, tenant: tenant, name: "Elaine Teixeira")
        create(:appointment, tenant: tenant, client: client_a, status: "confirmed", starts_at: Time.zone.local(2026, 9, 8, 9, 0))
        create(:appointment, tenant: tenant, client: client_b, status: "confirmed", starts_at: Time.zone.local(2026, 9, 8, 15, 0))
        create(:appointment, :completed, tenant: tenant, client: client_c, starts_at: Time.zone.local(2026, 9, 1, 10, 0))
        create(:appointment, :completed, tenant: tenant, client: client_d, starts_at: Time.zone.local(2026, 8, 1, 10, 0))
        create(:appointment, :cancelled, tenant: tenant, client: client_e, starts_at: Time.zone.local(2026, 8, 15, 10, 0))

        clients = ActsAsTenant.with_tenant(tenant) { Client::Roster.new.entries.map(&:client) }

        expect(clients).to eq([ client_a, client_b, client_c, client_d, client_e ])
      end
    end

    it "filters by name with ILIKE and excludes non-matches" do
      travel_to Time.zone.local(2026, 9, 8, 7, 0) do
        tenant = create(:tenant)
        camila = create(:client, tenant: tenant, name: "Camila Nunes")
        create(:client, tenant: tenant, name: "Bruna Salles")

        clients = ActsAsTenant.with_tenant(tenant) { Client::Roster.new(query: "camila").entries.map(&:client) }

        expect(clients).to contain_exactly(camila)
      end
    end

    it "filters by a phone substring, matching digits in the middle of the number" do
      travel_to Time.zone.local(2026, 9, 8, 7, 0) do
        tenant = create(:tenant)
        camila = create(:client, tenant: tenant, name: "Camila Nunes", phone: "11977668899")
        create(:client, tenant: tenant, name: "Bruna Salles", phone: "11912340000")

        clients = ActsAsTenant.with_tenant(tenant) { Client::Roster.new(query: "97766").entries.map(&:client) }

        expect(clients).to contain_exactly(camila)
      end
    end

    it "finds a client by a phone pasted with the 55 country code" do
      travel_to Time.zone.local(2026, 9, 8, 7, 0) do
        tenant = create(:tenant)
        camila = create(:client, tenant: tenant, name: "Camila Nunes", phone: "11977668899")
        create(:client, tenant: tenant, name: "Bruna Salles", phone: "11912340000")

        clients = ActsAsTenant.with_tenant(tenant) { Client::Roster.new(query: "+55 11 97766-8899").entries.map(&:client) }

        expect(clients).to contain_exactly(camila)
      end
    end

    it "keeps another tenant's clients and appointments out of the roster" do
      travel_to Time.zone.local(2026, 9, 8, 7, 0) do
        other_tenant = create(:tenant, name: "Barbearia do Zé")
        other_client = create(:client, tenant: other_tenant, name: "Juliana Prado")
        create(:appointment, :completed, tenant: other_tenant, client: other_client, starts_at: Time.zone.local(2026, 8, 1, 10, 0))
        create(:appointment, :completed, tenant: other_tenant, client: other_client, starts_at: Time.zone.local(2026, 8, 5, 10, 0))

        tenant = create(:tenant, name: "Estúdio Aurora")
        client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro")
        create(:appointment, :completed, tenant: tenant, client: client, starts_at: Time.zone.local(2026, 8, 20, 10, 0))

        entries = ActsAsTenant.with_tenant(tenant) { Client::Roster.new.entries }

        expect(entries.map(&:client)).to include(client)
        expect(entries.map(&:client)).not_to include(other_client)
        expect(entries.find { |entry| entry.client == client }.visit_count).to eq(1)
      end
    end
  end
end
