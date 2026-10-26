class Components::Owner::Clients::Roster < Components::Base
  include Phlex::Rails::Helpers::TurboFrameTag

  FRAME_ID = "clients".freeze
  EMPTY_TITLE = "Nenhuma cliente ainda".freeze
  EMPTY_BODY = "Quem agenda pelo seu link aparece aqui.".freeze
  SHARE_LABEL = "Seu link".freeze
  SHARE_HELPER = "Mande esse endereço para suas clientes. É por ele que elas escolhem o horário.".freeze
  NO_RESULTS = "Nenhuma cliente com esse nome ou telefone.".freeze

  def initialize(entries:, total:, tenant:)
    @entries = entries
    @total = total
    @tenant = tenant
  end

  def view_template
    turbo_frame_tag(FRAME_ID) do
      if @total.zero?
        render_empty_state
      elsif @entries.empty?
        render_no_results
      else
        render Components::Owner::Clients::List.new(entries: @entries)
        render Components::Owner::Clients::Table.new(entries: @entries)
      end
    end
  end

  private

  def render_empty_state
    div(class: "grid gap-3.5") do
      div(class: "grid justify-items-center gap-2 rounded-xl border border-dashed border-line-strong bg-surface px-4 py-5 text-center") do
        h2(class: "text-sm font-bold text-ink") { EMPTY_TITLE }
        p(class: "text-sm text-ink-muted") { EMPTY_BODY }
      end
      render Components::Owner::ShareLink.new(host: @tenant.canonical_host, name: @tenant.name, label: SHARE_LABEL, helper: SHARE_HELPER)
    end
  end

  def render_no_results
    p(class: "text-sm text-ink-muted") { NO_RESULTS }
  end
end
