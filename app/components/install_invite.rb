class Components::InstallInvite < Components::Base
  IOS_HELPER = "São dois toques no Safari.".freeze
  INSTALL_LABEL = "Instalar agora".freeze
  INSTALLED_LABEL = "Já instalei".freeze
  STEP_ONE = [ "Toque em ", "Compartilhar", " na barra do Safari" ].freeze
  STEP_TWO = [ "Escolha ", "Adicionar à Tela de Início", "" ].freeze

  OWNER_TITLE = "Tenha sua agenda na tela inicial".freeze
  OWNER_ACTION_HELPER = "Abre como aplicativo, com sua marca e sem navegador.".freeze
  OWNER_DISMISS = "Depois".freeze
  CLIENT_TITLE = "Tenha a %s na tela inicial".freeze
  CLIENT_ACTION_HELPER = "Marque o próximo horário em um toque e veja seus agendamentos.".freeze
  CLIENT_DISMISS = "Agora não".freeze
  CLIENT_SNOOZE_DAYS = 7

  CARD_CLASS = "grid gap-4 rounded-[18px] border border-line bg-surface p-5 shadow-[0_8px_24px_rgba(14,26,36,0.10)]".freeze
  IDENTITY_CLASS = "flex items-center gap-3.5".freeze
  ICON_CLASS = "h-13 w-13 flex-none rounded-[14px]".freeze
  INITIAL_CLASS = "grid place-items-center bg-brand-600 text-[22px] leading-[normal] font-extrabold text-on-brand".freeze
  TEXT_COLUMN_CLASS = "grid flex-grow gap-[3px]".freeze
  TITLE_CLASS = "text-base leading-[normal] font-extrabold tracking-[-0.01em] text-ink".freeze
  HELPER_CLASS = "text-[13px] leading-[normal] text-ink-muted".freeze
  ACTIONS_CLASS = "flex gap-2".freeze
  INSTALL_CLASS = "flex min-h-11 flex-grow items-center justify-center gap-2 rounded-[10px] bg-brand-600 text-sm leading-[normal] font-bold text-on-brand".freeze
  DISMISS_CLASS = "inline-flex min-h-11 flex-none items-center rounded-[10px] border border-line bg-surface px-4 text-sm leading-[normal] font-bold text-ink-muted".freeze
  STEPS_CLASS = "grid gap-2.5".freeze
  STEP_ROW_CLASS = "flex items-center gap-3 rounded-[10px] border border-line bg-surface-2 px-3.5 py-3".freeze
  STEP_NUMBER_CLASS = "grid h-6 w-6 flex-none place-items-center rounded-full bg-brand-600 text-xs leading-[normal] font-extrabold text-on-brand".freeze
  STEP_TEXT_CLASS = "flex-grow text-[13px] leading-[normal] text-ink".freeze
  STEP_ICON_CLASS = "h-5 w-5 flex-none text-ink".freeze
  INSTALL_ICON_CLASS = "h-4.5 w-4.5".freeze
  INSTALLED_CLASS = "inline-flex min-h-11 items-center justify-self-start rounded-[10px] border border-line bg-surface px-4 text-sm leading-[normal] font-bold text-ink-muted".freeze

  def self.for_owner(name:, icon:, initial:)
    new(name: name, icon: icon, initial: initial,
        title: OWNER_TITLE, action_helper: OWNER_ACTION_HELPER, dismiss_label: OWNER_DISMISS, audience: "owner")
  end

  def self.for_client(name:, icon:, initial:, require_visit: false, mark_visit: false, standalone_path: nil)
    new(name: name, icon: icon, initial: initial,
        title: Kernel.format(CLIENT_TITLE, name), action_helper: CLIENT_ACTION_HELPER, dismiss_label: CLIENT_DISMISS,
        audience: "client", snooze_days: CLIENT_SNOOZE_DAYS,
        require_visit: require_visit, mark_visit: mark_visit, standalone_path: standalone_path)
  end

  def initialize(name:, icon:, initial:, title:, action_helper:, dismiss_label:, audience:, snooze_days: 0, require_visit: false, mark_visit: false, standalone_path: nil)
    @name = name
    @icon = icon
    @initial = initial
    @title = title
    @action_helper = action_helper
    @dismiss_label = dismiss_label
    @audience = audience
    @snooze_days = snooze_days
    @require_visit = require_visit
    @mark_visit = mark_visit
    @standalone_path = standalone_path
  end

  def view_template
    div(data: { controller: "pwa-install",
                 pwa_install_audience_value: @audience,
                 pwa_install_snooze_days_value: @snooze_days,
                 pwa_install_require_visit_value: @require_visit,
                 pwa_install_mark_visit_value: @mark_visit,
                 pwa_install_standalone_path_value: @standalone_path }.compact,
        hidden: true) do
      render_action_card
      render_instructions_card
    end
  end

  private

  def render_action_card
    div(class: CARD_CLASS, data: { pwa_install_target: "action" }, hidden: true) do
      render_identity(@action_helper)
      div(class: ACTIONS_CLASS) do
        button(type: "button", class: INSTALL_CLASS, data: { action: "pwa-install#install" }) do
          render_download_icon
          plain INSTALL_LABEL
        end
        button(type: "button", class: DISMISS_CLASS, data: { action: "pwa-install#dismiss" }) { @dismiss_label }
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
      button(type: "button", class: INSTALLED_CLASS, data: { action: "pwa-install#dismiss", pwa_install_forever_param: true }) { INSTALLED_LABEL }
    end
  end

  def render_identity(helper)
    div(class: IDENTITY_CLASS) do
      render_icon
      div(class: TEXT_COLUMN_CLASS) do
        p(class: TITLE_CLASS) { @title }
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
    render Components::Icon.new(:arrow_down_to_line, class: INSTALL_ICON_CLASS)
  end

  def render_share_icon
    render Components::Icon.new(:share, class: STEP_ICON_CLASS)
  end

  def render_plus_square_icon
    render Components::Icon.new(:square_plus, class: STEP_ICON_CLASS)
  end
end
