class Views::Pages::Home::FinalCta < Views::Base
  GUARANTEES = [
    "Sem comissão por agendamento",
    "Sua lista de clientes não é compartilhada",
    "Seu endereço próprio no cadastro"
  ].freeze

  def view_template
    section(class: "bg-brand-800") do
      div(class: "mx-auto grid w-full max-w-3xl gap-6 px-6 py-20 text-center") do
        h2(class: "text-3xl font-extrabold leading-tight tracking-tight text-white sm:text-4xl") { "Coloque sua agenda no ar hoje" }
        p(class: "text-lg text-white/80") do
          "Cadastre o negócio, escolha sua cor, mande o link. O primeiro agendamento pode ser ainda hoje."
        end
        div(class: "grid gap-3 sm:flex sm:flex-wrap sm:justify-center") do
          a(href: new_signup_path, class: "rounded-xl bg-white px-7 py-4 text-base font-bold text-brand-800 shadow-md hover:opacity-90") { "Criar minha agenda grátis" }
          a(href: "#faq", class: "rounded-xl border border-white/40 px-6 py-4 text-base font-bold text-white hover:bg-white/10") { "Tirar uma dúvida" }
        end
        ul(class: "flex flex-wrap justify-center gap-x-6 gap-y-2 text-sm font-semibold text-white/70") do
          GUARANTEES.each { |guarantee| li { guarantee } }
        end
      end
    end
  end
end
