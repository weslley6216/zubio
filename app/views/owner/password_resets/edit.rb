class Views::Owner::PasswordResets::Edit < Views::Base
  include Components::Form::Styles

  def initialize(branding:, user:, token:)
    @branding = branding
    @user = user
    @token = token
  end

  def view_template
    render Views::Layouts::Application.new(title: "Nova senha · Zubio", branding: @branding) do
      render Components::Panel.new(title: "Escolher nova senha") do
        form_with(url: owner_password_reset_path, method: :patch, class: "space-y-4") do |form|
          form.hidden_field :token, value: @token
          div do
            form.label :password, "Nova senha", class: LABEL
            form.password_field :password, required: true, minlength: User::MINIMUM_PASSWORD_LENGTH, class: CONTROL
            p(class: HINT) { "Mínimo de #{User::MINIMUM_PASSWORD_LENGTH} caracteres" }
            render Components::Form::Errors.new(messages: @user.errors[:password])
          end
          form.submit "Salvar nova senha", class: SUBMIT
        end
      end
    end
  end
end
