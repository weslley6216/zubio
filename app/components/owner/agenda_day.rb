class Components::Owner::AgendaDay < Components::Base
  include Phlex::Rails::Helpers::TurboFrameTag

  FRAME_ID = "agenda_day".freeze

  EMPTY_TITLE = "Nenhum agendamento neste dia.".freeze
  SHARE_LABEL = "Seu link".freeze
  SHARE_HELPER = "Mande esse endereço para suas clientes. É por ele que elas escolhem o horário.".freeze

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
      @appointments.any? ? render_list : render_empty_state
      render_install_invite
    end
  end

  def render_aside
    aside(class: "lg:border-l lg:border-line lg:bg-surface") do
      render Components::Owner::AppointmentDetailFrame.new(selected: @selected, selected_visit_number: @selected_visit_number)
    end
  end

  def render_title_row
    div(class: "flex items-baseline gap-2.5") do
      h1(class: "flex-grow text-[20px] font-extrabold tracking-[-0.02em] text-ink") { render Components::LongDate.new(date: @day) }
      span(class: "text-[13px] font-bold tabular-nums text-ink-muted") { count_label }
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
