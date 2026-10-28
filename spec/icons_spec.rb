require "rails_helper"

RSpec.describe "icon rendering", type: :model do
  it "keeps every hand-written svg inside the icon component and the Google button" do
    files_with_hand_written_svg = Dir["app/**/*.rb"].select { |path| File.read(path).include?("svg(") }

    expect(files_with_hand_written_svg).to contain_exactly("app/components/icon.rb", "app/components/client/google_button.rb")
  end
end
