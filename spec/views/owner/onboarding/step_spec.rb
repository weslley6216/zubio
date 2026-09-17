require "rails_helper"

RSpec.describe "Owner onboarding step frame", type: :view do
  def dummy_body_class
    Class.new(Components::Base) do
      const_set(:HEADING_ID, "dummy-heading")

      def view_template
        h1(id: self.class::HEADING_ID) { "Dummy question" }
      end
    end
  end

  def render_step(step:)
    render Views::Owner::Onboarding::Step.new(
      tenant: build(:tenant, :onboarding), branding: Branding.platform_default, body: dummy_body_class.new,
      step: step, submit_url: "/owner/onboarding/#{step}", submit_label: "Continuar"
    )
  end

  it "shows the counter and the group label for the given step" do
    render_step(step: "name")

    expect(rendered).to include("2 de 5")
    expect(rendered).to include("Sua marca")
  end

  it "serves the same frame for another question, only the counter changing" do
    render_step(step: "logo")

    expect(rendered).to include("3 de 5")
  end

  it "renders the question body inside the form" do
    render_step(step: "colors")

    expect(rendered).to include("Dummy question")
  end

  it "keeps the surface and ink tokens that carry the theme in light and dark" do
    render_step(step: "colors")

    expect(rendered).to include("bg-surface")
    expect(rendered).to include("text-ink")
  end
end
