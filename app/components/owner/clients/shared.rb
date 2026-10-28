module Components::Owner::Clients::Shared
  WEEKDAY_ABBR = Views::Client::Bookings::New::WEEKDAY_ABBR
  MONTH_ABBR = Views::Client::Bookings::New::MONTH_ABBR

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
      render Components::Icon.new(:message_circle, class: icon_class)
    end
  end
end
