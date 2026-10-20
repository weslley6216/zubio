class Views::Client::AccountPhones::New < Views::Base
  BACK_LABEL = "Voltar".freeze
  TITLE = "Qual é o seu WhatsApp?".freeze
  SUBTITLE = "É por ele que a %s fala com você sobre seus horários. Pedimos só desta vez.".freeze
  NAME_LABEL = "Nome".freeze
  PHONE_LABEL = "WhatsApp".freeze
  PHONE_PLACEHOLDER = "(11) 90000-0000".freeze
  CONTINUE_LABEL = "Continuar".freeze

  PAGE_CLASS = "mx-auto flex min-h-dvh w-full max-w-[430px] flex-col bg-surface-2 leading-[normal] text-ink".freeze
  HEADER_CLASS = "flex items-center gap-3 bg-brand-600 px-5 py-3.5 text-on-brand".freeze
  BACK_CLASS = "grid h-10 w-10 flex-none place-items-center rounded-[10px] bg-white/18".freeze
  BACK_ICON_CLASS = "h-5 w-5".freeze
  NAME_CLASS = "grow truncate text-[15px] font-extrabold tracking-[-0.01em]".freeze
  MAIN_CLASS = "flex grow flex-col gap-5 px-5 py-6".freeze
  HEADING_BLOCK_CLASS = "flex flex-col gap-1.5".freeze
  HEADING_CLASS = "text-[22px] leading-[normal] font-extrabold tracking-[-0.02em]".freeze
  SUBTITLE_CLASS = "text-[14px] leading-[1.5] text-pretty text-ink-muted".freeze
  CARD_CLASS = "flex flex-col gap-3.5 rounded-2xl border border-line bg-surface p-5".freeze
  NAME_ROW_CLASS = "flex items-baseline justify-between gap-4".freeze
  NAME_ROW_LABEL_CLASS = "flex-none text-[13px] text-ink-muted".freeze
  NAME_ROW_VALUE_CLASS = "text-right text-[14px] font-bold".freeze
  DIVIDER_CLASS = "h-px bg-line".freeze
  FIELD_WRAPPER_CLASS = "flex flex-col gap-1.5".freeze
  FIELD_LABEL_CLASS = "text-[11px] font-bold uppercase tracking-[0.06em] text-ink-muted".freeze
  FIELD_CLASS = "flex min-h-[48px] items-center rounded-lg border-2 border-brand-600 bg-surface px-3 text-[15px] font-bold tabular-nums".freeze
  SUBMIT_CLASS = "flex min-h-[50px] w-full items-center justify-center gap-2 rounded-xl bg-brand-600 text-[15px] font-extrabold text-on-brand".freeze

  def initialize(tenant:, branding:, name:, token:, client: nil)
    @tenant = tenant
    @branding = branding
    @name = name
    @token = token
    @client = client
  end

  def view_template
    render Views::Layouts::Application.new(title: @tenant.name, branding: @branding) do
      div(class: PAGE_CLASS) do
        render_header
        render_main
      end
    end
  end

  private

  def render_header
    header(class: HEADER_CLASS) do
      a(href: establishment_path, class: BACK_CLASS, aria_label: BACK_LABEL) { render_back_icon }
      h1(class: NAME_CLASS) { @tenant.name }
    end
  end

  def render_back_icon
    svg(viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2.5", stroke_linecap: "round",
      stroke_linejoin: "round", aria_hidden: "true", class: BACK_ICON_CLASS) do |icon|
      icon.path(d: "m15 6-6 6 6 6")
    end
  end

  def render_main
    main(class: MAIN_CLASS) do
      div(class: HEADING_BLOCK_CLASS) do
        h1(class: HEADING_CLASS) { TITLE }
        p(class: SUBTITLE_CLASS) { SUBTITLE % @tenant.name }
      end
      render_form
    end
  end

  def render_form
    form_with(url: client_account_phone_path, method: :post, class: "contents") do
      div(class: CARD_CLASS) do
        div(class: NAME_ROW_CLASS) do
          span(class: NAME_ROW_LABEL_CLASS) { NAME_LABEL }
          span(class: NAME_ROW_VALUE_CLASS) { @name }
        end
        div(class: DIVIDER_CLASS)
        div(class: FIELD_WRAPPER_CLASS) do
          label(class: FIELD_LABEL_CLASS) { PHONE_LABEL }
          input(type: "tel", name: "phone", placeholder: PHONE_PLACEHOLDER, class: FIELD_CLASS)
          render Components::Form::Errors.new(messages: @client ? @client.errors[:phone] : [])
        end
      end
      input(type: "hidden", name: "token", value: @token)
      button(type: "submit", class: SUBMIT_CLASS) { CONTINUE_LABEL }
    end
  end
end
