class Views::Owner::Sessions::New < Views::Base
  include Components::Form::Styles

  def initialize(branding:)
    @branding = branding
  end

  def view_template
    render Views::Layouts::Application.new(title: "Entrar · Zubio", branding: @branding) do
      render Components::Panel.new(title: "Entrar") do
        render Components::Alert.new(text: flash[:alert]) if flash[:alert]
        form_with(url: owner_session_path, method: :post, class: "space-y-4") do |form|
          div do
            form.label :email, "E-mail", class: LABEL
            form.email_field :email, required: true, class: CONTROL
          end
          div do
            form.label :password, "Senha", class: LABEL
            form.password_field :password, required: true, class: CONTROL
          end
          form.submit "Entrar", class: SUBMIT
        end
      end
    end
  end
end
