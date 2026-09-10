class Owner::HandoffsController < ApplicationController
  include Owner::SessionStart

  REFUSED = "Este link expirou. Entre com seu e-mail e senha.".freeze
  SAFE_SITES = [ nil, "same-site", "same-origin", "none" ].freeze

  def show
    return redirect_to(new_owner_session_path, alert: REFUSED) unless navigation?

    user = User.find_by_handoff_token(params[:token])

    if user&.owner? && user.tenant_id == ActsAsTenant.current_tenant&.id
      user.consume_handoff_token!
      start_owner_session(user)
    else
      redirect_to new_owner_session_path, alert: REFUSED
    end
  end

  private

  def navigation?
    request.headers["Sec-Fetch-Dest"].in?([ nil, "document" ]) &&
      request.headers["Sec-Fetch-Site"].in?(SAFE_SITES)
  end
end
