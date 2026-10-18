class Components::Owner::AppointmentDetailFrame < Components::Base
  include Phlex::Rails::Helpers::TurboFrameTag

  SELECT_HINT = "Selecione um agendamento para ver os detalhes.".freeze

  def initialize(selected: nil, selected_visit_number: nil)
    @selected = selected
    @selected_visit_number = selected_visit_number
  end

  def view_template
    turbo_frame_tag(Components::Owner::AppointmentDetail::FRAME_ID,
      data: { active_row_target: "detailFrame", action: "turbo:frame-load->active-row#reconcile" }) do
      @selected ? render(Components::Owner::AppointmentDetail.new(appointment: @selected, visit_number: @selected_visit_number)) : render_placeholder
    end
  end

  private

  def render_placeholder
    div(class: "hidden lg:grid lg:place-content-center lg:justify-items-center lg:gap-2 lg:p-8 lg:text-center") do
      render_calendar_icon
      span(class: "text-[13px] text-ink-muted") { SELECT_HINT }
    end
  end

  def render_calendar_icon
    svg(viewBox: "0 0 28 28", fill: "none", stroke: "currentColor", stroke_width: "2", stroke_linecap: "round",
      stroke_linejoin: "round", aria_hidden: "true", class: "h-7 w-7 text-ink-subtle") do |icon|
      icon.rect(x: "3", y: "5", width: "18", height: "16", rx: "3")
      icon.path(d: "M8 3v4M16 3v4M3 11h18")
    end
  end
end
