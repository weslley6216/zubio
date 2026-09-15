class Components::Owner::FormCard < Components::Base
  HEADING_ID = "form-heading".freeze
  PAGE_CLASS = "mx-auto w-full max-w-md px-3 py-4".freeze
  CARD_CLASS = "rounded-2xl border border-line bg-surface p-4".freeze
  TITLE_CLASS = "text-xl font-extrabold tracking-tight text-ink".freeze
  SUBTITLE_CLASS = "text-sm text-ink-muted".freeze
  FORM_CLASS = "mt-3 grid grid-cols-1 gap-3.5".freeze

  def initialize(title:, subtitle:)
    @title = title
    @subtitle = subtitle
  end

  def view_template
    main(class: PAGE_CLASS) do
      section(aria_labelledby: HEADING_ID, data: { panel: true }, class: CARD_CLASS) do
        h1(id: HEADING_ID, class: TITLE_CLASS) { @title }
        p(class: SUBTITLE_CLASS) { @subtitle }
        yield(self)
      end
    end
  end
end
