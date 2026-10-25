class Owner::ClientsController < Owner::BaseController
  MIN_SEARCH_DIGITS = 4

  def index
    digits = params[:phone].to_s.gsub(/\D/, "")
    searchable = digits.length >= MIN_SEARCH_DIGITS
    matches = searchable ? ActsAsTenant.current_tenant.clients.matching_phone(params[:phone]).to_a : []

    render Components::Owner::Appointments::ClientSearch.new(matches: matches, query: searchable ? params[:phone].to_s : "")
  end
end
