class ClientMailer < ApplicationMailer
  def booking_receipt(tenant_id, appointment_id)
    tenant = Tenant.find(tenant_id)

    ActsAsTenant.with_tenant(tenant) do
      appointment = Appointment.find(appointment_id)

      mail(
        to: appointment.client.email,
        subject: "Seu horário na #{tenant.name}",
        body: booking_receipt_body(tenant, appointment),
        content_type: "text/plain"
      )
    end
  end

  private

  def booking_receipt_body(tenant, appointment)
    client = appointment.client

    <<~TEXT
      Olá, #{client.name.split.first}!

      Seu horário na #{tenant.name} está confirmado:

      - Serviço: #{appointment.service.name}
      - Quando: #{appointment.starts_at.strftime("%d/%m/%Y")} às #{appointment.starts_at.strftime("%H:%M")}

      Para ver ou desmarcar, é por este link:

      #{client_appointment_url(host: tenant.canonical_host, token: appointment.cancel_token)}
    TEXT
  end
end
