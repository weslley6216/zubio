class Views::Owner::Sessions::New < Views::Base
  FIELD_CLASS = "mt-1 w-full rounded-md border border-gray-300 px-3 py-2"

  def initialize(branding:)
    @branding = branding
  end

  def view_template
    render Views::Layouts::Application.new(title: "Entrar · Zubio", branding: @branding) do
      div(class: "mx-auto mt-16 w-full max-w-sm") do
        h1(class: "mb-6 text-center text-2xl font-semibold") { "Entrar" }
        render_alert
        form_with(url: owner_session_path, method: :post, class: "space-y-4") do |form|
          div do
            form.label :email, "E-mail", class: "block text-sm font-medium"
            form.email_field :email, required: true, class: FIELD_CLASS
          end
          div do
            form.label :password, "Senha", class: "block text-sm font-medium"
            form.password_field :password, required: true, class: FIELD_CLASS
          end
          form.submit "Entrar", class: "w-full rounded-md bg-brand-600 px-4 py-2 font-medium text-on-brand"
        end
      end
    end
  end

  private

  def render_alert
    return unless (alert = flash[:alert])

    p(class: "mb-4 rounded-md bg-red-50 px-4 py-2 text-sm text-red-700") { alert }
  end
end
