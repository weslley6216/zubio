class Components::Owner::ShareLink < Components::Base
  COPY_LABEL = "Copiar".freeze
  WHATSAPP_LABEL = "Enviar no WhatsApp".freeze

  CARD_CLASS = "grid gap-3 rounded-2xl border border-line bg-surface p-4.5 shadow-[0_4px_14px_rgba(14,26,36,0.07)]".freeze
  ADDRESS_CLASS = "break-all rounded-[10px] border border-line bg-surface-2 px-3.5 py-3 text-sm font-bold text-ink".freeze
  ACTIONS_CLASS = "flex gap-2".freeze
  WHATSAPP_CLASS = "flex min-h-12 flex-grow items-center justify-center gap-2 rounded-[10px] bg-brand-600 text-[15px] font-bold text-on-brand".freeze
  COPY_CLASS = "min-h-12 rounded-[10px] border border-line-strong bg-surface px-4 text-[15px] font-bold text-ink".freeze
  ICON_CLASS = "h-4.5 w-4.5".freeze

  def initialize(host:)
    @host = host
  end

  def view_template
    div(class: CARD_CLASS, data: { controller: "clipboard" }) do
      span(class: ADDRESS_CLASS, data: { "clipboard-target": "source" }) { address }
      div(class: ACTIONS_CLASS, data: { share_actions: true }) do
        a(href: whatsapp_url, class: WHATSAPP_CLASS, target: "_blank", rel: "noopener") do
          render_whatsapp_icon
          plain WHATSAPP_LABEL
        end
        button(type: "button", class: COPY_CLASS, data: { action: "clipboard#copy" }) { COPY_LABEL }
      end
    end
  end

  private

  def render_whatsapp_icon
    svg(viewBox: "0 0 24 24", fill: "currentColor", aria_hidden: "true", class: ICON_CLASS) do |icon|
      icon.path(d: "M21 11.5a8.4 8.4 0 0 1-8.5 8.4 8.5 8.5 0 0 1-4-1L4 20l1.1-4.4a8.4 8.4 0 0 1-1.1-4.1A8.4 8.4 0 0 1 12.5 3 8.4 8.4 0 0 1 21 11.5z")
    end
  end

  def address = "https://#{@host}"

  def whatsapp_url = "https://wa.me/?text=#{CGI.escape(address)}"
end
