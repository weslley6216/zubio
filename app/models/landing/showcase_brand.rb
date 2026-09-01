class Landing::ShowcaseBrand
  Service = Struct.new(:name, :duration, :price)

  CATALOG = [
    {
      key: "salao", name: "Studio Aurora", initial: "A", segment: "salão",
      meta: "Rua das Palmeiras, 240 · Pinheiros", host: "studioaurora.zubio.com.br",
      brand_600: "#5A3FE0",
      services: [ [ "Corte feminino", "45 min", "R$ 90,00" ], [ "Coloração completa", "120 min", "R$ 240,00" ] ]
    },
    {
      key: "estetica", name: "Casa Verde Estética", initial: "C", segment: "estética",
      meta: "Av. Sumaré, 88 · Perdizes", host: "casaverde.zubio.com.br",
      brand_600: "#0B7658",
      services: [ [ "Limpeza de pele", "60 min", "R$ 120,00" ], [ "Massagem relaxante", "90 min", "R$ 180,00" ] ]
    },
    {
      key: "barbearia", name: "Barbearia Norte", initial: "N", segment: "barbearia",
      meta: "Rua Aurora, 15 · Santa Cecília", host: "barbearianorte.zubio.com.br",
      brand_600: "#96590B",
      services: [ [ "Corte máquina", "30 min", "R$ 45,00" ], [ "Corte + barba", "60 min", "R$ 80,00" ] ]
    },
    {
      key: "clinica", name: "Clínica Vernes", initial: "V", segment: "psicologia",
      meta: "Al. Santos, 900 · Jardins", host: "vernes.zubio.com.br",
      brand_600: "#1E60C4",
      services: [ [ "Sessão avulsa", "50 min", "R$ 200,00" ], [ "Primeira consulta", "80 min", "R$ 260,00" ] ]
    }
  ].freeze

  attr_reader :key, :name, :initial, :segment, :meta, :host, :brand_600, :services

  def self.all
    @all ||= CATALOG.map { |attributes| new(**attributes) }
  end

  def self.css_rules
    all.map { |showcase_brand| showcase_brand.css_rule }.join +
      all.map { |showcase_brand| showcase_brand.variant_rule }.join
  end

  def initialize(key:, name:, initial:, segment:, meta:, host:, brand_600:, services:)
    @key = key
    @name = name
    @initial = initial
    @segment = segment
    @meta = meta
    @host = host
    @brand_600 = brand_600
    @services = services.map { |attributes| Service.new(*attributes) }
  end

  def css_rule
    ramp = Branding::ColorScale.new(brand_600).tokens.map { |step, value| "--demo-#{step}:#{value};" }.join

    %([data-demo-brand="#{key}"]{#{ramp}})
  end

  def variant_rule
    %([data-demo-brand="#{key}"] [data-demo-for="#{key}"]{display:inline})
  end
end
