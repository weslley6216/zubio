class CloudflareCustomHostname
  BASE_URL = "https://api.cloudflare.com/client/v4"
  Result = Struct.new(:id, :status, :verification_txt_name, :verification_txt_value, keyword_init: true)

  def initialize(zone_id: ENV["CLOUDFLARE_ZONE_ID"], api_token: ENV["CLOUDFLARE_API_TOKEN"])
    @zone_id = zone_id
    @api_token = api_token
  end

  def create(hostname)
    result = request(Net::HTTP::Post, "/custom_hostnames", body: { hostname: hostname, ssl: { method: "txt" } })

    Result.new(
      id: result["id"],
      status: result["status"],
      verification_txt_name: result["ownership_verification"]["name"],
      verification_txt_value: result["ownership_verification"]["value"]
    )
  end

  def status(cloudflare_id)
    request(Net::HTTP::Get, "/custom_hostnames/#{cloudflare_id}")["status"]
  end

  def delete(cloudflare_id)
    request(Net::HTTP::Delete, "/custom_hostnames/#{cloudflare_id}")
  end

  private

  def request(http_method_class, path, body: nil)
    uri = URI("#{BASE_URL}/zones/#{@zone_id}#{path}")
    http_request = http_method_class.new(uri)
    http_request["Authorization"] = "Bearer #{@api_token}"
    http_request["Content-Type"] = "application/json"
    http_request.body = body.to_json if body

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(http_request) }
    JSON.parse(response.body)["result"]
  end
end
