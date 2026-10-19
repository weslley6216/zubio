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

  it "shows the completed badge on the active row with its phone" do
    tenant = create(:tenant)
    client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro", phone: "11988771234")
    service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45)
    appointment = ActsAsTenant.with_tenant(tenant) do
      create(:appointment, :completed, tenant: tenant, client: client, service: service, starts_at: Time.current.change(hour: 9, min: 45))
    end

    html = render_phlex(described_class.new(appointment: appointment))

    expect(html).to include("Concluído")
    expect(html).to include("bg-success-soft")
    expect(html).to include("text-success")
    expect(html).to include(%(href="tel:+5511988771234"))
    expect(html).not_to include("line-through")
  end

  it "shows the no-show badge on the active row with its phone" do
    tenant = create(:tenant)
    client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro", phone: "11988771234")
    service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45)
    appointment = ActsAsTenant.with_tenant(tenant) do
      create(:appointment, :no_show, tenant: tenant, client: client, service: service, starts_at: Time.current.change(hour: 9, min: 45))
    end

    html = render_phlex(described_class.new(appointment: appointment))

    expect(html).to include("Falta")
    expect(html).to include("bg-danger-soft")
    expect(html).to include("text-danger")
    expect(html).to include(%(href="tel:+5511988771234"))
    expect(html).not_to include("line-through")
  end

  it "links the no-show row to its detail inside the detail frame" do
    tenant = create(:tenant)
    client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro", phone: "11988771234")
    service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45)
    appointment = ActsAsTenant.with_tenant(tenant) do
      create(:appointment, :no_show, tenant: tenant, client: client, service: service, starts_at: Time.current.change(hour: 9, min: 45))
    end

    html = render_phlex(described_class.new(appointment: appointment))
    fragment = Nokogiri::HTML5.fragment(html)
    link = fragment.at_css(%(a[href="/owner/appointments/#{appointment.id}"]))

    expect(link["data-turbo-frame"]).to eq("appointment_detail")
    expect(link["data-turbo-action"]).to eq("advance")
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

  it "frames the out-of-hours row in danger with the notice badge and the danger time" do
    tenant = create(:tenant)
    client = create(:client, tenant: tenant, name: "Camila Nunes", phone: "11988771234")
    service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45)
    appointment = ActsAsTenant.with_tenant(tenant) do
      create(:appointment, tenant: tenant, client: client, service: service, starts_at: Time.current.change(hour: 18, min: 30))
    end

    html = render_phlex(described_class.new(appointment: appointment, out_of_hours: true))

    expect(html).to include("border-danger")
    expect(html).to include("text-danger")
    expect(html).to include("bg-danger-soft")
    expect(html).to include("Fora do expediente")
    expect(html).not_to include("Confirmado")
    expect(html).not_to include("border-line")
  end

  it "leaves an in-hours row without the danger frame or notice" do
    tenant = create(:tenant)
    client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro", phone: "11988771234")
    service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45)
    appointment = ActsAsTenant.with_tenant(tenant) do
      create(:appointment, tenant: tenant, client: client, service: service, starts_at: Time.current.change(hour: 9, min: 45))
    end

    html = render_phlex(described_class.new(appointment: appointment, out_of_hours: false))

    expect(html).to include("Confirmado")
    expect(html).not_to include("Fora do expediente")
    expect(html).not_to include("border-danger")
  end

  it "keeps the danger frame on the selected out-of-hours row and marks it current" do
    tenant = create(:tenant)
    client = create(:client, tenant: tenant, name: "Camila Nunes", phone: "11988771234")
    service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45)
    appointment = ActsAsTenant.with_tenant(tenant) do
      create(:appointment, tenant: tenant, client: client, service: service, starts_at: Time.current.change(hour: 18, min: 30))
    end

    html = render_phlex(described_class.new(appointment: appointment, out_of_hours: true, selected: true))
    fragment = Nokogiri::HTML5.fragment(html)
    link = fragment.at_css(%(a[href="/owner/appointments/#{appointment.id}"]))

    expect(link["aria-current"]).to eq("true")
    expect(html).to include("border-danger")
    expect(html).not_to include("border-2 border-brand-600")
    expect(fragment.at_css(%([data-out-of-hours="true"]))).to be_present
  end
end
