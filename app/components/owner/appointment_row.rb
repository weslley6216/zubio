class Components::Owner::AppointmentRow < Components::Base
  CONFIRMED_LABEL = "Confirmado".freeze
  CANCELLED_LABEL = "Desmarcado".freeze
  ACTIVE_CLASS = "border-2 border-brand-600 shadow-[0_2px_6px_var(--tw-shadow-color)] shadow-brand-600/12 bg-surface".freeze
  RESTING_CLASS = "border border-line bg-surface shadow-[0_1px_2px_rgba(14,26,36,0.04)]".freeze

  def initialize(appointment:, selected: false)
    @appointment = appointment
    @selected = selected
  end

  def view_template
    @appointment.cancelled? ? render_cancelled : render_active
  end

  private

  def render_active
    div(class: "relative flex gap-3 rounded-xl px-4 py-3.5 #{active_border_class}",
      data: { active_row_target: "row", appointment_id: @appointment.id }) do
      div(class: "flex w-12 flex-none flex-col items-center") do
        span(class: "text-[16px] font-extrabold leading-[1.2] tabular-nums text-ink") { @appointment.starts_at.strftime("%H:%M") }
        span(class: "text-[11px] tabular-nums text-ink-muted") { ::Service::Duration.minutes_label(@appointment.service.duration_minutes) }
      end
      div(class: "w-px flex-none bg-line")
      div(class: "flex min-w-0 flex-grow flex-col gap-1") do
        a(href: owner_appointment_path(@appointment),
          data: { turbo_frame: Components::Owner::AppointmentDetail::FRAME_ID, turbo_action: "advance", action: "active-row#select" },
          aria_current: (@selected ? "true" : nil),
          class: "text-[14px] font-bold text-ink after:absolute after:inset-0 after:content-['']") { @appointment.client.name }
        span(class: "text-[12px] text-ink-muted") { @appointment.service.name }
        div(class: "mt-0.5 flex items-center gap-1.5") do
          render Components::Badge.new(text: CONFIRMED_LABEL, tone: :brand)
          a(href: @appointment.client.tel_href, class: "relative z-10 text-[12px] font-bold text-brand-600") { @appointment.client.phone_display }
        end
      end
    end
  end

  def active_border_class = @selected ? ACTIVE_CLASS : RESTING_CLASS

  def render_cancelled
    div(class: "flex gap-3 rounded-xl border border-dashed border-line-strong bg-surface-2 px-4 py-3.5") do
      div(class: "flex w-12 flex-none flex-col items-center") do
        span(class: "text-[16px] font-extrabold leading-[1.2] tabular-nums text-ink-subtle line-through") { @appointment.starts_at.strftime("%H:%M") }
      end
      div(class: "w-px flex-none bg-line")
      div(class: "flex min-w-0 flex-grow flex-col gap-1") do
        span(class: "text-[14px] font-bold text-ink-subtle line-through") { @appointment.client.name }
        render Components::Badge.new(text: CANCELLED_LABEL, tone: :muted)
      end
    end
  end
end
