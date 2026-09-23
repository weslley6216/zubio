require "rails_helper"

RSpec.describe Service::Duration do
  describe ".label" do
    {
      5 => "5 min",
      30 => "30 min",
      45 => "45 min",
      60 => "1 h",
      90 => "1 h 30 min",
      120 => "2 h",
      480 => "8 h"
    }.each do |minutes, label|
      it "formats #{minutes} minutes as #{label.inspect}" do
        expect(described_class.label(minutes)).to eq(label)
      end
    end
  end
end
