require "rails_helper"

RSpec.describe Service::Duration do
  describe ".label" do
    {
      5 => "5min",
      30 => "30min",
      45 => "45min",
      60 => "1h",
      90 => "1h 30min",
      120 => "2h",
      480 => "8h"
    }.each do |minutes, label|
      it "formats #{minutes} minutes as #{label.inspect}" do
        expect(described_class.label(minutes)).to eq(label)
      end
    end
  end
end
