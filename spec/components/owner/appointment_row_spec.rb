require "rails_helper"

RSpec.describe Components::Owner::AppointmentRow, type: :component do
  it "shows time, duration, client, service, the confirmed badge and the clickable phone" do
    tenant = create(:tenant)
    client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro", phone: "11988771234")
    service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45)
    appointment = ActsAsTenant.with_tenant(tenant) do
      create(:appointment, tenant: tenant, client: client, service: service, starts_at: Time.current.change(hour: 9, min: 45))
    end

    html = render_phlex(described_class.new(appointment: appointment))

    expect(html).to include("09:45")
    expect(html).to include("45 min")
    expect(html).to include("Ana Paula Ribeiro")
    expect(html).to include("Design de sobrancelhas")
    expect(html).to include("Confirmado")
    expect(html).to include("bg-brand-soft")
    expect(html).to include(%(href="tel:+5511988771234"))
    expect(html).to include("(11) 98877-1234")
  end

  it "strikes through the cancelled appointment with its badge and no phone" do
    tenant = create(:tenant)
    client = create(:client, tenant: tenant, name: "Bruna Salles")
    service = create(:service, tenant: tenant, name: "Design com henna", duration_minutes: 60)
    appointment = ActsAsTenant.with_tenant(tenant) do
      create(:appointment, :cancelled, tenant: tenant, client: client, service: service, starts_at: Time.current.change(hour: 15, min: 30))
    end

    html = render_phlex(described_class.new(appointment: appointment))

    expect(html).to include("line-through")
    expect(html).to include("Desmarcado")
    expect(html).to include("bg-surface-3")
    expect(html).not_to include("tel:")
  end

  it "links the confirmed row to its detail inside the detail frame" do
    tenant = create(:tenant)
    client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro", phone: "11988771234")
    service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45)
    appointment = ActsAsTenant.with_tenant(tenant) do
      create(:appointment, tenant: tenant, client: client, service: service, starts_at: Time.current.change(hour: 9, min: 45))
    end

    html = render_phlex(described_class.new(appointment: appointment))
    fragment = Nokogiri::HTML5.fragment(html)
    link = fragment.at_css(%(a[href="/owner/appointments/#{appointment.id}"]))

    expect(link["data-turbo-frame"]).to eq("appointment_detail")
    expect(link["data-turbo-action"]).to eq("advance")
  end

  it "keeps the cancelled row without a link to the detail" do
    tenant = create(:tenant)
    client = create(:client, tenant: tenant, name: "Bruna Salles")
    service = create(:service, tenant: tenant, name: "Design com henna", duration_minutes: 60)
    appointment = ActsAsTenant.with_tenant(tenant) do
      create(:appointment, :cancelled, tenant: tenant, client: client, service: service, starts_at: Time.current.change(hour: 15, min: 30))
    end

    html = render_phlex(described_class.new(appointment: appointment))

    expect(html).not_to include(%(href="/owner/appointments/))
  end

  it "highlights the selected row" do
    tenant = create(:tenant)
    client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro", phone: "11988771234")
    service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45)
    appointment = ActsAsTenant.with_tenant(tenant) do
      create(:appointment, tenant: tenant, client: client, service: service, starts_at: Time.current.change(hour: 9, min: 45))
    end

    html = render_phlex(described_class.new(appointment: appointment, selected: true))
    fragment = Nokogiri::HTML5.fragment(html)
    link = fragment.at_css(%(a[href="/owner/appointments/#{appointment.id}"]))

    expect(link["aria-current"]).to eq("true")
    expect(html).to include("border-2 border-brand-600")
  end

  it "leaves an unselected row without the highlight" do
    tenant = create(:tenant)
    client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro", phone: "11988771234")
    service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45)
    appointment = ActsAsTenant.with_tenant(tenant) do
      create(:appointment, tenant: tenant, client: client, service: service, starts_at: Time.current.change(hour: 9, min: 45))
    end

    html = render_phlex(described_class.new(appointment: appointment))
    fragment = Nokogiri::HTML5.fragment(html)
    link = fragment.at_css(%(a[href="/owner/appointments/#{appointment.id}"]))

    expect(link["aria-current"]).to be_nil
    expect(html).not_to include("border-2 border-brand-600")
  end
end
