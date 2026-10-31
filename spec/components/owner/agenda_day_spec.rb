require "rails_helper"

RSpec.describe Components::Owner::AgendaDay, type: :component do
  it "flags only the appointments in the out-of-hours set" do
    tenant = create(:tenant)
    branding = create(:branding, tenant: tenant)
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45)
    in_hours_client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro")
    out_of_hours_client = create(:client, tenant: tenant, name: "Camila Nunes")
    day = Date.current
    in_hours_appointment = ActsAsTenant.with_tenant(tenant) do
      create(:appointment, tenant: tenant, professional: professional, service: service, client: in_hours_client, starts_at: day.in_time_zone.change(hour: 9, min: 45))
    end
    out_of_hours_appointment = ActsAsTenant.with_tenant(tenant) do
      create(:appointment, tenant: tenant, professional: professional, service: service, client: out_of_hours_client, starts_at: day.in_time_zone.change(hour: 18, min: 30))
    end

    html = render_phlex(described_class.new(tenant: tenant, branding: branding, day: day,
      appointments: [ in_hours_appointment, out_of_hours_appointment ], out_of_hours: Set[out_of_hours_appointment]))
    fragment = Nokogiri::HTML5.fragment(html)
    in_hours_row = fragment.at_css(%(div[data-appointment-id="#{in_hours_appointment.id}"]))
    out_of_hours_row = fragment.at_css(%(div[data-appointment-id="#{out_of_hours_appointment.id}"]))

    expect(in_hours_row.text).to include("Confirmado")
    expect(in_hours_row["class"]).not_to include("border-danger")
    expect(out_of_hours_row.text).to include("Fora do expediente")
    expect(out_of_hours_row["class"]).to include("border-danger")
  end

  it "wraps the list region in frame-content and renders a row skeleton" do
    tenant = create(:tenant)
    branding = create(:branding, tenant: tenant)
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, duration_minutes: 45)
    client = create(:client, tenant: tenant)
    day = Date.current
    appointment = ActsAsTenant.with_tenant(tenant) do
      create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: day.in_time_zone.change(hour: 9, min: 45))
    end

    html = render_phlex(described_class.new(tenant: tenant, branding: branding, day: day, appointments: [ appointment ]))
    fragment = Nokogiri::HTML5.fragment(html)

    frame_content = fragment.at_css("[data-frame-content]")
    expect(frame_content.at_css(%(div[data-appointment-id="#{appointment.id}"]))).not_to be_nil
    skeleton = fragment.at_css("[data-skeleton][aria-hidden='true']")
    expect(skeleton).not_to be_nil
    expect(skeleton.css("> *").size).to eq(3)
    expect(frame_content.at_css("h1")).to be_nil
    expect(frame_content.text).not_to include(Components::Owner::AgendaDay::NEW_APPOINTMENT_LABEL)
    expect(fragment.at_css("h1")).not_to be_nil
    expect(fragment.text).to include(Components::Owner::AgendaDay::NEW_APPOINTMENT_LABEL)
  end

  it "draws each skeleton piece in the shape of an appointment row" do
    tenant = create(:tenant)
    branding = create(:branding, tenant: tenant)
    day = Date.current

    html = render_phlex(described_class.new(tenant: tenant, branding: branding, day: day, appointments: []))
    fragment = Nokogiri::HTML5.fragment(html)

    pieces = fragment.at_css("[data-skeleton]").css("> *")
    expect(pieces.size).to eq(3)
    first_piece = pieces.first.at_css("> *")
    expect(first_piece["class"]).to include("border").and include("bg-surface")
    expect(first_piece.css(".bg-line-strong").size).to be >= 3
    expect(first_piece.at_css(".w-12")).not_to be_nil
  end

  it "lists only the occupying appointments in time order and tucks the cancelled one into the group" do
    tenant = create(:tenant)
    branding = create(:branding, tenant: tenant)
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant)
    confirmed_client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro")
    completed_client = create(:client, tenant: tenant, name: "Juliana Prado")
    cancelled_client = create(:client, tenant: tenant, name: "Bruna Salles")
    day = Date.current
    confirmed = ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional, service: service, client: confirmed_client, starts_at: day.in_time_zone.change(hour: 9)) }
    cancelled = ActsAsTenant.with_tenant(tenant) { create(:appointment, :cancelled, tenant: tenant, professional: professional, service: service, client: cancelled_client, starts_at: day.in_time_zone.change(hour: 9, min: 50)) }
    completed = ActsAsTenant.with_tenant(tenant) { create(:appointment, :completed, tenant: tenant, professional: professional, service: service, client: completed_client, starts_at: day.in_time_zone.change(hour: 10)) }

    html = render_phlex(described_class.new(tenant: tenant, branding: branding, day: day, appointments: [ confirmed, cancelled, completed ]))
    fragment = Nokogiri::HTML5.fragment(html)
    list_ids = fragment.css("[data-frame-content] [data-appointment-id]").map { |row| row["data-appointment-id"].to_i }
    group = fragment.at_css("details")
    without_group = fragment.dup.tap { |copy| copy.at_css("details")&.remove }

    expect(list_ids).to eq([ confirmed.id, completed.id ])
    expect(group.text).to include("Bruna Salles")
    expect(group.text).to include("Desmarcado")
    expect(without_group.text).not_to include("Bruna Salles")
  end

  it "keeps a no-show in the day's list at its time" do
    tenant = create(:tenant)
    branding = create(:branding, tenant: tenant)
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant)
    confirmed_client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro")
    no_show_client = create(:client, tenant: tenant, name: "Camila Nunes")
    day = Date.current
    confirmed = ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional, service: service, client: confirmed_client, starts_at: day.in_time_zone.change(hour: 9)) }
    no_show = ActsAsTenant.with_tenant(tenant) { create(:appointment, :no_show, tenant: tenant, professional: professional, service: service, client: no_show_client, starts_at: day.in_time_zone.change(hour: 11)) }

    html = render_phlex(described_class.new(tenant: tenant, branding: branding, day: day, appointments: [ confirmed, no_show ]))
    fragment = Nokogiri::HTML5.fragment(html)
    no_show_row = fragment.at_css(%(div[data-appointment-id="#{no_show.id}"]))

    expect(no_show_row.text).to include("Falta")
    expect(fragment.at_css("details")).to be_nil
  end

  it "collects the cancelled appointments into a closed group labelled in the plural" do
    tenant = create(:tenant)
    branding = create(:branding, tenant: tenant)
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant)
    day = Date.current
    cancelled_appointments = [ 9, 10, 11 ].map do |hour|
      client = create(:client, tenant: tenant)
      ActsAsTenant.with_tenant(tenant) { create(:appointment, :cancelled, tenant: tenant, professional: professional, service: service, client: client, starts_at: day.in_time_zone.change(hour: hour)) }
    end

    html = render_phlex(described_class.new(tenant: tenant, branding: branding, day: day, appointments: cancelled_appointments))
    fragment = Nokogiri::HTML5.fragment(html)
    group = fragment.at_css("details[data-preserve-open]")
    without_group = fragment.dup.tap { |copy| copy.at_css("details")&.remove }

    expect(group).not_to be_nil
    expect(group["open"]).to be_nil
    expect(group.at_css("summary").text).to include("3 desmarcados")
    expect(without_group.text).not_to include("Desmarcado")
  end

  it "renders no group when nothing is cancelled" do
    tenant = create(:tenant)
    branding = create(:branding, tenant: tenant)
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant)
    client = create(:client, tenant: tenant)
    day = Date.current
    confirmed = ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: day.in_time_zone.change(hour: 9)) }

    html = render_phlex(described_class.new(tenant: tenant, branding: branding, day: day, appointments: [ confirmed ]))
    fragment = Nokogiri::HTML5.fragment(html)

    expect(fragment.at_css("details")).to be_nil
  end

  it "shows the empty state and the collapsed group on a day with only cancellations" do
    tenant = create(:tenant)
    branding = create(:branding, tenant: tenant)
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant)
    day = Date.current
    cancelled_appointments = [ 9, 10 ].map do |hour|
      client = create(:client, tenant: tenant)
      ActsAsTenant.with_tenant(tenant) { create(:appointment, :cancelled, tenant: tenant, professional: professional, service: service, client: client, starts_at: day.in_time_zone.change(hour: hour)) }
    end

    html = render_phlex(described_class.new(tenant: tenant, branding: branding, day: day, appointments: cancelled_appointments))
    fragment = Nokogiri::HTML5.fragment(html)
    group = fragment.at_css("details[data-preserve-open]")

    expect(fragment.text).to include("0 atendimentos")
    expect(fragment.text).to include(Components::Owner::AgendaDay::EMPTY_TITLE)
    expect(fragment.text).to include(tenant.canonical_host)
    expect(group.at_css("summary").text).to include("2 desmarcados")
    expect(group["open"]).to be_nil
  end

  it "labels a single cancelled appointment in the singular" do
    tenant = create(:tenant)
    branding = create(:branding, tenant: tenant)
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant)
    client = create(:client, tenant: tenant)
    day = Date.current
    cancelled = ActsAsTenant.with_tenant(tenant) { create(:appointment, :cancelled, tenant: tenant, professional: professional, service: service, client: client, starts_at: day.in_time_zone.change(hour: 9)) }

    html = render_phlex(described_class.new(tenant: tenant, branding: branding, day: day, appointments: [ cancelled ]))
    fragment = Nokogiri::HTML5.fragment(html)
    summary = fragment.at_css("summary")

    expect(summary.text).to include("1 desmarcado")
    expect(summary.text).not_to include("1 desmarcados")
  end
end
