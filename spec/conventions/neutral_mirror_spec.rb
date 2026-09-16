require "rails_helper"

RSpec.describe "Neutral surfaces mirrored for color derivation" do
  def stylesheet = Rails.root.join("app/assets/tailwind/application.css").read

  def declared_neutrals(block, names) = block.to_s.scan(/--([\w-]+):\s*(#\h{6});/).to_h.slice(*names)

  def theme_blocks(css)
    {
      light: [ css[/^:root \{(.*?)\}/m, 1] ],
      dark: [
        css[/:root:not\(\[data-theme="light"\]\) \{(.*?)\}/m, 1],
        css[/^:root\[data-theme="dark"\] \{(.*?)\}/m, 1]
      ]
    }
  end

  def divergences(css)
    theme_blocks(css).flat_map do |theme, blocks|
      expected = Branding::NEUTRALS.fetch(theme)

      blocks.map { |block| declared_neutrals(block, expected.keys) }
        .reject { |declared| declared == expected }
        .map { |declared| "#{theme}: #{declared}" }
    end
  end

  it "mirrors in Ruby the neutral surfaces the stylesheet declares for each theme" do
    expect(divergences(stylesheet)).to be_empty
  end

  it "catches a neutral that changes in the stylesheet and not in the mirror" do
    drifted = stylesheet.sub("--surface-3: #eef2f5;", "--surface-3: #e5e9ec;")

    expect(divergences(drifted)).not_to be_empty
  end
end
