class Views::Client::AccountPhones::New < Views::Base
  BACK_LABEL = "Voltar".freeze
  TITLE = "Qual é o seu WhatsApp?".freeze
  SUBTITLE = "É por ele que a %s fala com você sobre seus horários. Pedimos só desta vez.".freeze
  NAME_LABEL = "Nome".freeze
  PHONE_LABEL = "WhatsApp".freeze
  PHONE_PLACEHOLDER = "(11) 90000-0000".freeze
  CONTINUE_LABEL = "Continuar".freeze

  PAGE_CLASS = Views::Client::Frame::PAGE
  HEADER_CLASS = Views::Client::Frame::HEADER
  BACK_CLASS = Views::Client::Frame::BACK
  BACK_ICON_CLASS = Views::Client::Frame::BACK_ICON
  NAME_CLASS = Views::Client::Frame::NAME
  MAIN_CLASS = "flex grow flex-col gap-5 px-5 py-6".freeze
  HEADING_BLOCK_CLASS = "flex flex-col gap-1.5".freeze
  HEADING_CLASS = "text-[22px] leading-[normal] font-extrabold tracking-[-0.02em]".freeze
  SUBTITLE_CLASS = "text-[14px] leading-[1.5] text-pretty text-(--theme-on-bg-muted)".freeze
  CARD_CLASS = "flex flex-col gap-3.5 rounded-2xl bg-(--theme-card) p-5 text-(--theme-on-card)".freeze
  NAME_ROW_CLASS = "flex items-baseline justify-between gap-4".freeze
  NAME_ROW_LABEL_CLASS = "flex-none text-[13px] text-(--theme-on-card-muted)".freeze
  NAME_ROW_VALUE_CLASS = "text-right text-[14px] font-bold".freeze
  DIVIDER_CLASS = "h-px bg-(--theme-card-line)".freeze
  FIELD_WRAPPER_CLASS = "flex flex-col gap-1.5".freeze
  FIELD_LABEL_CLASS = "text-[11px] font-bold uppercase tracking-[0.06em] text-(--theme-on-card-muted)".freeze
  FIELD_CLASS = "flex min-h-[48px] items-center rounded-lg border-2 border-(--theme-field-line) px-3 text-[15px] font-bold tabular-nums".freeze
  SUBMIT_CLASS = "flex min-h-[50px] w-full items-center justify-center gap-2 rounded-xl bg-(--theme-accent) text-[15px] font-extrabold text-(--theme-on-accent)".freeze

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
    render Components::Icon.new(:chevron_left, stroke_width: "2.5", class: BACK_ICON_CLASS)
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
