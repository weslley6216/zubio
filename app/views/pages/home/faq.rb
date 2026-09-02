class Views::Pages::Home::Faq < Views::Base
  QUESTIONS = [
    [ "Preciso instalar alguma coisa?", "Não. O Zubio abre no navegador, no computador e no celular. Seu cliente pode salvar o link na tela inicial e usar como aplicativo, sem passar por loja." ],
    [ "Já uso caderno e WhatsApp. Vou perder meu histórico?", "Não. Você continua atendendo como sempre — o Zubio vale do próximo agendamento em diante. Lançar à mão no painel quem marcou por telefone está no plano." ],
    [ "E se dois clientes escolherem o mesmo horário?", "O horário fica travado na primeira reserva: a segunda pessoa recebe o aviso na hora e a lista de horários livres se atualiza. Não deixar reserva dupla passar é a regra mais importante do sistema." ],
    [ "Trabalho sozinho. Serve para mim?", "Serve. Com um profissional o painel fica mais simples: sua agenda, seus serviços, seu link. Se um dia a equipe crescer, é só adicionar gente." ],
    [ "Que endereço meu negócio recebe?", "Todo estabelecimento recebe um endereço no formato seunegocio.zubio.com.br assim que se cadastra, já com a sua marca aplicada." ]
  ].freeze

  def view_template
    section(id: "faq", class: "scroll-mt-16 border-b border-line") do
      div(class: "mx-auto w-full max-w-3xl px-6 py-20") do
        h2(class: "mb-9 text-3xl font-extrabold leading-tight tracking-tight text-ink sm:text-4xl") { "Dúvidas antes de começar" }
        div(class: "grid gap-3") { QUESTIONS.each { |question, answer| render_question(question, answer) } }
      end
    end
  end

  private

  # The padding lives on the summary, not on the details, so the whole row is
  # the click target instead of the single line of text.
  def render_question(question, answer)
    details(class: "overflow-hidden rounded-xl border border-line bg-surface") do
      summary(class: "cursor-pointer px-5 py-4 text-base font-bold text-ink hover:bg-surface-2") { question }
      p(class: "px-5 pb-5 text-sm leading-relaxed text-ink-muted") { answer }
    end
  end
end
