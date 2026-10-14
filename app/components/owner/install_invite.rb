class Components::Owner::InstallInvite < Components::Base
  TITLE = "Tenha sua agenda na tela inicial".freeze
  ACTION_HELPER = "Abre como aplicativo, com sua marca e sem navegador.".freeze
  IOS_HELPER = "São dois toques no Safari.".freeze
  INSTALL_LABEL = "Instalar agora".freeze
  DISMISS_LABEL = "Depois".freeze
  INSTALLED_LABEL = "Já instalei".freeze
  STEP_ONE = [ "Toque em ", "Compartilhar", " na barra do Safari" ].freeze
  STEP_TWO = [ "Escolha ", "Adicionar à Tela de Início", "" ].freeze

  CARD_CLASS = "grid gap-4 rounded-[18px] border border-line bg-surface p-5 shadow-[0_8px_24px_rgba(14,26,36,0.10)]".freeze
  IDENTITY_CLASS = "flex items-center gap-3.5".freeze
  ICON_CLASS = "h-13 w-13 flex-none rounded-[14px]".freeze
  INITIAL_CLASS = "grid place-items-center bg-brand-600 text-[22px] font-extrabold text-on-brand".freeze
  TEXT_COLUMN_CLASS = "grid flex-grow gap-[3px]".freeze
  TITLE_CLASS = "text-base font-extrabold tracking-tight text-ink".freeze
  HELPER_CLASS = "text-[13px] text-ink-muted".freeze
  ACTIONS_CLASS = "flex gap-2".freeze
  INSTALL_CLASS = "flex min-h-11 flex-grow items-center justify-center gap-2 rounded-[10px] bg-brand-600 text-sm font-bold text-on-brand".freeze
  DISMISS_CLASS = "inline-flex min-h-11 flex-none items-center rounded-[10px] border border-line bg-surface px-4 text-sm font-bold text-ink-muted".freeze
  STEPS_CLASS = "grid gap-2.5".freeze
  STEP_ROW_CLASS = "flex items-center gap-3 rounded-[10px] border border-line bg-surface-2 px-3.5 py-3".freeze
  STEP_NUMBER_CLASS = "grid h-6 w-6 flex-none place-items-center rounded-full bg-brand-600 text-xs font-extrabold text-on-brand".freeze
  STEP_TEXT_CLASS = "flex-grow text-[13px] text-ink".freeze
  STEP_ICON_CLASS = "h-5 w-5 flex-none text-ink".freeze
  INSTALL_ICON_CLASS = "h-4.5 w-4.5".freeze
  INSTALLED_CLASS = "inline-flex min-h-11 items-center justify-self-start rounded-[10px] border border-line bg-surface px-4 text-sm font-bold text-ink-muted".freeze

  def initialize(name:, icon:, initial:)
    @name = name
    @icon = icon
    @initial = initial
  end

  def view_template
    div(data: { controller: "pwa-install" }, hidden: true) do
      render_action_card
      render_instructions_card
    end
  end

  private

  def render_action_card
    div(class: CARD_CLASS, data: { pwa_install_target: "action" }, hidden: true) do
      render_identity(ACTION_HELPER)
      div(class: ACTIONS_CLASS) do
        button(type: "button", class: INSTALL_CLASS, data: { action: "pwa-install#install" }) do
          render_download_icon
          plain INSTALL_LABEL
        end
        button(type: "button", class: DISMISS_CLASS, data: { action: "pwa-install#dismiss" }) { DISMISS_LABEL }
      end
    end
  end

  def render_instructions_card
    div(class: CARD_CLASS, data: { pwa_install_target: "instructions" }, hidden: true) do
      render_identity(IOS_HELPER)
      div(class: STEPS_CLASS) do
        render_step(1, STEP_ONE) { render_share_icon }
        render_step(2, STEP_TWO) { render_plus_square_icon }
      end
      button(type: "button", class: INSTALLED_CLASS, data: { action: "pwa-install#dismiss" }) { INSTALLED_LABEL }
    end
  end

  def render_identity(helper)
    div(class: IDENTITY_CLASS) do
      render_icon
      div(class: TEXT_COLUMN_CLASS) do
        p(class: TITLE_CLASS) { TITLE }
        p(class: HELPER_CLASS) { helper }
      end
    end
  end

  def render_icon
    if @icon
      img(src: rails_storage_proxy_path(@icon), alt: @name, class: "#{ICON_CLASS} object-cover")
    else
      span(class: "#{ICON_CLASS} #{INITIAL_CLASS}", data: { brand_initial: true }) { @initial }
    end
  end

  def render_step(number, parts)
    prefix, highlight, suffix = parts
    div(class: STEP_ROW_CLASS) do
      span(class: STEP_NUMBER_CLASS) { number.to_s }
      span(class: STEP_TEXT_CLASS) do
        plain prefix
        strong { highlight }
        plain suffix
      end
      yield
    end
  end

  def render_download_icon
    svg(viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2", stroke_linecap: "round",
      stroke_linejoin: "round", aria_hidden: "true", class: INSTALL_ICON_CLASS) do |icon|
      icon.path(d: "M12 3v12")
      icon.path(d: "m7 10 5 5 5-5")
      icon.path(d: "M5 21h14")
    end
  end

  def render_share_icon
    svg(viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2", stroke_linecap: "round",
      stroke_linejoin: "round", aria_hidden: "true", class: STEP_ICON_CLASS) do |icon|
      icon.path(d: "M12 16V4")
      icon.path(d: "m8 8 4-4 4 4")
      icon.path(d: "M5 12v7a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1v-7")
    end
  end

  def render_plus_square_icon
    svg(viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2", stroke_linecap: "round",
      stroke_linejoin: "round", aria_hidden: "true", class: STEP_ICON_CLASS) do |icon|
      icon.rect(x: "4", y: "4", width: "16", height: "16", rx: "3")
      icon.path(d: "M12 9v6M9 12h6")
    end
  end
end
