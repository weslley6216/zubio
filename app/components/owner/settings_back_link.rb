class Components::Owner::SettingsBackLink < Components::Base
  LABEL = Components::Owner::Header::SETTINGS_LABEL
  CLASS = "inline-flex min-h-11 items-center gap-1 text-sm font-bold text-ink-muted hover:text-ink".freeze

  def view_template
    a(href: owner_settings_path, class: CLASS) do
      render Components::Icon.new(:chevron_left, stroke_width: "2.5", class: "h-4 w-4")
      plain LABEL
    end
  end
end
