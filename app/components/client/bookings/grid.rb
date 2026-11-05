class Components::Client::Bookings::Grid < Components::Base
  include Phlex::Rails::Helpers::TurboFrameTag

  FRAME_ID = "booking-grid".freeze
  TAKEN_LABEL = "ocupado".freeze
  NO_SERVICE_MESSAGE = "Não há atendimento nesse dia.".freeze
  FULLY_BOOKED_MESSAGE = "Não há mais horários livres nesse dia.".freeze
  GRID_HINT = "A grade anda de %<minutes>d em %<minutes>d porque o serviço dura %<minutes>d.".freeze
  REASON_MESSAGES = { no_working_day: NO_SERVICE_MESSAGE, day_off: NO_SERVICE_MESSAGE, fully_booked: FULLY_BOOKED_MESSAGE }.freeze

  HINT_CLASS = "text-[12px] text-(--theme-on-bg-muted)".freeze
  WRAPPER_CLASS = "relative rounded-2xl bg-(--theme-card) p-3 text-(--theme-on-card)".freeze
  GRID_CLASS = "grid grid-cols-3 gap-2".freeze
  SLOT_BASE_CLASS = "grid min-h-[46px] place-items-center rounded-[10px] text-[15px] font-extrabold tabular-nums".freeze
  SLOT_FREE_CLASS = "bg-(--theme-card-chip) text-(--theme-on-card) aria-pressed:bg-(--theme-accent) aria-pressed:text-(--theme-on-accent) aria-pressed:ring-2 aria-pressed:ring-inset aria-pressed:ring-[color:var(--theme-selected-ring,transparent)]".freeze
  SLOT_TAKEN_CLASS = "box-content border-[1.5px] border-dashed border-(--theme-on-card-muted) bg-(--theme-card) text-(--theme-on-card-muted) line-through".freeze
  REASON_CLASS = "p-3 text-[14px] text-(--theme-on-card-muted)".freeze
  SKELETON_CLASS = "#{GRID_CLASS} absolute inset-3 grid-rows-[repeat(auto-fill,46px)] auto-rows-[0px] overflow-hidden".freeze
  SKELETON_SLOT_CLASS = "rounded-[10px] bg-line-strong motion-safe:animate-pulse".freeze
  SKELETON_PIECES = 8

  def initialize(service:, slots:, taken_slots:, reason:, selected_slot:)
    @service = service
    @slots = slots
    @taken_slots = taken_slots
    @reason = reason
    @selected_slot = selected_slot
  end

  def view_template
    turbo_frame_tag(FRAME_ID, class: "contents", data: { action: "frame-cache:revalidated->slot-selector#reconcile" }) do
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
    p(class: HINT_CLASS, data: { grid_hint: true, frame_content: true }) { grid_hint }
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
