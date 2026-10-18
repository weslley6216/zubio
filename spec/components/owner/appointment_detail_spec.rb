require "rails_helper"

RSpec.describe Components::Owner::AppointmentDetail, type: :component do
  it "shows the time range, the confirmed badge and the long date" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    tenant = create(:tenant)
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45, price_cents: 6000)
    client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro", phone: "11988771234")
    appointment = ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: Time.zone.local(2026, 9, 8, 9, 45)) }

    html = ActsAsTenant.with_tenant(tenant) { render_phlex(described_class.new(appointment: appointment, visit_number: 1)) }

    expect(html).to include("09:45")
    expect(html).to include("10:30")
    expect(html).to include("Confirmado")
    expect(html).to include("Terça, 8 de setembro")
  end

  it "shows the client's initials, name, phone and visit number" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    tenant = create(:tenant)
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, duration_minutes: 45, price_cents: 6000)
    client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro", phone: "11988771234")
    appointment = ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: Time.zone.local(2026, 9, 8, 9, 45)) }

    html = ActsAsTenant.with_tenant(tenant) { render_phlex(described_class.new(appointment: appointment, visit_number: 1)) }

    expect(html).to include("AP")
    expect(html).to include("Ana Paula Ribeiro")
    expect(html).to include("(11) 98877-1234 · 1ª visita")
  end

  it "shows the visit number it is given" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    tenant = create(:tenant)
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, duration_minutes: 45)
    client = create(:client, tenant: tenant, phone: "11988771234")
    appointment = ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: Time.zone.local(2026, 9, 8, 9, 45)) }

    html = ActsAsTenant.with_tenant(tenant) { render_phlex(described_class.new(appointment: appointment, visit_number: 3)) }

    expect(html).to include("(11) 98877-1234 · 3ª visita")
  end

  it "renders a preloaded appointment without querying the database" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    tenant = create(:tenant)
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, duration_minutes: 45)
    client = create(:client, tenant: tenant)
    created = ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: Time.zone.local(2026, 9, 8, 9, 45)) }
    appointment = ActsAsTenant.with_tenant(tenant) { Appointment.includes(:client, :service).find(created.id) }

    queries = ActsAsTenant.with_tenant(tenant) { count_queries { render_phlex(described_class.new(appointment: appointment, visit_number: 1)) } }

    expect(queries).to eq(0)
  end

  it "shows the service, the price and the duration" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    tenant = create(:tenant)
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45, price_cents: 6000)
    client = create(:client, tenant: tenant)
    appointment = ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: Time.zone.local(2026, 9, 8, 9, 45)) }

    html = ActsAsTenant.with_tenant(tenant) { render_phlex(described_class.new(appointment: appointment, visit_number: 1)) }

    expect(html).to include("Design de sobrancelhas")
    expect(html).to include("R$ 60,00")
    expect(html).to include("45 min")
  end

  it "shows the price to the owner even when it is hidden from the public" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    tenant = create(:tenant)
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, duration_minutes: 45, price_cents: 6000, show_price: false)
    client = create(:client, tenant: tenant)
    appointment = ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: Time.zone.local(2026, 9, 8, 9, 45)) }

    html = ActsAsTenant.with_tenant(tenant) { render_phlex(described_class.new(appointment: appointment, visit_number: 1)) }

    expect(html).to include("R$ 60,00")
  end

  it "links WhatsApp and the phone call to the client's number" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    tenant = create(:tenant)
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, duration_minutes: 45)
    client = create(:client, tenant: tenant, phone: "11988771234")
    appointment = ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: Time.zone.local(2026, 9, 8, 9, 45)) }

    html = ActsAsTenant.with_tenant(tenant) { render_phlex(described_class.new(appointment: appointment, visit_number: 1)) }
    fragment = Nokogiri::HTML5.fragment(html)

    whatsapp_link = fragment.at_css(%(a[href="https://wa.me/5511988771234"]))
    phone_link = fragment.at_css(%(a[href="tel:+5511988771234"]))
    expect(whatsapp_link.text).to include("Chamar no WhatsApp")
    expect(phone_link.text).to include("Ligar")
    expect(whatsapp_link.ancestors("form")).to be_empty
    expect(phone_link.ancestors("form")).to be_empty
  end

  it "offers the cancel trigger and a confirmation sheet posting to the agenda frame" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    tenant = create(:tenant)
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, duration_minutes: 45)
    client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro")
    appointment = ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: Time.zone.local(2026, 9, 8, 9, 45)) }

    html = ActsAsTenant.with_tenant(tenant) { render_phlex(described_class.new(appointment: appointment, visit_number: 1)) }
    fragment = Nokogiri::HTML5.fragment(html)

    trigger = fragment.at_css(%(button[type="button"][data-action="dialog#open"]))
    expect(trigger.text).to include("Desmarcar este horário")
    expect(html).to include("O horário volta a aparecer livre na sua página. A Ana não é avisada sozinha: mande uma mensagem para ela.")
    sheet = fragment.at_css(%(dialog[data-dialog-target="sheet"]))
    expect(sheet.text).to include("Desmarcar terça, 8 set, às 09:45?")
    expect(sheet.text).to include("O horário volta a ficar livre para outras pessoas. Não dá para desfazer.")
    form = fragment.at_css("dialog form")
    expect(form["action"]).to eq("/owner/appointments/#{appointment.id}/cancellation")
    expect(form["method"]).to eq("post")
    expect(form["data-turbo-frame"]).to eq("agenda_day")
    expect(form["data-turbo-action"]).to eq("advance")
    expect(form.at_css(%(button[type="submit"])).text).to include("Sim, desmarcar")
    expect(fragment.at_css(%(dialog button[data-action="dialog#close"])).text).to include("Manter agendamento")
  end

  it "marks a cancelled appointment and drops the cancel button" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    tenant = create(:tenant)
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, duration_minutes: 45)
    client = create(:client, tenant: tenant)
    appointment = ActsAsTenant.with_tenant(tenant) { create(:appointment, :cancelled, tenant: tenant, professional: professional, service: service, client: client, starts_at: Time.zone.local(2026, 9, 8, 9, 45)) }

    html = ActsAsTenant.with_tenant(tenant) { render_phlex(described_class.new(appointment: appointment, visit_number: 1)) }

    expect(html).to include("Desmarcado")
    expect(html).not_to include("Desmarcar este horário")
    expect(html).not_to include("<dialog")
  end

  it "drops the cancel button on a past appointment" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    tenant = create(:tenant)
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, duration_minutes: 45)
    client = create(:client, tenant: tenant)
    appointment = ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: Time.zone.local(2026, 9, 7, 9, 45)) }

    html = ActsAsTenant.with_tenant(tenant) { render_phlex(described_class.new(appointment: appointment, visit_number: 1)) }

    expect(html).not_to include("Desmarcar este horário")
    expect(html).not_to include("<dialog")
  end

  it "points back and close to the appointment's day inside the detail frame" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    tenant = create(:tenant)
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, duration_minutes: 45)
    client = create(:client, tenant: tenant)
    appointment = ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: Time.zone.local(2026, 9, 8, 9, 45)) }

    html = ActsAsTenant.with_tenant(tenant) { render_phlex(described_class.new(appointment: appointment, visit_number: 1)) }
    fragment = Nokogiri::HTML5.fragment(html)

    links = fragment.css(%(a[data-turbo-frame="appointment_detail"]))
    matching = links.select { |link| link["href"].end_with?("day=2026-09-08") }
    expect(matching.size).to eq(2)
  end
end
