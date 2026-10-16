class Views::Client::Bookings::Receipt < Views::Base
  SUCCESS_TITLE = "Horário confirmado".freeze
  SUBTITLE = "A %<professional>s já está sabendo, %<client>s.".freeze
  WHEN_LABEL = "Quando".freeze
  SERVICE_LABEL = "Serviço".freeze
  DURATION_LABEL = "Duração".freeze
  PRICE_LABEL = "Valor".freeze
  KEEP_LINK_TITLE = "Guarde este link".freeze
  KEEP_LINK_BODY = "É por ele que você desmarca, se precisar. Ele não chega por mensagem — salve agora.".freeze
  COPY_LABEL = "Copiar link".freeze
  COPIED_LABEL = "Link copiado".freeze
  SAVE_LABEL = "Salvar na tela".freeze
  REBOOK_LABEL = "Marcar outro horário".freeze
  CANCEL_LABEL = "Desmarcar este horário".freeze
  FOOTER_NOTE = "Nada é enviado por e-mail ou WhatsApp nesta versão. Esta tela é o comprovante.".freeze

  PAGE_CLASS = "mx-auto flex min-h-dvh w-full max-w-[430px] flex-col bg-surface-2 leading-[normal] text-ink".freeze
  BAND_CLASS = "flex flex-col items-center gap-3.5 bg-brand-600 px-5 pt-[34px] pb-[44px] text-center text-on-brand".freeze
  BADGE_CLASS = "grid h-16 w-16 place-items-center rounded-full bg-on-brand/20".freeze
  BADGE_ICON_CLASS = "h-[34px] w-[34px]".freeze
  BAND_TEXT_CLASS = "flex flex-col gap-[5px]".freeze
  TITLE_CLASS = "text-[22px] font-extrabold tracking-[-0.02em]".freeze
  SUBTITLE_CLASS = "text-[14px] text-on-brand/[0.92]".freeze
  CONTENT_CLASS = "-mt-6 flex flex-col gap-4 px-5 pb-6".freeze
  DETAIL_CARD_CLASS = "flex flex-col gap-3.5 rounded-2xl border border-line bg-surface p-5 shadow-[0_4px_14px_rgba(14,26,36,0.07)]".freeze
  DETAIL_DIVIDER_CLASS = "h-px bg-line".freeze
  DETAIL_ROW_CLASS = "flex items-baseline gap-3".freeze
  DETAIL_LABEL_CLASS = "w-[78px] flex-none text-[12px] font-bold uppercase tracking-[0.04em] text-ink-muted".freeze
  DETAIL_VALUE_CLASS = "text-[15px] font-bold text-ink".freeze
  LINK_CARD_CLASS = "flex flex-col gap-3 rounded-[14px] border-2 border-brand-600 bg-surface p-4".freeze
  LINK_HEADER_CLASS = "flex items-center gap-2".freeze
  LINK_ICON_CLASS = "h-[17px] w-[17px] text-brand-600".freeze
  LINK_TITLE_CLASS = "text-[14px] font-extrabold".freeze
  LINK_BODY_CLASS = "text-[13px] leading-[1.55] text-ink-muted".freeze
  LINK_BOX_CLASS = "break-all rounded-lg border border-line bg-surface-2 px-3 py-2.5 text-[12px] font-bold text-ink-muted".freeze
  LINK_ACTIONS_CLASS = "flex gap-2".freeze
  COPY_BUTTON_CLASS = "flex min-h-11 flex-grow items-center justify-center gap-2 rounded-[10px] bg-brand-600 text-[14px] font-bold text-on-brand".freeze
  SAVE_BUTTON_CLASS = "flex min-h-11 flex-grow items-center justify-center gap-2 rounded-[10px] border border-line-strong bg-surface text-[14px] font-bold text-ink".freeze
  BUTTON_ICON_CLASS = "h-[17px] w-[17px]".freeze
  ACTIONS_CLASS = "flex flex-col gap-2.5".freeze
  REBOOK_LINK_CLASS = "grid min-h-[46px] place-items-center rounded-[10px] border border-line bg-surface text-[14px] font-bold text-ink-muted".freeze
  CANCEL_LINK_CLASS = "grid min-h-[46px] place-items-center rounded-[10px] border border-danger bg-surface text-[14px] font-bold text-danger".freeze
  FOOTER_CLASS = "text-center text-[12px] leading-[1.6] text-ink-subtle".freeze

  def initialize(tenant:, branding:, service:, professional:, appointment:, client_name:)
    @tenant = tenant
    @branding = branding
    @service = service
    @professional = professional
    @appointment = appointment
    @client_name = client_name
  end

  def view_template
    render Views::Layouts::Application.new(title: "#{SUCCESS_TITLE} · #{@tenant.name}", branding: @branding) do
      div(class: PAGE_CLASS, data: { receipt: true }) do
        render_band
        div(class: CONTENT_CLASS) do
          render_detail_card
          render_link_card
          render_actions
          p(class: FOOTER_CLASS) { FOOTER_NOTE }
        end
      end
    end
  end

  private

  def render_band
    div(class: BAND_CLASS) do
      div(class: BADGE_CLASS) { render_check_icon }
      div(class: BAND_TEXT_CLASS) do
        span(class: TITLE_CLASS) { SUCCESS_TITLE }
        span(class: SUBTITLE_CLASS) { subtitle }
      end
    end
  end

  def render_check_icon
    svg(viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2.6", stroke_linecap: "round",
      stroke_linejoin: "round", aria_hidden: "true", class: BADGE_ICON_CLASS) do |icon|
      icon.path(d: "M20 6 9 17l-5-5")
    end
  end

  def subtitle
    Kernel.format(SUBTITLE, professional: @professional.display_name.split.first, client: @client_name.split.first)
  end

  def render_detail_card
    div(class: DETAIL_CARD_CLASS, data: { when: true }) do
      render_detail_row(WHEN_LABEL, when_label)
      render_divider
      render_detail_row(SERVICE_LABEL, @service.name)
      render_divider
      render_detail_row(DURATION_LABEL, duration_label)
      render_divider
      render_detail_row(PRICE_LABEL, price_label)
    end
  end

  def render_detail_row(label, value)
    div(class: DETAIL_ROW_CLASS) do
      span(class: DETAIL_LABEL_CLASS) { label }
      span(class: "#{DETAIL_VALUE_CLASS} tabular-nums") { value }
    end
  end

  def render_divider = div(class: DETAIL_DIVIDER_CLASS)

  def when_label
    date = @appointment.starts_at.to_date
    "#{Views::Client::Bookings::New::WEEKDAY_ABBR[date.wday].capitalize}, #{date.day} #{Views::Client::Bookings::New::MONTH_ABBR[date.month - 1]} · #{@appointment.starts_at.strftime("%H:%M")}"
  end

  def duration_label
    "#{::Service::Duration.minutes_label(@service.duration_minutes)} · termina #{@appointment.ends_at.strftime("%H:%M")}"
  end

  def price_label = ::Service::Price.label(@service.public_price_cents)

  def render_link_card
    div(class: LINK_CARD_CLASS) do
      div(class: LINK_HEADER_CLASS) do
        render_link_icon
        span(class: LINK_TITLE_CLASS) { KEEP_LINK_TITLE }
      end
      p(class: LINK_BODY_CLASS) { KEEP_LINK_BODY }
      div(class: LINK_BOX_CLASS) { cancel_display }
      div(class: LINK_ACTIONS_CLASS) do
        render_copy_button
        render_save_button
      end
    end
  end

  def render_link_icon
    svg(viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2", stroke_linecap: "round",
      stroke_linejoin: "round", aria_hidden: "true", class: LINK_ICON_CLASS) do |icon|
      icon.path(d: "M10 13a5 5 0 0 0 7 0l3-3a5 5 0 0 0-7-7l-1 1")
      icon.path(d: "M14 11a5 5 0 0 0-7 0l-3 3a5 5 0 0 0 7 7l1-1")
    end
  end

  def cancel_path = "/a/#{@appointment.cancel_token}"

  def cancel_display = "#{@tenant.canonical_host}#{cancel_path}"

  def cancel_url = "https://#{cancel_display}"

  def render_copy_button
    button(type: "button", class: COPY_BUTTON_CLASS,
      data: { controller: "clipboard", clipboard_text_value: cancel_url, clipboard_copied_value: COPIED_LABEL }) do
      render_copy_icon
      span(data: { clipboard_target: "label", action: "clipboard#copy" }) { COPY_LABEL }
    end
  end

  def render_copy_icon
    svg(viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2", stroke_linecap: "round",
      stroke_linejoin: "round", aria_hidden: "true", class: BUTTON_ICON_CLASS) do |icon|
      icon.rect(x: "9", y: "9", width: "11", height: "11", rx: "2")
      icon.path(d: "M15 5H6a2 2 0 0 0-2 2v9")
    end
  end

  def render_save_button
    button(type: "button", class: SAVE_BUTTON_CLASS, data: { controller: "print", action: "print#run" }) do
      render_save_icon
      span { SAVE_LABEL }
    end
  end

  def render_save_icon
    svg(viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2", stroke_linecap: "round",
      stroke_linejoin: "round", aria_hidden: "true", class: BUTTON_ICON_CLASS) do |icon|
      icon.path(d: "M12 3v12")
      icon.path(d: "m7 10 5 5 5-5")
      icon.path(d: "M5 21h14")
    end
  end

  def render_actions
    div(class: ACTIONS_CLASS) do
      a(href: new_client_service_booking_path(@service), class: REBOOK_LINK_CLASS) { REBOOK_LABEL }
      a(href: cancel_path, class: CANCEL_LINK_CLASS, data: { cancel_link: true }) { CANCEL_LABEL }
    end
  end
end
