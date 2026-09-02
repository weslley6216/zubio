class Views::Pages::Home::FinalCta < Views::Base
  GUARANTEES = [
    "Sem comissão por agendamento",
    "Dados isolados por estabelecimento",
    "Seu endereço próprio no cadastro"
  ].freeze

  def view_template
    section(class: "bg-brand-800") do
      div(class: "mx-auto grid w-full max-w-3xl gap-6 px-6 py-20 text-center") do
        h2(class: "text-3xl font-extrabold leading-tight tracking-tight text-white sm:text-4xl") { "Coloque sua agenda no ar hoje" }
        p(class: "text-lg text-white/80") do
          "Cadastre o negócio, escolha sua cor e compartilhe o link. O primeiro agendamento pode acontecer ainda hoje."
        end
        div(class: "flex flex-wrap justify-center gap-3") do
          a(href: new_signup_path, class: "rounded-xl bg-white px-7 py-4 text-base font-bold text-brand-800 shadow-md") { "Criar conta grátis" }
          a(href: "#faq", class: "rounded-xl border border-white/40 px-6 py-4 text-base font-bold text-white") { "Tirar uma dúvida" }
        end
        ul(class: "flex flex-wrap justify-center gap-x-6 gap-y-2 text-sm font-semibold text-white/70") do
          GUARANTEES.each { |guarantee| li { guarantee } }
        end
      end
    end
  end
end
