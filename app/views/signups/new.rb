class Views::Signups::New < Views::Base
  FIELD_CLASS = "mt-1 w-full rounded-md border border-gray-300 px-3 py-2"

  def initialize(tenant:, user:, branding:)
    @tenant = tenant
    @user = user
    @branding = branding
  end

  def view_template
    render Views::Layouts::Application.new(title: "Criar conta · Zubio", branding: @branding) do
      div(class: "mx-auto mt-16 w-full max-w-sm") do
        h1(class: "mb-6 text-center text-2xl font-semibold") { "Criar sua conta" }
        render_alert
        form_with(url: signup_path, method: :post, class: "space-y-4") do |form|
          render_establishment_name_field(form)
          render_subdomain_field(form)
          render_owner_name_field(form)
          render_email_field(form)
          render_password_field(form)
          render_password_confirmation_field(form)
          form.submit "Criar conta", class: "w-full rounded-md bg-brand-600 px-4 py-2 font-medium text-on-brand"
        end
      end
    end
  end

  private

  def render_alert
    return unless (alert = flash[:alert])

    p(class: "mb-4 rounded-md bg-red-50 px-4 py-2 text-sm text-red-700") { alert }
  end

  def render_establishment_name_field(form)
    div do
      form.label :tenant_name, "Nome do estabelecimento", class: "block text-sm font-medium"
      form.text_field :tenant_name, name: "tenant[name]", value: @tenant.name, required: true, class: FIELD_CLASS
      render_errors(@tenant.errors[:name])
    end
  end

  def render_subdomain_field(form)
    div do
      form.label :tenant_subdomain, "Subdomínio", class: "block text-sm font-medium"
      form.text_field :tenant_subdomain, name: "tenant[subdomain]", value: @tenant.subdomain, required: true, class: FIELD_CLASS
      render_errors(@tenant.errors[:subdomain])
    end
  end

  def render_owner_name_field(form)
    div do
      form.label :user_name, "Seu nome", class: "block text-sm font-medium"
      form.text_field :user_name, name: "user[name]", value: @user.name, required: true, class: FIELD_CLASS
      render_errors(@user.errors[:name])
    end
  end

  def render_email_field(form)
    div do
      form.label :user_email, "E-mail", class: "block text-sm font-medium"
      form.email_field :user_email, name: "user[email]", value: @user.email, required: true, class: FIELD_CLASS
      render_errors(@user.errors[:email])
    end
  end

  def render_password_field(form)
    div do
      form.label :user_password, "Senha", class: "block text-sm font-medium"
      form.password_field :user_password, name: "user[password]", required: true, class: FIELD_CLASS
      render_errors(@user.errors[:password])
    end
  end

  def render_password_confirmation_field(form)
    div do
      form.label :user_password_confirmation, "Confirme a senha", class: "block text-sm font-medium"
      form.password_field :user_password_confirmation, name: "user[password_confirmation]", required: true, class: FIELD_CLASS
      render_errors(@user.errors[:password_confirmation])
    end
  end

  def render_errors(messages)
    return if messages.empty?

    p(class: "mt-1 text-sm text-red-700") { messages.join(", ") }
  end
end
