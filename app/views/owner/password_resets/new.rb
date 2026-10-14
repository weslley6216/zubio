class Views::Owner::PasswordResets::New < Views::Base
  include Components::Form::Styles

  def initialize(branding:)
    @branding = branding
  end

  def view_template
    render Views::Layouts::Application.new(title: "Recuperar senha · Zubio", branding: @branding) do
      render Components::Panel.new(title: "Recuperar senha") do
        p(class: HINT) { "Informe o e-mail da sua conta. Enviamos um link para você escolher uma nova senha." }
        form_with(url: owner_password_reset_path, method: :post, class: "space-y-4") do |form|
          div do
            form.label :email, "E-mail", class: LABEL
            form.email_field :email, required: true, class: CONTROL
          end
          form.submit "Enviar o link", class: SUBMIT
        end
      end
    end
  end
end
