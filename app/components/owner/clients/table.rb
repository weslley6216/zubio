class Components::Owner::Clients::Table < Components::Base
  include Components::Owner::Clients::Shared

  COLUMNS_CLASS = "grid grid-cols-[minmax(0,1.4fr)_170px_minmax(0,1fr)_90px_56px] items-center gap-4 px-5 py-3 leading-[normal]".freeze
  HEADER_LABEL_CLASS = "text-[11px] font-bold uppercase tracking-[0.08em] text-ink-muted".freeze
  AVATAR_CLASS = "grid h-[38px] w-[38px] flex-none place-items-center rounded-full bg-brand-soft text-[13px] leading-[normal] font-extrabold text-brand-soft-ink".freeze
  NAME_CLASS = "text-[15px] font-bold text-ink".freeze
  PHONE_CLASS = "text-[14px] text-ink-muted tabular-nums".freeze
  VISITS_CLASS = "text-[14px] font-bold tabular-nums".freeze
  NEXT_VISIT_CLASS = "text-[14px] font-bold text-brand-soft-ink tabular-nums".freeze
  LAST_VISIT_CLASS = "text-[14px] text-ink-muted tabular-nums".freeze

  def initialize(entries:)
    @entries = entries
  end

  def view_template
    div(class: "hidden overflow-hidden rounded-2xl border border-line bg-surface sm:block") do
      render_header
      @entries.each_with_index { |entry, index| render_row(entry, last: index == @entries.size - 1) }
    end
  end

  private

  def render_header
    div(class: "#{COLUMNS_CLASS} border-b border-line") do
      span(class: HEADER_LABEL_CLASS) { "Cliente" }
      span(class: HEADER_LABEL_CLASS) { "Celular" }
      span(class: HEADER_LABEL_CLASS) { "Visita" }
      span(class: HEADER_LABEL_CLASS) { "Visitas" }
      span
    end
  end

  def render_row(entry, last:)
    div(class: [ COLUMNS_CLASS, ("border-b border-line" unless last) ]) do
      render_client_cell(entry.client)
      span(class: PHONE_CLASS) { entry.client.phone_display }
      render_visit_cell(entry)
      span(class: VISITS_CLASS) { entry.visit_count.to_s }
      div(class: "flex justify-end") { whatsapp_link(entry.client, size: :desktop) }
    end
  end

  def render_client_cell(client)
    div(class: "flex min-w-0 items-center gap-3") do
      div(class: AVATAR_CLASS) { client.initials }
      span(class: NAME_CLASS) { client.name }
    end
  end

  def render_visit_cell(entry)
    if entry.next_visit_at
      span(class: NEXT_VISIT_CLASS) { next_phrase(entry.next_visit_at) }
    elsif entry.last_visit_at
      span(class: LAST_VISIT_CLASS) { "Última: #{short_date(entry.last_visit_at)}" }
    else
      span(class: LAST_VISIT_CLASS) { "—" }
    end
  end
end
