class OwnerMailer < ApplicationMailer
  def welcome(tenant_id, user_id)
    tenant = Tenant.find(tenant_id)

    ActsAsTenant.with_tenant(tenant) do
      owner = User.find(user_id)

      mail(
        to: owner.email,
        subject: "#{tenant.name} está no ar no Zubio",
        body: welcome_body(tenant, owner),
        content_type: "text/plain"
      )
    end
  end

  private

  def welcome_body(tenant, owner)
    <<~TEXT
      Olá, #{owner.name}!

      A conta de #{tenant.name} está pronta. O endereço do seu estabelecimento é:

      #{new_owner_session_url(host: tenant.canonical_host)}

      Guarde esse link: é por ele que você e sua equipe entram no painel.
    TEXT
  end
end
