RSpec::Matchers.define :mirror_branding_neutrals do
  match do |stylesheet|
    blocks = {
      light: [ stylesheet[/^:root \{(.*?)\}/m, 1] ],
      dark: [
        stylesheet[/:root:not\(\[data-theme="light"\]\) \{(.*?)\}/m, 1],
        stylesheet[/^:root\[data-theme="dark"\] \{(.*?)\}/m, 1]
      ]
    }

    @divergences = blocks.flat_map do |theme, theme_blocks|
      expected = Branding::NEUTRALS.fetch(theme)

      theme_blocks.map { |block| block.to_s.scan(/--([\w-]+):\s*(#\h{6});/).to_h.slice(*expected.keys) }
        .reject { |declared| declared == expected }
        .map { |declared| "#{theme}: #{declared}" }
    end

    @divergences.empty?
  end

  failure_message do
    "expected the stylesheet to declare the neutrals Branding::NEUTRALS mirrors, but it diverges in #{@divergences.join('; ')}"
  end

  failure_message_when_negated do
    "expected the stylesheet to diverge from Branding::NEUTRALS, but every theme block matches it"
  end
end
