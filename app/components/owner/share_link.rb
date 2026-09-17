class Components::Owner::ShareLink < Components::Base
  COPY_LABEL = "Copiar link".freeze
  WHATSAPP_LABEL = "Enviar no WhatsApp".freeze

  CARD_CLASS = "grid gap-3 rounded-xl border border-line bg-surface-2 p-4".freeze
  ADDRESS_CLASS = "truncate text-sm font-bold text-ink".freeze
  ACTIONS_CLASS = "grid grid-cols-2 gap-2".freeze
  COPY_CLASS = "h-11 rounded-lg border border-line-strong text-sm font-bold text-ink".freeze
  WHATSAPP_CLASS = "grid h-11 place-items-center rounded-lg bg-brand-600 text-sm font-bold text-on-brand".freeze

  def initialize(host:)
    @host = host
  end

  def view_template
    div(class: CARD_CLASS, data: { controller: "clipboard" }) do
      span(class: ADDRESS_CLASS, data: { "clipboard-target": "source" }) { address }
      div(class: ACTIONS_CLASS) do
        button(type: "button", class: COPY_CLASS, data: { action: "clipboard#copy" }) { COPY_LABEL }
        a(href: whatsapp_url, class: WHATSAPP_CLASS, target: "_blank", rel: "noopener") { WHATSAPP_LABEL }
      end
    end
  end

  private

  def address = "https://#{@host}"

  def whatsapp_url = "https://wa.me/?text=#{CGI.escape(address)}"
end
