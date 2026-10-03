class Components::Owner::SettingsBackLink < Components::Base
  LABEL = Components::Owner::Header::SETTINGS_LABEL
  ICON = "m15 6-6 6 6 6".freeze
  CLASS = "inline-flex min-h-11 items-center gap-1 text-sm font-bold text-ink-muted hover:text-ink".freeze

  def view_template
    a(href: owner_settings_path, class: CLASS) do
      svg(viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2.5", stroke_linecap: "round",
        stroke_linejoin: "round", aria_hidden: "true", class: "h-4 w-4") { |icon| icon.path(d: ICON) }
      plain LABEL
    end
  end
end
