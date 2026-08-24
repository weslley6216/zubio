class Views::Pages::Home < Views::Base
  FEATURES = [
    [ "Endereço só seu", "seu-estabelecimento.zubio.com.br no ar assim que você criar a conta." ],
    [ "A sua marca, não a nossa", "Logo e cor definidos por você, aplicados na hora em todas as telas." ],
    [ "Vira app no celular", "Seu cliente instala na tela inicial e volta com um toque." ]
  ].freeze

  def initialize(branding:)
    @branding = branding
  end

  def view_template
    render Views::Layouts::Application.new(title: "Zubio · Agendamento online com a sua marca", branding: @branding) do
      div(class: "mx-auto mt-16 w-full max-w-3xl px-4") do
        render_hero
        render_features
      end
    end
  end

  private

  def render_hero
    h1(class: "text-3xl font-semibold") { "Sua agenda online, com a sua marca" }
    p(class: "mt-4 max-w-xl text-lg text-gray-700") do
      "Seus clientes agendam pelo celular, no seu próprio endereço na internet, com o seu logo e a sua cor. Sem instalar app, sem comissão por agendamento."
    end
    a(href: new_signup_path, class: "mt-8 inline-block rounded-md bg-brand-600 px-6 py-3 font-medium text-on-brand") do
      "Criar meu estabelecimento"
    end
  end

  def render_features
    div(class: "mt-16 grid gap-8 sm:grid-cols-3") do
      FEATURES.each do |title, description|
        div do
          h2(class: "font-medium") { title }
          p(class: "mt-2 text-sm text-gray-700") { description }
        end
      end
    end
  end
end
