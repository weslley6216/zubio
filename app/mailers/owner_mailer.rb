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
end
