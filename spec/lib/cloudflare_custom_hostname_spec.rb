require "rails_helper"

RSpec.describe CloudflareCustomHostname do
  let(:client) { described_class.new(zone_id: "zone-123", api_token: "token-abc") }

  describe "#create" do
    it "creates a custom hostname and returns the ownership verification record" do
      stub_request(:post, "https://api.cloudflare.com/client/v4/zones/zone-123/custom_hostnames")
        .with(
          body: { hostname: "barbeariadoze.com.br", ssl: { method: "txt" } }.to_json,
          headers: { "Authorization" => "Bearer token-abc", "Content-Type" => "application/json" }
        )
        .to_return(
          status: 200,
          body: {
            success: true,
            result: {
              id: "cf-hostname-id",
              status: "pending",
              ownership_verification: {
                name: "_cf-custom-hostname.barbeariadoze.com.br",
                value: "cf-verification-token"
              }
            }
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = client.create("barbeariadoze.com.br")

      expect(result).to have_attributes(
        id: "cf-hostname-id",
        status: "pending",
        verification_txt_name: "_cf-custom-hostname.barbeariadoze.com.br",
        verification_txt_value: "cf-verification-token"
      )
    end
  end

  describe "#status" do
    it "returns the hostname's current status" do
      stub_request(:get, "https://api.cloudflare.com/client/v4/zones/zone-123/custom_hostnames/cf-hostname-id")
        .to_return(
          status: 200,
          body: { success: true, result: { status: "active" } }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect(client.status("cf-hostname-id")).to eq("active")
    end
  end

  describe "#delete" do
    it "deletes the custom hostname" do
      request_stub = stub_request(:delete, "https://api.cloudflare.com/client/v4/zones/zone-123/custom_hostnames/cf-hostname-id")
        .to_return(status: 200, body: { success: true, result: { id: "cf-hostname-id" } }.to_json)

      client.delete("cf-hostname-id")

      expect(request_stub).to have_been_requested
    end
  end
end
