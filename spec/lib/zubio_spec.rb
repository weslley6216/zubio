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

  describe ".google_oauth_credentials" do
    it "demands GOOGLE_CLIENT_ID in production, naming the missing variable" do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
      allow(ENV).to receive(:fetch).with("GOOGLE_CLIENT_ID").and_raise(KeyError.new(%(key not found: "GOOGLE_CLIENT_ID")))

      expect { described_class.google_oauth_credentials }.to raise_error(KeyError, /GOOGLE_CLIENT_ID/)
    end

    it "demands GOOGLE_CLIENT_SECRET in production, naming the missing variable" do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
      allow(ENV).to receive(:fetch).with("GOOGLE_CLIENT_ID").and_return("client-id")
      allow(ENV).to receive(:fetch).with("GOOGLE_CLIENT_SECRET").and_raise(KeyError.new(%(key not found: "GOOGLE_CLIENT_SECRET")))

      expect { described_class.google_oauth_credentials }.to raise_error(KeyError, /GOOGLE_CLIENT_SECRET/)
    end

    it "reads the credentials leniently outside production, tolerating their absence" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("GOOGLE_CLIENT_ID").and_return(nil)
      allow(ENV).to receive(:[]).with("GOOGLE_CLIENT_SECRET").and_return(nil)

      expect(described_class.google_oauth_credentials).to eq([ nil, nil ])
    end
  end
end
