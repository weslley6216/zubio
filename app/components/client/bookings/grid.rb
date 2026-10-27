class Components::Client::Bookings::Grid < Components::Base
  include Phlex::Rails::Helpers::TurboFrameTag

  FRAME_ID = "booking-grid".freeze
  TAKEN_LABEL = "ocupado".freeze
  NO_SERVICE_MESSAGE = "Não há atendimento nesse dia.".freeze
  FULLY_BOOKED_MESSAGE = "Não há mais horários livres nesse dia.".freeze
  GRID_HINT = "A grade anda de %<minutes>d em %<minutes>d porque o serviço dura %<minutes>d.".freeze
  REASON_MESSAGES = { no_working_day: NO_SERVICE_MESSAGE, day_off: NO_SERVICE_MESSAGE, fully_booked: FULLY_BOOKED_MESSAGE }.freeze

  HINT_CLASS = "text-[12px] text-ink-subtle".freeze
  WRAPPER_CLASS = "relative".freeze
  GRID_CLASS = "grid grid-cols-4 gap-2".freeze
  SLOT_BASE_CLASS = "grid min-h-[46px] place-items-center rounded-[10px] text-[13px] font-bold tabular-nums".freeze
  SLOT_FREE_CLASS = "border border-line bg-surface aria-pressed:border-transparent aria-pressed:bg-brand-600 aria-pressed:text-on-brand aria-pressed:shadow-[0_2px_6px_color-mix(in_srgb,var(--brand-600)_20%,transparent)]".freeze
  SLOT_TAKEN_CLASS = "border border-dashed border-line-strong bg-surface-3 text-ink-subtle line-through".freeze
  REASON_CLASS = "rounded-xl border border-line bg-surface p-6 text-[14px] text-ink-muted".freeze
  SKELETON_CLASS = "#{GRID_CLASS} absolute inset-0 grid-rows-[repeat(auto-fill,46px)] auto-rows-[0px] overflow-hidden".freeze
  SKELETON_SLOT_CLASS = "rounded-[10px] bg-surface-3 motion-safe:animate-pulse".freeze
  SKELETON_PIECES = 8

  def initialize(service:, slots:, taken_slots:, reason:, selected_slot:)
    @service = service
    @slots = slots
    @taken_slots = taken_slots
    @reason = reason
    @selected_slot = selected_slot
  end

  def view_template
    turbo_frame_tag(FRAME_ID, class: "contents") do
      div(class: WRAPPER_CLASS) do
        div(data: { frame_content: true }) { @reason == :bookable ? render_grid : render_reason }
        render_skeleton
      end
      render_hint if @reason == :bookable
    end
  end

  private

  def render_skeleton
    div(aria_hidden: "true", data: { skeleton: true }, class: SKELETON_CLASS) do
      SKELETON_PIECES.times { div(class: SKELETON_SLOT_CLASS) }
    end
  end

  def render_grid
    div(class: GRID_CLASS, data: { slots: true }) do
      (@slots + @taken_slots).sort.each { |slot| @taken_slots.include?(slot) ? render_taken_slot(slot) : render_free_slot(slot) }
    end
  end

  def render_hint
    p(class: HINT_CLASS, data: { grid_hint: true }) { grid_hint }
  end

  def render_free_slot(slot)
    button(type: "button", aria_pressed: (slot == @selected_slot).to_s,
      data: { slot: true, starts_at: slot.iso8601, time: slot.strftime("%H:%M"), slot_selector_target: "slot", action: "slot-selector#select" },
      class: [ SLOT_BASE_CLASS, SLOT_FREE_CLASS ]) { slot.strftime("%H:%M") }
  end

  def render_taken_slot(slot)
    time = slot.strftime("%H:%M")
    span(class: [ SLOT_BASE_CLASS, SLOT_TAKEN_CLASS ], data: { slot_taken: true }, aria_label: "#{time}, #{TAKEN_LABEL}") { time }
  end

  def grid_hint
    Kernel.format(GRID_HINT, minutes: @service.duration_minutes)
  end

  def render_reason
    p(class: REASON_CLASS) { REASON_MESSAGES.fetch(@reason) }
  end
end
