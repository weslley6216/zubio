class Components::Owner::Clients::List < Components::Base
  include Components::Owner::Clients::Shared

  ROW_CLASS = "flex items-center gap-3 rounded-xl border border-line bg-surface px-3.5 py-3".freeze
  AVATAR_CLASS = "grid h-10 w-10 flex-none place-items-center rounded-full bg-brand-soft text-[14px] leading-[normal] font-extrabold text-brand-soft-ink".freeze
  NAME_CLASS = "block text-[14px] font-bold text-ink".freeze
  SUB_CLASS = "block text-[12px] text-ink-muted tabular-nums".freeze

  def initialize(entries:)
    @entries = entries
  end

  def view_template
    div(class: "grid gap-2 sm:hidden") do
      @entries.each { |entry| render_row(entry) }
    end
  end

  private

  def render_row(entry)
    div(class: ROW_CLASS) do
      div(class: AVATAR_CLASS) { entry.client.initials }
      div(class: "flex min-w-0 flex-grow flex-col gap-0.5 leading-[normal]") do
        span(class: NAME_CLASS) { entry.client.name }
        span(class: SUB_CLASS) { sub_phrase(entry) }
      end
      whatsapp_link(entry.client, size: :mobile)
    end
  end
end
