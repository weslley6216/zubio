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
  SKELETON_ROW_CLASS = "flex gap-3 rounded-xl border border-line bg-surface px-4 py-3.5 motion-safe:animate-pulse".freeze
  SKELETON_ROW_TIME_CLASS = "h-4 w-8 rounded bg-line-strong".freeze
  SKELETON_ROW_DURATION_CLASS = "h-2.5 w-6 rounded bg-line-strong".freeze
  SKELETON_ROW_TITLE_CLASS = "h-3.5 w-28 rounded bg-line-strong".freeze
  SKELETON_ROW_SUBTITLE_CLASS = "h-3 w-16 rounded bg-line-strong".freeze
  SKELETON_ROW_BADGE_CLASS = "h-5 w-20 rounded-full bg-line-strong".freeze
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
        div(data: { frame_content: true }) do
          occupying.any? ? render_list : render_empty_state
          render_cancelled_group if cancelled.any?
        end
        render_rows_skeleton
      end
      render_install_invite
    end
  end

  def render_rows_skeleton
    div(aria_hidden: "true", data: { skeleton: true }, class: SKELETON_CLASS) do
      SKELETON_ROWS.times { render_skeleton_row }
    end
  end

  def render_skeleton_row
    div(class: "min-h-0 overflow-hidden") do
      div(class: SKELETON_ROW_CLASS) do
        div(class: "flex w-12 flex-none flex-col items-center gap-1") do
          div(class: SKELETON_ROW_TIME_CLASS)
          div(class: SKELETON_ROW_DURATION_CLASS)
        end
        div(class: "w-px flex-none bg-line")
        div(class: "flex min-w-0 flex-grow flex-col gap-1.5") do
          div(class: SKELETON_ROW_TITLE_CLASS)
          div(class: SKELETON_ROW_SUBTITLE_CLASS)
          div(class: SKELETON_ROW_BADGE_CLASS)
        end
      end
    end
  end

  def render_aside
    aside(class: "lg:border-l lg:border-line lg:bg-surface") do
      render Components::Owner::AppointmentDetailFrame.new(selected: @selected, selected_visit_number: @selected_visit_number)
    end
  end

  def render_title_row
    div(class: "flex flex-wrap items-center gap-2.5") do
      h1(class: "min-w-0 flex-grow truncate text-[20px] font-extrabold tracking-[-0.02em] text-ink", data: { frame_title: true }) { render Components::LongDate.new(date: @day) }
      span(class: "text-[13px] font-bold tabular-nums text-ink-muted", data: { frame_content: true }) { count_label }
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
    render Components::Icon.new(:plus, stroke_width: "2.4", class: NEW_APPOINTMENT_ICON_CLASS)
  end

  def partitioned = @partitioned ||= @appointments.partition { |appointment| !appointment.cancelled? }
  def occupying = partitioned.first
  def cancelled = partitioned.last

  def count_label
    count = occupying.count
    "#{count} #{count == 1 ? 'atendimento' : 'atendimentos'}"
  end

  def cancelled_label
    count = cancelled.count
    "#{count} #{count == 1 ? 'desmarcado' : 'desmarcados'}"
  end

  def render_list
    div(class: "grid gap-2.5") do
      occupying.each { |appointment| render Components::Owner::AppointmentRow.new(appointment: appointment, selected: appointment == @selected, out_of_hours: @out_of_hours.include?(appointment)) }
    end
  end

  def render_cancelled_group
    details(class: "group mt-1", data: { preserve_open: true }) do
      summary(class: "flex min-h-[48px] cursor-pointer list-none items-center justify-between rounded-xl border border-dashed border-line-strong px-4 text-[13px] font-bold text-ink-muted [&::-webkit-details-marker]:hidden") do
        span { cancelled_label }
        render Components::Icon.new(:chevron_down, stroke_width: "2.6", class: "h-4 w-4 flex-none text-ink-muted transition-transform group-open:rotate-180")
      end
      div(class: "mt-2.5 grid gap-2.5") do
        cancelled.each { |appointment| render Components::Owner::AppointmentRow.new(appointment: appointment) }
      end
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
    render Components::Icon.new(:calendar, class: "h-7 w-7 text-ink-subtle")
  end

  def render_install_invite
    render Components::Owner::InstallInvite.new(name: @tenant.name, icon: @branding.invite_icon, initial: @tenant.initial)
  end
end
