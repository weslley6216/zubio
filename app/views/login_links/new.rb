class Views::LoginLinks::New < Views::Base
  include Components::Form::Styles

  def initialize(branding:)
    @branding = branding
  end

  def view_template
    render Views::Layouts::Application.new(title: "Entrar · Zubio", branding: @branding) do
      render Components::Platform::Header.new
      render Components::Panel.new(title: "Entrar") do
        p(class: HINT) { "Informe o e-mail da sua conta. Enviamos o link de acesso de cada estabelecimento em que você é dono." }
        form_with(url: login_link_path, method: :post, class: "space-y-4") do |form|
          div do
            form.label :email, "E-mail", class: LABEL
            form.email_field :email, required: true, class: CONTROL
          end
          form.submit "Enviar o link de acesso", class: SUBMIT
        end
      end
      render Components::Platform::Footer.new
    end
  end
end
