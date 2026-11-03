class ClientMailer < ApplicationMailer
  def booking_receipt(tenant_id, appointment_id)
    tenant = Tenant.find(tenant_id)

    ActsAsTenant.with_tenant(tenant) do
      appointment = Appointment.find(appointment_id)

      mail(from: email_address_with_name(self.class.default_params[:from], tenant.name), to: appointment.client.email,
        subject: "Seu horário na #{tenant.name}") do |format|
        format.text { render plain: booking_receipt_text(tenant, appointment) }
        format.html { render Views::Mailers::Client::BookingReceipt.new(tenant: tenant, branding: tenant.branding_or_default, appointment: appointment) }
      end
    end
  end

  private

  def booking_receipt_text(tenant, appointment)
    client = appointment.client
    labels = Appointment::Labels.new(appointment)

    <<~TEXT
      Olá, #{client.name.split.first}!

      Seu horário na #{tenant.name} está confirmado:

      - Quando: #{labels.when_label}
      - Serviço: #{appointment.service.name}
      - Duração: #{labels.duration_label}
      - Valor: #{labels.price_label}

      Para ver ou desmarcar, é por este link:

      #{client_appointment_url(host: tenant.canonical_host, token: appointment.cancel_token)}
    TEXT
  end
end
