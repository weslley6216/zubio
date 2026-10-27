module NavigationRequest
  extend ActiveSupport::Concern

  SAFE_SITES = [ nil, "same-site", "same-origin", "none" ].freeze

  private

  def navigation? = document_request? && request.headers["Sec-Fetch-Site"].in?(SAFE_SITES)

  def document_request? = request.headers["Sec-Fetch-Dest"].in?([ nil, "document" ])
end
