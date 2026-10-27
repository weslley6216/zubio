class Components::Owner::AgendaDay < Components::Base
  include Phlex::Rails::Helpers::TurboFrameTag

  FRAME_ID = "agenda_day".freeze

  EMPTY_TITLE = "Nenhum agendamento neste dia.".freeze
  SHARE_LABEL = "Seu link".freeze
  SHARE_HELPER = "Mande esse endereço para suas clientes. É por ele que elas escolhem o horário.".freeze
  NEW_APPOINTMENT_LABEL = "Novo agendamento".freeze
  NEW_APPOINTMENT_CLASS = "flex min-h-[40px] flex-none items-center gap-1.5 rounded-[10px] bg-brand-600 px-3.5 text-[13px] font-bold text-on-brand".freeze
  NEW_APPOINTMENT_ICON_CLASS = "h-4 w-4 flex-none".freeze
  SKELETON_CLASS = "absolute inset-0 grid grid-rows-[repeat(auto-fill,103px)] auto-rows-[0px] gap-2.5 overflow-hidden".freeze
  SKELETON_ROW_CLASS = "rounded-xl bg-surface-3 motion-safe:animate-pulse".freeze
  SKELETON_ROWS = 3

  def initialize(tenant:, branding:, day:, appointments:, out_of_hours: Set.new, selected: nil, selected_visit_number: nil)
    @tenant = tenant
    @branding = branding
    @day = day
    @appointments = appointments
    @out_of_hours = out_of_hours
    @selected = selected
    @selected_visit_number = selected_visit_number
  end

  def view_template
    turbo_frame_tag(FRAME_ID, class: "grid lg:grid-cols-[minmax(0,1fr)_440px]",
      data: {
        controller: "active-row",
        active_row_active_class: Components::Owner::AppointmentRow::ACTIVE_CLASS,
        active_row_resting_class: Components::Owner::AppointmentRow::RESTING_CLASS
      }) do
      render_main
      render_aside
    end
  end

  private

  def render_main
    main(class: "#{Components::Owner::Panel::CONTENT_WIDE} grid content-start gap-3.5 py-5") do
      render_title_row
      div(class: "relative") do
        div(data: { frame_content: true }) { @appointments.any? ? render_list : render_empty_state }
        render_rows_skeleton
      end
      render_install_invite
    end
  end

  def render_rows_skeleton
    div(aria_hidden: "true", data: { skeleton: true }, class: SKELETON_CLASS) do
      SKELETON_ROWS.times { div(class: SKELETON_ROW_CLASS) }
    end
  end

  def render_aside
    aside(class: "lg:border-l lg:border-line lg:bg-surface") do
      render Components::Owner::AppointmentDetailFrame.new(selected: @selected, selected_visit_number: @selected_visit_number)
    end
  end

  def render_title_row
    div(class: "flex flex-wrap items-center gap-2.5") do
      h1(class: "min-w-0 flex-grow truncate text-[20px] font-extrabold tracking-[-0.02em] text-ink") { render Components::LongDate.new(date: @day) }
      span(class: "text-[13px] font-bold tabular-nums text-ink-muted") { count_label }
      render_new_appointment_link
    end
  end

  def render_new_appointment_link
    a(href: new_owner_appointment_path, class: NEW_APPOINTMENT_CLASS) do
      render_plus_icon
      plain NEW_APPOINTMENT_LABEL
    end
  end

  def render_plus_icon
    svg(viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2.4", stroke_linecap: "round",
      stroke_linejoin: "round", aria_hidden: "true", class: NEW_APPOINTMENT_ICON_CLASS) do |icon|
      icon.path(d: "M12 5v14M5 12h14")
    end
  end

  def count_label
    count = @appointments.count { |appointment| !appointment.cancelled? }
    "#{count} #{count == 1 ? 'atendimento' : 'atendimentos'}"
  end

  def render_list
    div(class: "grid gap-2.5") do
      @appointments.each { |appointment| render Components::Owner::AppointmentRow.new(appointment: appointment, selected: appointment == @selected, out_of_hours: @out_of_hours.include?(appointment)) }
    end
  end

  def render_empty_state
    div(class: "grid gap-3.5") do
      div(class: "grid justify-items-center gap-2 rounded-xl border border-dashed border-line-strong bg-surface px-4 py-5 text-center") do
        render_calendar_icon
        p(class: "text-sm font-bold text-ink") { EMPTY_TITLE }
      end
      render Components::Owner::ShareLink.new(host: @tenant.canonical_host, name: @tenant.name, label: SHARE_LABEL, helper: SHARE_HELPER)
    end
  end

  def render_calendar_icon
    svg(viewBox: "0 0 28 28", fill: "none", stroke: "currentColor", stroke_width: "2", stroke_linecap: "round",
      stroke_linejoin: "round", aria_hidden: "true", class: "h-7 w-7 text-ink-subtle") do |icon|
      icon.rect(x: "3", y: "5", width: "18", height: "16", rx: "3")
      icon.path(d: "M8 3v4M16 3v4M3 11h18")
    end
  end

  def render_install_invite
    render Components::Owner::InstallInvite.new(name: @tenant.name, icon: @branding.invite_icon, initial: @tenant.initial)
  end
end
