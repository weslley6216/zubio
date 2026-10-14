class Components::Owner::OutsideHoursNotice < Components::Base
  HEADING_SINGULAR = "1 agendamento ficou fora do expediente".freeze
  REASSURANCE_SINGULAR = "Ele continua valendo — fale com o cliente se precisar remarcar.".freeze
  REASSURANCE_PLURAL = "Eles continuam valendo — fale com os clientes se precisar remarcar.".freeze

  def initialize(conflicts:)
    @conflicts = conflicts
  end

  def view_template
    return if @conflicts.empty?

    render Components::Alert.new(tone: :neutral) do
      div(class: "grid gap-1", data: { outside_hours: true }) do
        span(class: "font-bold") { heading }
        ul(class: "grid gap-0.5") do
          @conflicts.each { |appointment| li { line_for(appointment) } }
        end
        span(class: "text-ink-muted") { reassurance }
      end
    end
  end

  private

  def heading
    @conflicts.one? ? HEADING_SINGULAR : "#{@conflicts.size} agendamentos ficaram fora do expediente"
  end

  def reassurance
    @conflicts.one? ? REASSURANCE_SINGULAR : REASSURANCE_PLURAL
  end

  def line_for(appointment)
    "#{appointment.client.name}, #{appointment.starts_at.strftime('%d/%m')} às #{appointment.starts_at.strftime('%H:%M')}"
  end
end
