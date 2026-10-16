class Views::Owner::Sessions::New < Views::Base
  TITLE = "Entrar no painel".freeze
  FOOTER_LEAD = "Não é este estabelecimento? Entre por ".freeze
  FOOTER_LINK = "zubio.com.br".freeze
  FOOTER_TAIL = " e receba no e-mail o link de cada um.".freeze
  FORGOT_LABEL = "Esqueci minha senha".freeze

  FRAME_CLASS = "mx-auto flex min-h-dvh w-full max-w-md flex-col bg-canvas".freeze
  CONTENT_CLASS = "flex grow flex-col gap-[22px] px-6 pt-14 pb-6".freeze
  BRAND_COLUMN_CLASS = "flex flex-col items-center gap-[14px] text-center".freeze
  HEADING_BLOCK_CLASS = "flex flex-col gap-1".freeze
  HEADING_CLASS = "text-[24px] leading-[normal] font-extrabold tracking-[-0.02em] text-ink".freeze
  SUBTITLE_CLASS = "text-[14px] leading-[normal] text-ink-muted".freeze
  CARD_CLASS = "flex flex-col gap-[14px] rounded-2xl border border-line bg-surface p-5".freeze
  FIELD_CLASS = "flex flex-col gap-1.5".freeze
  LABEL_CLASS = "text-[11px] leading-[normal] font-bold uppercase tracking-[0.06em] text-ink-muted".freeze
  EMAIL_CONTROL_CLASS = "min-h-12 w-full rounded-[10px] border border-line-strong bg-surface px-3.5 text-[15px] leading-[normal] font-bold tabular-nums text-ink".freeze
  PASSWORD_BOX_CLASS = "flex min-h-12 items-center gap-2 rounded-[10px] border-2 border-brand-600 bg-surface pl-3.5 pr-1.5".freeze
  PASSWORD_CONTROL_CLASS = "w-full border-0 bg-transparent p-0 text-[18px] leading-[normal] tracking-[0.2em] text-ink focus:outline-none".freeze
  TOGGLE_CLASS = "min-h-9 flex-none cursor-pointer border-0 bg-transparent px-2.5 text-[13px] leading-[normal] font-bold text-brand-600".freeze
  SUBMIT_CLASS = "flex min-h-[50px] w-full items-center justify-center gap-2 rounded-xl bg-brand-600 text-[15px] leading-[normal] font-extrabold text-on-brand".freeze
  FORGOT_CLASS = "self-center p-1.5 text-[14px] leading-[normal] font-bold text-brand-600".freeze
  FOOTER_CLASS = "px-6 pb-7 text-center text-[13px] leading-[1.55] text-ink-muted".freeze
  FOOTER_LINK_CLASS = "font-bold text-ink".freeze

  def initialize(tenant:, branding:, email: nil)
    @tenant = tenant
    @branding = branding
    @email = email
  end

  def view_template
    render Views::Layouts::Application.new(title: "Entrar · Zubio", branding: @branding) do
      div(class: FRAME_CLASS) do
        div(class: CONTENT_CLASS) do
          render_brand_column
          render_card
        end
        render_footer
      end
    end
  end

  private

  def render_brand_column
    div(class: BRAND_COLUMN_CLASS) do
      render Components::Owner::Emblem.new(tenant: @tenant, branding: @branding, size: :login)
      div(class: HEADING_BLOCK_CLASS) do
        h1(class: HEADING_CLASS) { TITLE }
        span(class: SUBTITLE_CLASS) { @tenant.name }
      end
    end
  end

  def render_card
    div(class: CARD_CLASS, data: { surface: true }) do
      form_with(url: owner_session_path, method: :post, class: "contents") do |form|
        render_email_field(form)
        render_password_field(form)
        form.button "Entrar", class: SUBMIT_CLASS
      end
      a(href: new_owner_password_reset_path, class: FORGOT_CLASS) { FORGOT_LABEL }
    end
  end

  def render_email_field(form)
    div(class: FIELD_CLASS) do
      form.label :email, "E-mail", class: LABEL_CLASS
      form.email_field :email, value: @email, required: true, class: EMAIL_CONTROL_CLASS
    end
  end

  def render_password_field(form)
    div(class: FIELD_CLASS) do
      form.label :password, "Senha", class: LABEL_CLASS
      div(class: PASSWORD_BOX_CLASS, data: { controller: "password-visibility" }) do
        form.password_field :password, required: true, class: PASSWORD_CONTROL_CLASS,
          data: { "password-visibility-target": "input" }
        button(type: "button", class: TOGGLE_CLASS, hidden: true,
          data: { "password-visibility-target": "toggle", action: "password-visibility#toggle" }) do
          span(data: { "password-visibility-target": "hidden" }) { "Mostrar" }
          span(data: { "password-visibility-target": "shown" }, hidden: true) { "Ocultar" }
        end
      end
    end
  end

  def render_footer
    div(class: FOOTER_CLASS) do
      plain FOOTER_LEAD
      a(href: new_login_link_url(host: Tenant::PLATFORM_HOST), class: FOOTER_LINK_CLASS) { FOOTER_LINK }
      plain FOOTER_TAIL
    end
  end
end
