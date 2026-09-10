class Components::Signup::SubdomainStatus < Components::Base
  AVAILABLE = "text-success".freeze
  NEUTRAL = "text-ink-muted".freeze
  PROBLEM = "text-danger".freeze

  STATES = {
    available: [ AVAILABLE, ->(host) { "#{host} está disponível." } ],
    blank: [ NEUTRAL, ->(_host) { "Escolha um subdomínio para o seu estabelecimento." } ],
    taken: [ PROBLEM, ->(host) { "#{host} já está em uso. Escolha outro." } ],
    exclusion: [ PROBLEM, ->(_host) { "Este subdomínio é reservado pela plataforma." } ],
    invalid: [ PROBLEM, ->(_host) { "Use apenas letras minúsculas, números e hífen." } ],
    too_short: [ PROBLEM, ->(_host) { "O subdomínio precisa de pelo menos #{Tenant::SUBDOMAIN_LENGTH.min} caracteres." } ],
    too_long: [ PROBLEM, ->(_host) { "O subdomínio pode ter no máximo #{Tenant::SUBDOMAIN_LENGTH.max} caracteres." } ]
  }.freeze

  UNKNOWN = [ PROBLEM, ->(_host) { "Este subdomínio não pode ser usado." } ].freeze

  def initialize(status:, host:)
    @status = status
    @host = host
  end

  def view_template
    tone, message = STATES.fetch(@status, UNKNOWN)

    p(class: "mt-1 text-sm #{tone}") { message.call(@host) }
  end
end
