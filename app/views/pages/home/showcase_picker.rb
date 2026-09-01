class Views::Pages::Home::ShowcasePicker < Views::Base
  def initialize(showcase_brands:)
    @showcase_brands = showcase_brands
  end

  def view_template
    div(class: "grid justify-items-center gap-2") do
      span(class: "text-[0.65rem] font-extrabold uppercase tracking-[0.14em] text-ink-subtle") { "Experimente uma identidade" }
      div(class: "flex flex-wrap justify-center gap-2") do
        @showcase_brands.each_with_index { |showcase_brand, index| render_option(showcase_brand, index.zero?) }
      end
    end
  end

  private

  def render_option(showcase_brand, selected)
    button(
      type: "button",
      aria_pressed: selected.to_s,
      class: "inline-flex items-center gap-2 rounded-full border border-line bg-surface px-4 py-2 text-xs font-bold text-ink-muted aria-pressed:border-brand-accent aria-pressed:bg-brand-accent aria-pressed:text-on-brand-accent",
      data: {
        showcase_brand_target: "option",
        showcase_brand_key_param: showcase_brand.key,
        action: "showcase-brand#pick"
      }
    ) do
      span(class: "h-2.5 w-2.5 rounded-full", style: "background:#{showcase_brand.brand_600}")
      plain showcase_brand.segment.capitalize
    end
  end
end
