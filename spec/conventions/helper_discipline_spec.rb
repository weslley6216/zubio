require "rails_helper"

RSpec.describe "Helper discipline" do
  METHOD_DEFINITION = /^\s*def\s/
  SUPPORT_ASSERTION = /\bexpect\s*[({]/

  PENDING_SPECS = [
    "spec/components/alert_spec.rb",
    "spec/components/form/color_swatches_spec.rb",
    "spec/components/owner/brand_question/colors_spec.rb",
    "spec/components/owner/brand_question/logo_spec.rb",
    "spec/components/owner/brand_question/name_spec.rb",
    "spec/components/owner/menu_spec.rb",
    "spec/components/owner/onboarding/screen_spec.rb",
    "spec/components/owner/service/fields_spec.rb",
    "spec/components/owner/settings_back_link_spec.rb",
    "spec/components/owner/share_link_spec.rb",
    "spec/components/owner/working_hours/fields_spec.rb",
    "spec/components/toggle_spec.rb",
    "spec/conventions/comment_discipline_spec.rb",
    "spec/conventions/neutral_mirror_spec.rb",
    "spec/models/branding_spec.rb",
    "spec/models/concerns/stylesheet_producer_spec.rb",
    "spec/models/tenant_spec.rb",
    "spec/models/weekly_schedule_spec.rb",
    "spec/models/working_hour/summary_spec.rb",
    "spec/system/landing_spec.rb",
    "spec/system/onboarding_schedule_spec.rb",
    "spec/system/onboarding_viewport_spec.rb",
    "spec/system/owner/branding_accent_spec.rb",
    "spec/system/owner/branding_compact_spec.rb",
    "spec/system/owner/branding_repaint_spec.rb",
    "spec/system/owner/brand_logo_spec.rb",
    "spec/system/registration_footer_spec.rb",
    "spec/system/surface_spec.rb",
    "spec/views/palette_coverage_spec.rb",
    "spec/views/secondary_fill_spec.rb"
  ].freeze

  PENDING_SUPPORT = [].freeze

  it "declares no method in a spec file" do
    specs = Dir[Rails.root.join("spec/**/*_spec.rb")].map { |path| Pathname.new(path).relative_path_from(Rails.root).to_s }

    offenders = specs.select { |path| Rails.root.join(path).read.match?(METHOD_DEFINITION) } - PENDING_SPECS

    expect(offenders).to be_empty, "Spec files declaring methods: #{offenders.join(', ')}"
  end

  it "keeps a cleaned spec off the pending list" do
    cleaned = PENDING_SPECS.reject { |path| Rails.root.join(path).read.match?(METHOD_DEFINITION) }

    expect(cleaned).to be_empty, "Remove from PENDING_SPECS: #{cleaned.join(', ')}"
  end

  it "keeps assertions out of spec/support" do
    supports = Dir[Rails.root.join("spec/support/**/*.rb")].map { |path| Pathname.new(path).relative_path_from(Rails.root).to_s }

    offenders = supports.select { |path| Rails.root.join(path).read.match?(SUPPORT_ASSERTION) } - PENDING_SUPPORT

    expect(offenders).to be_empty, "Support files asserting: #{offenders.join(', ')}"
  end

  it "keeps a cleaned support file off the pending list" do
    cleaned = PENDING_SUPPORT.reject { |path| Rails.root.join(path).read.match?(SUPPORT_ASSERTION) }

    expect(cleaned).to be_empty, "Remove from PENDING_SUPPORT: #{cleaned.join(', ')}"
  end

  it "recognizes a method definition at any indentation, one-line or not" do
    probe = [ "def sign_in", "  def field(name) = name", "    def  body" ]

    expect(probe.grep(METHOD_DEFINITION).size).to eq(3)
  end

  it "leaves a word merely containing def out of the count" do
    probe = [ "  defaults = {}", %(  it "is undefined"), "  default_hours" ]

    expect(probe.grep(METHOD_DEFINITION)).to be_empty
  end
end
