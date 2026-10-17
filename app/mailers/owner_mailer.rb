class OwnerMailer < ApplicationMailer
  def welcome(tenant_id, user_id)
    tenant = Tenant.find(tenant_id)

    ActsAsTenant.with_tenant(tenant) do
      owner = User.find(user_id)

      mail(
        to: owner.email,
        subject: "Sua conta no Zubio está pronta",
        body: welcome_body(tenant, owner),
        content_type: "text/plain"
      )
    end
  end

  def completed(tenant_id, user_id)
    tenant = Tenant.find(tenant_id)

    ActsAsTenant.with_tenant(tenant) do
      owner = User.find(user_id)

      mail(
        to: owner.email,
        subject: "Sua página está no ar no Zubio",
        body: completed_body(tenant, owner),
        content_type: "text/plain"
      )
    end
  end

  def password_reset(tenant_id, user_id, token)
    tenant = Tenant.find(tenant_id)

    ActsAsTenant.with_tenant(tenant) do
      owner = User.find(user_id)

      mail(
        to: owner.email,
        subject: "Recuperação de senha no Zubio",
        body: password_reset_body(tenant, owner, token),
        content_type: "text/plain"
      )
    end
  end

  def new_appointment(tenant_id, appointment_id)
    tenant = Tenant.find(tenant_id)

    ActsAsTenant.with_tenant(tenant) do
      appointment = Appointment.find(appointment_id)
      owner = User.owner.first

      mail(
        to: owner.email,
        subject: "Novo agendamento",
        body: new_appointment_body(tenant, owner, appointment),
        content_type: "text/plain"
      )
    end
  end

  def login_links(email)
    targets = User.login_targets_for(email)
    return if targets.empty?

    mail(
      to: email,
      subject: "Seus acessos no Zubio",
      body: login_links_body(targets),
      content_type: "text/plain"
    )
  end

  private

  def login_links_body(targets)
    links = targets.map { |target| login_link_line(target) }.join("\n")

    <<~TEXT
      Olá!

      Encontramos estas contas para o seu e-mail. Entre pelo link do seu estabelecimento:

      #{links}
    TEXT
  end

  def login_link_line(target)
    tenant = target.tenant
    label = tenant.name.presence || tenant.canonical_host

    "- #{label}: #{new_owner_session_url(host: tenant.canonical_host, email: target.email)}"
  end

  def welcome_body(tenant, owner)
    <<~TEXT
      Olá, #{owner.name}!

      Sua conta no Zubio está criada. Quando quiser voltar e continuar de onde parou, é por este link:

      #{new_owner_session_url(host: tenant.canonical_host)}
    TEXT
  end

  def completed_body(tenant, owner)
    <<~TEXT
      Olá, #{owner.name}!

      A página de #{tenant.name} está no ar. O endereço é:

      https://#{tenant.canonical_host}

      Mande esse link pra quem você quiser: é por ele que seus clientes marcam horário.
    TEXT
  end

  def new_appointment_body(tenant, owner, appointment)
    client = appointment.client

    <<~TEXT
      Olá, #{owner.name}!

      Você tem um novo agendamento:

      - Serviço: #{appointment.service.name}
      - Quando: #{appointment.starts_at.strftime("%d/%m/%Y")} às #{appointment.starts_at.strftime("%H:%M")}
      - Cliente: #{client.name}
      - Telefone: #{client.phone}

      Veja no painel do seu estabelecimento:

      #{owner_appointments_url(host: tenant.canonical_host)}
    TEXT
  end

  def password_reset_body(tenant, owner, token)
    <<~TEXT
      Olá, #{owner.name}!

      Recebemos um pedido para trocar a senha da sua conta no Zubio. Para escolher uma senha nova, abra este link em até 2 horas:

      #{edit_owner_password_reset_url(host: tenant.canonical_host, token: token)}

      Se você pediu mais de uma vez, só o link mais recente funciona. Se não foi você, ignore este e-mail: sua senha continua a mesma.
    TEXT
  end
end
