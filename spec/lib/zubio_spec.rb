require "rails_helper"

RSpec.describe Zubio do
  describe ".origin_from" do
    it "reduces an endpoint to scheme and host" do
      expect(described_class.origin_from("https://abcxyz.storage.supabase.co")).to eq("https://abcxyz.storage.supabase.co")
    end

    it "keeps a non-default port" do
      expect(described_class.origin_from("http://localhost:9000")).to eq("http://localhost:9000")
    end

    it "returns nothing for a blank endpoint" do
      expect(described_class.origin_from(nil)).to be_nil
    end
  end
end
