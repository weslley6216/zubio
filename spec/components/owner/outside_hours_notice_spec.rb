require "rails_helper"

RSpec.describe Components::Owner::OutsideHoursNotice, type: :component do
  it "stays silent when nothing sits outside the hours" do
    document = Nokogiri::HTML5.fragment(described_class.new(conflicts: []).call)

    expect(document.at_css("[data-outside-hours]")).to be_nil
  end

  it "heads a single conflict with the singular count" do
    tenant = create(:tenant)
    appointment = create(:appointment, tenant: tenant)

    document = ActsAsTenant.with_tenant(tenant) { Nokogiri::HTML5.fragment(described_class.new(conflicts: [ appointment ]).call) }

    expect(document.at_css("[data-outside-hours]")).not_to be_nil
    expect(document.text).to include("1 agendamento ficou fora do expediente")
  end

  it "heads two conflicts with the plural count" do
    tenant = create(:tenant)
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant)
    first = create(:appointment, tenant: tenant, professional: professional, service: service, starts_at: 1.week.from_now.change(hour: 9))
    second = create(:appointment, tenant: tenant, professional: professional, service: service, starts_at: 2.weeks.from_now.change(hour: 9))

    document = ActsAsTenant.with_tenant(tenant) { Nokogiri::HTML5.fragment(described_class.new(conflicts: [ first, second ]).call) }

    expect(document.text).to include("2 agendamentos ficaram fora do expediente")
  end

  it "prints each client name with the appointment date and time" do
    tenant = create(:tenant)
    client = create(:client, tenant: tenant, name: "Ana Paula")
    appointment = create(:appointment, tenant: tenant, client: client, starts_at: "2026-09-07 10:00".in_time_zone)

    document = ActsAsTenant.with_tenant(tenant) { Nokogiri::HTML5.fragment(described_class.new(conflicts: [ appointment ]).call) }

    expect(document.text).to include("Ana Paula, 07/09 às 10:00")
  end

  it "reassures that the appointment stays valid" do
    tenant = create(:tenant)
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant)
    appointment = create(:appointment, tenant: tenant, professional: professional, service: service)
    other = create(:appointment, tenant: tenant, professional: professional, service: service, starts_at: 2.weeks.from_now.change(hour: 9))

    singular = ActsAsTenant.with_tenant(tenant) { Nokogiri::HTML5.fragment(described_class.new(conflicts: [ appointment ]).call) }
    plural = ActsAsTenant.with_tenant(tenant) { Nokogiri::HTML5.fragment(described_class.new(conflicts: [ appointment, other ]).call) }

    expect(singular.text).to include("Ele continua valendo — fale com o cliente se precisar remarcar.")
    expect(plural.text).to include("Eles continuam valendo — fale com os clientes se precisar remarcar.")
  end

  it "paints the notice with neutral tokens, never the danger red" do
    tenant = create(:tenant)
    appointment = create(:appointment, tenant: tenant)

    response = ActsAsTenant.with_tenant(tenant) { described_class.new(conflicts: [ appointment ]).call }
    document = Nokogiri::HTML5.fragment(response)

    expect(document.at_css("[data-alert]")["class"].split).to include("border-line")
    expect(document.at_css("[data-alert] svg")["class"].split).to include("text-ink-muted")
    expect(response).not_to include("border-danger")
    expect(response).not_to include("#b42318")
    expect(response).not_to include("text-danger")
  end
end
