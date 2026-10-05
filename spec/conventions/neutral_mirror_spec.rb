require "rails_helper"

RSpec.describe "Neutral surfaces mirrored for color derivation" do
  it "mirrors in Ruby the neutral surfaces the stylesheet declares for each theme" do
    stylesheet = Rails.root.join("app/assets/tailwind/application.css").read

    expect(stylesheet).to mirror_branding_neutrals
  end

  it "catches a neutral that changes in the stylesheet and not in the mirror" do
    stylesheet = Rails.root.join("app/assets/tailwind/application.css").read

    drifted = stylesheet.sub("--surface-3: #eef2f5;", "--surface-3: #e5e9ec;")

    expect(drifted).not_to eq(stylesheet)
    expect(drifted).not_to mirror_branding_neutrals
  end
end
