class Views::Client::Auth::Redirect < Views::Base
  TITLE = "Entrando com o Google…".freeze
  BUTTON_LABEL = "Continuar com o Google".freeze

  PAGE_CLASS = "mx-auto flex min-h-dvh w-full max-w-md flex-col items-center justify-center gap-4 px-6 text-center text-ink".freeze
  BUTTON_CLASS = "min-h-[44px] rounded-lg bg-brand-600 px-5 text-[15px] font-extrabold text-on-brand".freeze

  def initialize(state:)
    @state = state
  end

  def view_template
    render Views::Layouts::Application.new(title: TITLE, branding: Branding.platform_default) do
      div(class: PAGE_CLASS) do
        p { TITLE }
        form_with(url: "/auth/google_oauth2", method: :post, data: { turbo: false, controller: "auto-submit" }) do
          input(type: "hidden", name: "state", value: @state)
          button(type: "submit", class: BUTTON_CLASS) { BUTTON_LABEL }
        end
      end
    end
  end
end
