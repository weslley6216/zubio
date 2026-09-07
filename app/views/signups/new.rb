class Views::Signups::New < Views::Base
  include Components::Form::Styles

  def initialize(tenant:, user:, branding:)
    @tenant = tenant
    @user = user
    @branding = branding
  end

  def view_template
    render Views::Layouts::Application.new(title: "Criar conta · Zubio", branding: @branding) do
      div(class: "mx-auto mt-16 w-full max-w-sm") do
        h1(class: "mb-6 text-center text-2xl font-semibold") { "Criar sua conta" }
        render Components::Alert.new(text: flash[:alert]) if flash[:alert]
        form_with(url: signup_path, method: :post, class: "space-y-4") do |form|
          render_establishment_name_field(form)
          render_subdomain_field(form)
          render_owner_name_field(form)
          render_email_field(form)
          render_password_field(form)
          render_password_confirmation_field(form)
          form.submit "Criar conta", class: SUBMIT
        end
      end
    end
  end

  private

  def render_establishment_name_field(form)
    div do
      form.label :tenant_name, "Nome do estabelecimento", class: LABEL
      form.text_field :tenant_name, name: "tenant[name]", value: @tenant.name, required: true, class: CONTROL
      render Components::Form::Errors.new(messages: @tenant.errors[:name])
    end
  end

  def render_subdomain_field(form)
    div do
      form.label :tenant_subdomain, "Subdomínio", class: LABEL
      form.text_field :tenant_subdomain, name: "tenant[subdomain]", value: @tenant.subdomain, required: true, class: CONTROL
      render Components::Form::Errors.new(messages: @tenant.errors[:subdomain])
    end
  end

  def render_owner_name_field(form)
    div do
      form.label :user_name, "Seu nome", class: LABEL
      form.text_field :user_name, name: "user[name]", value: @user.name, required: true, class: CONTROL
      render Components::Form::Errors.new(messages: @user.errors[:name])
    end
  end

  def render_email_field(form)
    div do
      form.label :user_email, "E-mail", class: LABEL
      form.email_field :user_email, name: "user[email]", value: @user.email, required: true, class: CONTROL
      render Components::Form::Errors.new(messages: @user.errors[:email])
    end
  end

  def render_password_field(form)
    div do
      form.label :user_password, "Senha", class: LABEL
      form.password_field :user_password, name: "user[password]", required: true, class: CONTROL
      render Components::Form::Errors.new(messages: @user.errors[:password])
    end
  end

  def render_password_confirmation_field(form)
    div do
      form.label :user_password_confirmation, "Confirme a senha", class: LABEL
      form.password_field :user_password_confirmation, name: "user[password_confirmation]", required: true, class: CONTROL
      render Components::Form::Errors.new(messages: @user.errors[:password_confirmation])
    end
  end
end
