module NavigationRequest
  extend ActiveSupport::Concern

  SAFE_SITES = [ nil, "same-site", "same-origin", "none" ].freeze

  private

  def navigation?
    request.headers["Sec-Fetch-Dest"].in?([ nil, "document" ]) &&
      request.headers["Sec-Fetch-Site"].in?(SAFE_SITES)
  end
end
