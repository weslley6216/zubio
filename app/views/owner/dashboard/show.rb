class Views::Owner::Dashboard::Show < Views::Base
  def initialize(branding:)
    @branding = branding
  end

  def view_template
    render Views::Layouts::Application.new(title: "Painel · Zubio", branding: @branding) do
      div(class: "mx-auto mt-16") do
        h1(class: "text-2xl font-semibold") { "Painel" }
      end
    end
  end
end
