class Views::Signups::New < Views::Base
  include Components::Form::Styles

  TOGGLE_CLASS = "mt-1 text-xs font-medium text-brand-600".freeze

  def initialize(user:, branding:)
    @user = user
    @branding = branding
  end

  def view_template
    render Views::Layouts::Application.new(title: "Criar conta · Zubio", branding: @branding) do
      div(class: "flex min-h-dvh flex-col") do
        render Components::Platform::Header.new
        div(class: "flex-grow") do
          render Components::Panel.new(title: "Criar sua conta") do
            form_with(url: signup_path, method: :post, class: "space-y-4", data: { turbo: false }) do |form|
              render_owner_name_field(form)
              render_email_field(form)
              render_password_field(form)
              form.submit "Criar conta", class: SUBMIT
            end
          end
        end
        render Components::Platform::Footer.new
      end
    end
  end

  private

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
    div(data: { controller: "password-visibility" }) do
      form.label :user_password, "Senha", class: LABEL
      form.password_field :user_password, name: "user[password]", required: true,
        minlength: User::MINIMUM_PASSWORD_LENGTH, class: CONTROL,
        data: { "password-visibility-target": "input" }
      p(class: HINT) { "Mínimo de #{User::MINIMUM_PASSWORD_LENGTH} caracteres" }
      button(type: "button", class: TOGGLE_CLASS, data: { action: "password-visibility#toggle" }) do
        span(data: { "password-visibility-target": "hidden" }) { "Mostrar senha" }
        span(data: { "password-visibility-target": "shown" }, hidden: true) { "Ocultar senha" }
      end
      render Components::Form::Errors.new(messages: @user.errors[:password])
    end
  end
end
