class Views::Mailers::Client::BookingReceipt < Views::Base
  SUCCESS_TITLE = "Horário confirmado".freeze
  SUBTITLE = "A %<professional>s já está sabendo, %<client>s.".freeze
  WHEN_LABEL = "Quando".freeze
  SERVICE_LABEL = "Serviço".freeze
  DURATION_LABEL = "Duração".freeze
  PRICE_LABEL = "Valor".freeze
  BUTTON_LABEL = "Ver ou desmarcar".freeze
  SIGNATURE_NOTE = "Agendado pelo Zubio".freeze
  FONT_URL = "https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;600;700;800&display=swap".freeze

  TABLE_ATTRS = { role: "presentation", cellpadding: 0, cellspacing: 0 }.freeze
  BODY_STYLE = "margin:0;background:#eef2f5;font-family:'Plus Jakarta Sans','Segoe UI',system-ui,sans-serif;-webkit-font-smoothing:antialiased;".freeze
  OUTER_CELL_STYLE = "padding:24px 16px;".freeze
  CONTENT_TABLE_STYLE = "max-width:600px;width:100%;background:#f8fafb;border-radius:16px;overflow:hidden;color:#0e1a24;".freeze
  CONTENT_CELL_STYLE = "padding:0 20px 24px;".freeze
  CARD_TABLE_STYLE = "margin-top:-24px;background:#ffffff;border:1px solid #e4eaef;border-radius:16px;box-shadow:0 4px 14px rgba(14,26,36,0.07);".freeze
  CARD_CELL_STYLE = "padding:20px;".freeze
  ROW_LABEL_STYLE = "font-size:12px;font-weight:700;letter-spacing:0.04em;text-transform:uppercase;color:#68798a;width:78px;vertical-align:baseline;".freeze
  ROW_VALUE_STYLE = "font-size:15px;font-weight:700;color:#0e1a24;vertical-align:baseline;font-variant-numeric:tabular-nums;".freeze
  ROW_DIVIDER_STYLE = "height:1px;background:#e4eaef;margin:14px 0;".freeze
  BUTTON_TABLE_STYLE = "margin-top:16px;".freeze
  SIGNATURE_TABLE_STYLE = "margin-top:28px;".freeze
  SIGNATURE_CELL_STYLE = "text-align:center;".freeze
  SIGNATURE_NAME_STYLE = "font-size:14px;font-weight:800;color:#0e1a24;".freeze
  SIGNATURE_LINK_WRAP_STYLE = "margin-top:2px;".freeze
  SIGNATURE_NOTE_STYLE = "font-size:11px;color:#94a6b4;margin-top:12px;".freeze
  TITLE_STYLE = "font-size:22px;font-weight:800;letter-spacing:-0.02em;".freeze
  SUBTITLE_STYLE = "font-size:14px;opacity:0.92;margin-top:5px;".freeze

  def initialize(tenant:, branding:, appointment:)
    @tenant = tenant
    @branding = branding
    @appointment = appointment
  end

  def view_template
    doctype
    html do
      head do
        meta(charset: "utf-8")
        meta(name: "viewport", content: "width=device-width,initial-scale=1")
        link(rel: "stylesheet", href: FONT_URL)
      end
      body(style: BODY_STYLE) { render_outer_table }
    end
  end

  private

  def labels = @labels ||= Appointment::Labels.new(@appointment)

  def hex = @branding.color_scale.hex

  def foreground = @branding.color_scale.foreground

  def render_outer_table
    table(**TABLE_ATTRS, width: "100%") do
      tr { td(align: "center", style: OUTER_CELL_STYLE) { render_content_table } }
    end
  end

  def render_content_table
    table(**TABLE_ATTRS, width: "600", style: CONTENT_TABLE_STYLE) do
      tr { render_band }
      tr { td(style: CONTENT_CELL_STYLE) { render_content } }
    end
  end

  def render_band
    td(style: "background:#{hex};color:#{foreground};padding:34px 20px 44px;text-align:center;", data: { band: true }) do
      render_band_chip
      div(style: TITLE_STYLE) { SUCCESS_TITLE }
      div(style: SUBTITLE_STYLE) { subtitle }
    end
  end

  def subtitle
    Kernel.format(SUBTITLE, professional: @appointment.professional.display_name.split.first, client: @appointment.client.name.split.first)
  end

  def render_band_chip
    logo = @branding.invite_icon
    style = "width:56px;height:56px;border-radius:14px;background:#{foreground};margin:0 auto 14px;text-align:center;"
    style += "padding:6px;box-sizing:border-box;" if logo

    div(style: style) do
      if logo
        img(src: rails_storage_proxy_url(logo, host: @tenant.canonical_host, protocol: "https"), alt: @tenant.name,
          width: 44, height: 44, style: "display:block;width:44px;height:44px;border-radius:9px;", data: { brand_logo: true })
      else
        span(style: "color:#{hex};font-size:26px;font-weight:800;line-height:56px;text-align:center;", data: { brand_initial: true }) { @tenant.initial }
      end
    end
  end

  def render_content
    render_detail_card
    render_button
    render_signature
  end

  def render_detail_card
    table(**TABLE_ATTRS, width: "100%", style: CARD_TABLE_STYLE) do
      tr { td(style: CARD_CELL_STYLE) { render_detail_rows } }
    end
  end

  def render_detail_rows
    render_detail_row(WHEN_LABEL, labels.when_label)
    render_divider
    render_detail_row(SERVICE_LABEL, @appointment.service.name)
    render_divider
    render_detail_row(DURATION_LABEL, labels.duration_label)
    render_divider
    render_detail_row(PRICE_LABEL, labels.price_label)
  end

  def render_detail_row(caption, text)
    table(**TABLE_ATTRS, width: "100%") do
      tr do
        td(style: ROW_LABEL_STYLE) { caption }
        td(style: ROW_VALUE_STYLE) { text }
      end
    end
  end

  def render_divider = div(style: ROW_DIVIDER_STYLE)

  def render_button
    table(**TABLE_ATTRS, width: "100%", style: BUTTON_TABLE_STYLE) do
      tr do
        td(align: "center", style: "background:#{hex};border:1px solid #{hex};border-radius:10px;") do
          a(href: client_appointment_url(host: @tenant.canonical_host, token: @appointment.cancel_token),
            style: "display:block;padding:13px 16px;color:#{foreground};font-size:15px;font-weight:700;text-decoration:none;",
            data: { receipt_link: true }) { BUTTON_LABEL }
        end
      end
    end
  end

  def render_signature
    table(**TABLE_ATTRS, width: "100%", style: SIGNATURE_TABLE_STYLE) do
      tr { td(align: "center", style: SIGNATURE_CELL_STYLE) { render_signature_content } }
    end
  end

  def render_signature_content
    render_signature_chip
    div(style: SIGNATURE_NAME_STYLE) { @tenant.name }
    div(style: SIGNATURE_LINK_WRAP_STYLE) do
      a(href: root_url(host: @tenant.canonical_host), style: "font-size:13px;color:#{@branding.light_ink};text-decoration:none;",
        data: { signature_link: true }) { @tenant.canonical_host }
    end
    div(style: SIGNATURE_NOTE_STYLE) { SIGNATURE_NOTE }
  end

  def render_signature_chip
    logo = @branding.invite_icon
    style = "display:inline-block;width:40px;height:40px;border-radius:10px;margin-bottom:8px;text-align:center;"
    style += logo ? "background:#ffffff;border:1px solid #e4eaef;padding:4px;box-sizing:border-box;" : "background:#{hex};"

    div(style: style) do
      if logo
        img(src: rails_storage_proxy_url(logo, host: @tenant.canonical_host, protocol: "https"), alt: @tenant.name,
          width: 30, height: 30, style: "display:block;width:30px;height:30px;border-radius:7px;", data: { brand_logo: true })
      else
        span(style: "color:#{foreground};font-size:18px;font-weight:800;line-height:40px;text-align:center;", data: { brand_initial: true }) { @tenant.initial }
      end
    end
  end
end
