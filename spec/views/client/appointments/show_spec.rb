require "rails_helper"

RSpec.describe Views::Client::Appointments::Show, type: :component do
  it "renders the active state with the cancel affordance" do
    appointment = create(:appointment)
    branding = build(:branding, tenant: appointment.tenant)

    html = Nokogiri::HTML5(render_phlex(described_class.new(tenant: appointment.tenant, branding: branding, appointment: appointment, service: appointment.service, professional: appointment.professional))).at_css("[data-appointment]").to_html

    expect(html).to include("Seu horário")
    expect(html).to include("Marcar outro horário")
    expect(html).to include("Desmarcar este horário")
    expect(html).to include("Este link mostra só este agendamento.")
  end

  it "renders the cancelled state struck through and without the cancel affordance" do
    tenant = create(:tenant, name: "Mary Sombracelhas")
    professional = create(:professional, tenant: tenant, display_name: "Mary Sombracelhas")
    appointment = create(:appointment, :cancelled, tenant: tenant, professional: professional)
    branding = build(:branding, tenant: tenant)

    html = Nokogiri::HTML5(render_phlex(described_class.new(tenant: tenant, branding: branding, appointment: appointment, service: appointment.service, professional: professional))).at_css("[data-appointment]").to_html

    expect(html).to include("Horário desmarcado")
    expect(html).to include("A Mary já vê o horário livre na agenda dela.")
    expect(html).to include("Se abrir este link de novo, você vê esta mesma tela.")
    expect(html).to include("line-through")
    expect(html).not_to include("Desmarcar este horário")
  end

  it "renders the past state without the cancel affordance or the sheet" do
    appointment = create(:appointment, :past)
    branding = build(:branding, tenant: appointment.tenant)

    html = Nokogiri::HTML5(render_phlex(described_class.new(tenant: appointment.tenant, branding: branding, appointment: appointment, service: appointment.service, professional: appointment.professional))).at_css("[data-appointment]").to_html

    expect(html).to include("Seu horário")
    expect(html).to include(appointment.service.name)
    expect(html).not_to include("Desmarcar este horário")
    expect(html).not_to include("<dialog")
  end

  it "paints the three states with theme-aware tokens only" do
    active = create(:appointment)
    cancelled = create(:appointment, :cancelled)
    past = create(:appointment, :past)

    markup = [ active, cancelled, past ].map do |appointment|
      branding = build(:branding, tenant: appointment.tenant)
      Nokogiri::HTML5(render_phlex(described_class.new(tenant: appointment.tenant, branding: branding, appointment: appointment, service: appointment.service, professional: appointment.professional))).at_css("[data-appointment]").to_html
    end.join

    expect(markup).to include("bg-surface")
    expect(markup).to include("text-ink")
    expect(markup).not_to match(/#[0-9a-f]{6}/i)
    expect(markup).not_to include("rgb(")
  end
end
