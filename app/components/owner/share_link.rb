class Components::Owner::ShareLink < Components::Base
  COPY_LABEL = "Copiar".freeze
  COPIED_LABEL = "Copiado!".freeze
  WHATSAPP_LABEL = "Enviar no WhatsApp".freeze

  CARD_CLASS = "grid gap-3 rounded-2xl border border-line bg-surface p-4.5 shadow-[0_4px_14px_rgba(14,26,36,0.07)]".freeze
  LABEL_ROW_CLASS = "flex items-center gap-1.5 text-[11px] font-semibold uppercase tracking-wide text-ink-subtle".freeze
  LABEL_ICON_CLASS = "h-3.5 w-3.5".freeze
  ADDRESS_CLASS = "break-all rounded-[10px] border border-line bg-surface-2 px-3.5 py-3 text-sm font-bold text-ink".freeze
  HELPER_CLASS = "text-sm leading-relaxed text-ink-muted".freeze
  ACTIONS_CLASS = "flex gap-2".freeze
  WHATSAPP_CLASS = "flex min-h-12 flex-grow items-center justify-center gap-2 rounded-[10px] bg-brand-600 text-[15px] font-bold text-on-brand".freeze
  COPY_CLASS = "inline-flex min-h-12 items-center justify-center gap-2 rounded-[10px] border border-line-strong bg-surface px-4 text-[15px] font-bold text-ink".freeze
  ICON_CLASS = "h-4.5 w-4.5".freeze

  def initialize(host:, name:, label: nil, helper: nil)
    @host = host
    @name = name
    @label = label
    @helper = helper
  end

  def view_template
    div(class: CARD_CLASS, data: {
      controller: "clipboard",
      clipboard_text_value: address,
      clipboard_copied_value: COPIED_LABEL
    }) do
      render_label if @label
      span(class: ADDRESS_CLASS, data: { share_address: true }) { @host }
      render_helper if @helper
      div(class: ACTIONS_CLASS, data: { share_actions: true }) do
        a(href: whatsapp_url, class: WHATSAPP_CLASS, target: "_blank", rel: "noopener") do
          render_whatsapp_icon
          plain WHATSAPP_LABEL
        end
        button(type: "button", class: COPY_CLASS, data: { action: "clipboard#copy" }) do
          render_copy_icon
          span(data: { clipboard_target: "label" }) { COPY_LABEL }
        end
      end
    end
  end

  private

  def render_label
    div(class: LABEL_ROW_CLASS) do
      render_link_icon
      span { @label }
    end
  end

  def render_helper
    p(class: HELPER_CLASS) { @helper }
  end

  def render_link_icon
    render Components::Icon.new(:link, class: LABEL_ICON_CLASS)
  end

  def render_whatsapp_icon
    render Components::Icon.new(:message_circle, class: ICON_CLASS)
  end

  def render_copy_icon
    render Components::Icon.new(:copy, class: ICON_CLASS)
  end

  def address = "https://#{@host}"

  def message = "Oi! Agende seu horário na #{@name}: #{address}"

  def whatsapp_url = "https://wa.me/?text=#{CGI.escape(message)}"
end
