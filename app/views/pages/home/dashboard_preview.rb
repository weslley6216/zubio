class Views::Pages::Home::DashboardPreview < Views::Base
  NAV = [ "Visão geral", "Agenda", "Serviços", "Profissionais", "Clientes", "Minha marca" ].freeze
  STATS = [
    [ "Faturamento do dia", "R$ 1.840", "+12% sobre a terça passada" ],
    [ "Ocupação", "78%", "9 de 12 horários" ],
    [ "Clientes novos", "3", "nesta semana" ]
  ].freeze
  APPOINTMENTS = [
    [ "09:00", "45 min", "Júlia Menezes", "Corte feminino · Marina", "Confirmado" ],
    [ "09:45", "120 min", "Ana Beatriz Souza", "Coloração completa · Marina", "Aguardando" ],
    [ "14:30", "30 min", "Renata Lopes", "Retorno · Camila", "Concluído" ]
  ].freeze

  def initialize(showcase_brands:)
    @showcase_brands = showcase_brands
  end

  def view_template
    section(class: "border-b border-line") do
      div(class: "mx-auto w-full max-w-6xl px-6 py-20") do
        render_intro
        div(class: "overflow-hidden rounded-2xl border border-line bg-surface shadow-lg") do
          render_address_bar
          render_toolbar
          div(class: "grid gap-6 p-4 sm:p-6 lg:grid-cols-[12rem_1fr]") do
            render_nav
            div(class: "grid gap-5") do
              render_stats
              render_agenda
            end
          end
        end
      end
    end
  end

  private

  def render_intro
    div(class: "mb-9 grid max-w-2xl gap-3") do
      h2(class: "text-3xl font-extrabold leading-tight tracking-tight text-ink sm:text-4xl") { "O dia inteiro em uma tela" }
      p(class: "text-lg text-ink-muted") do
        "Quem chega, quanto entrou, o que ainda dá pra encaixar. É a primeira tela quando você abre — e quase sempre a única que precisa."
      end
    end
  end

  def render_address_bar
    div(class: "flex items-center gap-2 border-b border-line bg-surface-3 px-4 py-2.5") do
      span(class: "h-2.5 w-2.5 rounded-full bg-line-strong")
      span(class: "h-2.5 w-2.5 rounded-full bg-line-strong")
      span(class: "h-2.5 w-2.5 rounded-full bg-line-strong")
      span(class: "ml-2 truncate rounded-md bg-surface px-3 py-1 text-xs text-ink-muted") do
        "#{@showcase_brands.first.host}/painel"
      end
    end
  end

  def render_toolbar
    div(class: "grid gap-3 border-b border-line bg-surface-2 px-4 py-4 sm:flex sm:items-center sm:px-6") do
      div(class: "grid gap-1 sm:flex sm:items-center sm:gap-3") do
        span(class: "text-sm font-bold text-ink") { "Terça, 4 de agosto" }
        span(class: "text-sm text-ink-muted") { "12 agendamentos · 2 encaixes livres" }
      end
      span(class: "rounded-lg bg-brand-accent px-4 py-3 text-center text-sm font-bold text-on-brand-accent sm:ml-auto sm:py-2") { "Novo agendamento" }
    end
  end

  def render_nav
    nav(class: "hidden content-start gap-1 lg:grid") do
      NAV.each_with_index do |label, index|
        frame = index.zero? ? "bg-brand-100 font-bold text-brand-800" : "text-ink-muted"
        span(class: "rounded-lg px-3 py-2 text-sm #{frame}") { label }
      end
    end
  end

  def render_stats
    div(class: "grid gap-4 sm:grid-cols-3") do
      STATS.each do |label, value, note|
        div(class: "grid gap-1 rounded-xl border border-line bg-surface-2 p-4") do
          span(class: "text-xs font-bold uppercase tracking-wide text-ink-subtle") { label }
          span(class: "text-2xl font-extrabold tabular-nums text-ink") { value }
          span(class: "text-xs text-ink-muted") { note }
        end
      end
    end
  end

  def render_agenda
    div(class: "grid gap-2") do
      h3(class: "text-sm font-bold text-ink") { "Agenda de hoje" }
      APPOINTMENTS.each { |time, duration, client, detail, status| render_appointment(time, duration, client, detail, status) }
    end
  end

  def render_appointment(time, duration, client, detail, status)
    div(class: "grid gap-2 rounded-xl border border-line bg-surface px-4 py-3 sm:flex sm:items-center sm:gap-4") do
      div(class: "flex items-center gap-3 sm:w-20 sm:flex-none sm:grid sm:gap-0.5") do
        span(class: "text-sm font-bold tabular-nums text-ink") { time }
        span(class: "text-xs text-ink-subtle") { duration }
        render_status(status, "ml-auto sm:hidden")
      end
      div(class: "grid min-w-0 gap-0.5") do
        span(class: "truncate text-sm font-bold text-ink") { client }
        span(class: "truncate text-xs text-ink-muted", data: { agenda_detail: true }) { detail }
      end
      render_status(status, "ml-auto hidden flex-none sm:inline")
    end
  end

  def render_status(status, frame)
    span(class: "rounded-full bg-surface-3 px-3 py-1 text-xs font-bold text-ink-muted #{frame}") { status }
  end
end
