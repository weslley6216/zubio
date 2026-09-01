class Views::Pages::Home::Faq < Views::Base
  QUESTIONS = [
    [ "Preciso instalar alguma coisa?", "Não. O Zubio roda no navegador, no computador e no celular. Seu cliente pode adicionar o link à tela inicial e usar como aplicativo, sem passar por loja." ],
    [ "Já uso caderno e WhatsApp. Vou perder meu histórico?", "Você continua atendendo como sempre. O Zubio começa a valer do próximo agendamento em diante, e agendamentos feitos por telefone podem ser lançados à mão no painel." ],
    [ "E se dois clientes escolherem o mesmo horário?", "Só a primeira reserva é aceita. A segunda pessoa recebe um aviso na hora e a lista de horários livres é atualizada — nunca acontece de dois clientes chegarem para o mesmo slot." ],
    [ "Trabalho sozinho. Serve para mim?", "Serve. Com um profissional o painel fica mais simples: sua agenda, seus serviços, seu link. Se um dia a equipe crescer, é só adicionar pessoas." ],
    [ "Que endereço meu negócio recebe?", "Todo estabelecimento recebe um endereço no formato seunegocio.zubio.com.br assim que se cadastra, com sua marca aplicada." ]
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

  def render_question(question, answer)
    details(class: "rounded-xl border border-line bg-surface px-5 py-4") do
      summary(class: "cursor-pointer text-base font-bold text-ink") { question }
      p(class: "mt-3 text-sm leading-relaxed text-ink-muted") { answer }
    end
  end
end
