class Views::Pages::Home::BookingPreview < Views::Base
  DAYS = [ [ "TER", "4", true ], [ "QUA", "5", false ], [ "QUI", "6", false ], [ "SEX", "7", false ] ].freeze
  SLOTS = [
    [ "09:00", :free ], [ "09:45", :picked ], [ "10:30", :taken ], [ "11:15", :free ],
    [ "12:00", :taken ], [ "14:00", :free ], [ "14:45", :free ], [ "15:30", :free ]
  ].freeze
  SIGNAL_BARS = %w[h-1 h-1.5 h-2 h-2.5].freeze

  def initialize(showcase_brands:)
    @showcase_brands = showcase_brands
  end

  def view_template
    div(class: "mx-auto w-full max-w-[22.5rem] rounded-[2.75rem] bg-ink p-2.5 shadow-xl",
        data: { demo_brand: @showcase_brands.first.key, showcase_brand_target: "stage" }) do
      div(class: "relative flex min-h-[46rem] flex-col overflow-hidden rounded-[2.25rem] bg-surface-2") do
        render_notch
        render_status_bar
        render_establishment_bar
        render_steps
        render_confirmation_bar
        render_home_indicator
      end
    end
  end

  private

  def variants(&block)
    @showcase_brands.each do |showcase_brand|
      span(data: { demo_for: showcase_brand.key }) { block.call(showcase_brand) }
    end
  end

  def render_notch
    div(class: "absolute left-1/2 top-2 z-10 h-6 w-24 -translate-x-1/2 rounded-full bg-ink")
  end

  def render_status_bar
    div(class: "flex items-center justify-between bg-demo px-6 pb-1 pt-3.5 text-[0.7rem] font-bold tabular-nums text-on-demo") do
      span { "09:41" }
      div(class: "flex items-end gap-0.5") do
        SIGNAL_BARS.each { |bar_height| span(class: "w-0.5 rounded-full bg-current #{bar_height}") }
        span(class: "ml-1.5 block h-2.5 w-5 rounded-[3px] border border-current p-0.5") do
          span(class: "block h-full w-2/3 rounded-[1px] bg-current")
        end
      end
    end
  end

  def render_establishment_bar
    div(class: "grid gap-3 bg-demo px-5 pb-9 pt-4 text-on-demo", data: { demo_bar: true }) do
      div(class: "flex items-center gap-3") do
        div(class: "grid h-11 w-11 flex-none place-items-center rounded-xl bg-white/20 text-lg font-extrabold") do
          variants { |showcase_brand| plain showcase_brand.initial }
        end
        div(class: "grid gap-1") do
          span(class: "text-lg font-extrabold tracking-tight") { variants { |showcase_brand| plain showcase_brand.name } }
          span(class: "text-xs opacity-90") { variants { |showcase_brand| plain showcase_brand.meta } }
        end
      end
      div(class: "flex flex-wrap gap-1.5 text-[0.7rem] font-bold") do
        span(class: "rounded-full bg-white/20 px-2.5 py-1.5") { "Aberto até 20h" }
        span(class: "rounded-full bg-white/20 px-2.5 py-1.5") { "Confirmação na hora" }
      end
    end
  end

  def render_steps
    div(class: "-mt-4 grid flex-1 content-start gap-7 rounded-t-3xl bg-surface-2 p-5") do
      render_service_step
      render_time_step
    end
  end

  def render_service_step
    div(class: "grid gap-3") do
      render_step_label("1", "Escolha o serviço")
      render_service_row(0, selected: false)
      render_service_row(1, selected: true)
    end
  end

  def render_step_label(number, label)
    div(class: "flex items-center gap-2.5") do
      span(class: "grid h-6 w-6 place-items-center rounded-full bg-demo-100 text-xs font-extrabold text-demo-700") { number }
      span(class: "text-base font-bold tracking-tight text-ink") { label }
    end
  end

  def render_service_row(index, selected:)
    frame = selected ? "border-2 border-demo bg-surface shadow-md" : "border border-line bg-surface shadow-sm"
    badge = selected ? "bg-demo text-on-demo" : "bg-surface-3 text-ink"

    div(class: "flex items-center gap-2.5 rounded-xl px-3.5 py-3.5 #{frame}") do
      div(class: "grid gap-0.5") do
        span(class: "text-sm font-bold text-ink") { variants { |showcase_brand| plain showcase_brand.services[index].name } }
        span(class: "text-xs text-ink-muted") { variants { |showcase_brand| plain showcase_brand.services[index].duration } }
      end
      span(class: "ml-auto flex-none rounded-full px-2.5 py-1.5 text-xs font-bold tabular-nums #{badge}") do
        variants { |showcase_brand| plain showcase_brand.services[index].price }
      end
    end
  end

  def render_time_step
    div(class: "grid gap-3") do
      render_step_label("2", "Escolha o horário")
      div(class: "flex gap-2") { DAYS.each { |weekday, day, picked| render_day(weekday, day, picked) } }
      div(class: "grid grid-cols-4 gap-2") { SLOTS.each { |time, state| render_slot(time, state) } }
    end
  end

  def render_day(weekday, day, picked)
    frame = picked ? "bg-demo text-on-demo shadow-md" : "border border-line bg-surface text-ink"

    div(class: "grid flex-1 justify-items-center rounded-xl py-3 #{frame}") do
      span(class: "text-[0.65rem] font-bold") { weekday }
      span(class: "text-xl font-extrabold leading-tight") { day }
    end
  end

  def render_slot(time, state)
    frame = {
      free: "border border-line bg-surface text-ink",
      picked: "bg-demo text-on-demo shadow-md",
      taken: "border border-dashed border-line-strong bg-surface-3 text-ink-subtle line-through"
    }.fetch(state)

    div(class: "rounded-lg py-3 text-center text-xs font-bold tabular-nums #{frame}") { time }
  end

  def render_confirmation_bar
    div(class: "flex flex-none items-center gap-3 border-t border-line bg-surface px-5 pb-4 pt-4") do
      div(class: "grid gap-0.5") do
        span(class: "text-sm font-bold text-ink") { variants { |showcase_brand| plain showcase_brand.services[1].name } }
        span(class: "text-xs text-ink-muted") { "Ter, 4 ago · 09:45" }
      end
      span(class: "ml-auto flex-none rounded-lg bg-demo px-4 py-2.5 text-sm font-bold text-on-demo") { "Confirmar" }
    end
  end

  def render_home_indicator
    div(class: "flex flex-none justify-center bg-surface pb-2.5") do
      span(class: "h-1 w-28 rounded-full bg-ink-subtle")
    end
  end
end
