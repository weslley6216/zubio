module Components::Owner::Clients::Shared
  WEEKDAY_ABBR = Views::Client::Bookings::New::WEEKDAY_ABBR
  MONTH_ABBR = Views::Client::Bookings::New::MONTH_ABBR

  WHATSAPP_ICON_PATH = "M21 11.5a8.4 8.4 0 0 1-8.5 8.4 8.5 8.5 0 0 1-4-1L4 20l1.1-4.4a8.4 8.4 0 0 1-1.1-4.1A8.4 8.4 0 0 1 12.5 3 8.4 8.4 0 0 1 21 11.5z".freeze
  MOBILE_WHATSAPP_BUTTON_CLASS = "grid h-11 w-11 flex-none place-items-center rounded-[10px] border border-line bg-surface".freeze
  DESKTOP_WHATSAPP_BUTTON_CLASS = "grid h-10 w-10 flex-none place-items-center rounded-[9px] border border-line bg-surface".freeze

  def next_phrase(time)
    "Próxima: #{WEEKDAY_ABBR[time.wday].downcase}, #{time.day} #{MONTH_ABBR[time.month - 1]} · #{time.strftime('%H:%M')}"
  end

  def short_date(time) = "#{time.day} #{MONTH_ABBR[time.month - 1]}"

  def visits_phrase(count) = "#{count} #{count == 1 ? 'visita' : 'visitas'}"

  def sub_phrase(entry)
    return next_phrase(entry.next_visit_at) if entry.next_visit_at
    return "Última visita #{short_date(entry.last_visit_at)} · #{visits_phrase(entry.visit_count)}" if entry.last_visit_at

    "Sem visitas ainda"
  end

  def whatsapp_link(client, size:)
    button_class = size == :mobile ? MOBILE_WHATSAPP_BUTTON_CLASS : DESKTOP_WHATSAPP_BUTTON_CLASS
    icon_class = size == :mobile ? "h-[18px] w-[18px] text-brand-600" : "h-[17px] w-[17px] text-brand-600"

    a(href: client.whatsapp_url, target: "_blank", rel: "noopener", aria_label: "WhatsApp de #{client.name}", class: button_class) do
      svg(viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2", stroke_linecap: "round",
        stroke_linejoin: "round", aria_hidden: "true", class: icon_class) do |icon|
        icon.path(d: WHATSAPP_ICON_PATH)
      end
    end
  end
end
