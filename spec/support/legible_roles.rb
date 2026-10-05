RSpec::Matchers.define :have_legible_roles do |prefix|
  match do |css|
    color = ->(name) { Branding::ColorScale.new(css[/--#{prefix}-#{name}:(#\h{6});/, 1]) }

    @failures = Branding::NEUTRALS.flat_map do |theme, neutrals|
      backgrounds = neutrals.values.map { |hex| Branding::ColorScale.new(hex) }
      [
        ("ink #{theme}" if backgrounds.any? { |background| color.("ink-#{theme}").contrast_against(background) < Branding::ColorScale::MIN_CONTRAST }),
        ("mark #{theme}" if backgrounds.any? { |background| color.("mark-#{theme}").contrast_against(background) < Branding::ColorScale::MIN_NON_TEXT_CONTRAST }),
        ("soft-ink #{theme}" if color.("soft-ink-#{theme}").contrast_against(color.("soft-#{theme}")) < Branding::ColorScale::MIN_CONTRAST)
      ].compact
    end

    @failures.empty?
  end

  failure_message do |css|
    "expected the #{prefix} roles of #{css[/--#{prefix}-600:(#\h{6});/, 1]} to read, but these did not: #{@failures.join(', ')}"
  end

  failure_message_when_negated do |css|
    "expected some #{prefix} role of #{css[/--#{prefix}-600:(#\h{6});/, 1]} not to read, but every one did"
  end
end
