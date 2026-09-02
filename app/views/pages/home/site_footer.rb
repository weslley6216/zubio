class Views::Pages::Home::SiteFooter < Views::Base
  LINKS = [ [ "Recursos", "#recursos" ], [ "Whitelabel", "#whitelabel" ], [ "Perguntas", "#faq" ] ].freeze

  def view_template
    footer(class: "border-t border-line bg-surface") do
      div(class: "mx-auto flex w-full max-w-6xl flex-wrap items-center gap-4 px-6 py-8") do
        div(class: "flex items-center gap-2 text-sm text-ink-muted") do
          span(class: "grid h-7 w-7 place-items-center rounded-lg bg-brand-accent text-xs font-extrabold text-on-brand-accent") { "z" }
          span { "Zubio · agendamento online para o seu negócio" }
        end
        nav(class: "ml-auto flex gap-5 text-sm font-semibold text-ink-muted") do
          LINKS.each { |label, anchor| a(href: anchor) { label } }
        end
      end
    end
  end
end
