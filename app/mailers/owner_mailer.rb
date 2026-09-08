class OwnerMailer < ApplicationMailer
  def welcome(tenant_id, user_id)
    tenant = Tenant.find(tenant_id)

    ActsAsTenant.with_tenant(tenant) do
      owner = User.find(user_id)

      # The app still runs under the :en default locale while its copy is
      # hardcoded pt-BR, so this asks for the locale by name. The wrapper goes
      # away once config.i18n.default_locale moves.
      I18n.with_locale(:"pt-BR") do
        mail(
          to: owner.email,
          subject: I18n.t("owner.mailer.welcome.subject", establishment: tenant.name),
          body: I18n.t(
            "owner.mailer.welcome.body",
            name: owner.name,
            establishment: tenant.name,
            url: new_owner_session_url(host: tenant.canonical_host)
          ),
          content_type: "text/plain"
        )
      end
    end
  end
end
