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

  private

  def welcome_body(tenant, owner)
    <<~TEXT
      Olá, #{owner.name}!

      Sua conta no Zubio está criada. Quando quiser voltar e continuar de onde parou, é por este link:

      #{new_owner_session_url(host: tenant.canonical_host)}
    TEXT
  end
end
