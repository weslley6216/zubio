class Views::Pages::Home::Whitelabel < Views::Base
  GUARANTEES = [
    [ "Seu endereço", "seunegocio.zubio.com.br fica pronto assim que você se cadastra." ],
    [ "Sua cor em todo lugar", "Botão, seleção, destaque: tudo segue a cor que você escolheu." ],
    [ "Sempre legível", "A gente confere o contraste da sua cor antes de publicar. Nada de texto que some no fundo." ]
  ].freeze

  def initialize(showcase_brands:)
    @showcase_brands = showcase_brands
  end

  def view_template
    section(id: "whitelabel", class: "scroll-mt-16 border-b border-line bg-surface-2") do
      div(class: "mx-auto grid w-full max-w-6xl gap-11 px-6 py-20") do
        render_intro
        render_brand_row
        div(class: "grid gap-6 sm:grid-cols-3") { GUARANTEES.each { |title, body| render_guarantee(title, body) } }
      end
    end
  end

  private

  def render_intro
    div(class: "grid max-w-2xl gap-3") do
      h2(class: "text-3xl font-extrabold leading-tight tracking-tight text-ink sm:text-4xl") { "Seu cliente vê a sua marca, não a nossa" }
      p(class: "text-lg text-ink-muted") do
        "Você escolhe a cor, o logo e o nome. A partir daí a página de agendamento é do seu negócio, com endereço próprio. O Zubio fica por trás, cuidando dos horários."
      end
    end
  end

  def render_brand_row
    div(class: "grid grid-cols-2 gap-3 sm:flex sm:flex-wrap") do
      @showcase_brands.each do |showcase_brand|
        div(class: "flex items-center gap-3 rounded-xl border border-line bg-surface px-4 py-3") do
          span(class: "grid h-9 w-9 flex-none place-items-center rounded-lg text-sm font-extrabold text-white",
               style: "background:#{showcase_brand.brand_600}") { showcase_brand.initial }
          div(class: "grid min-w-0 gap-0.5") do
            span(class: "truncate text-sm font-bold text-ink") { showcase_brand.name }
            span(class: "text-xs text-ink-muted") { showcase_brand.segment }
          end
        end
      end
    end
  end

  def render_guarantee(title, body)
    div(class: "grid content-start gap-2") do
      h3(class: "text-base font-bold tracking-tight text-ink") { title }
      p(class: "text-sm leading-relaxed text-ink-muted") { body }
    end
  end
end
