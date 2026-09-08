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

  # A GET that opens a session is reachable from an <img> or a prefetch, which
  # is how login CSRF rides a victim's browser. Fetch Metadata makes the browser
  # say what the request is for, and the browser will not let a page forge it.
  # The legitimate caller is always a top-level navigation from the signup
  # redirect, which is same-site. An absent header means the caller is not a
  # browser, and a non-browser caller has no victim's session to ride.
  #
  # This is why the signup form carries data-turbo="false": under Turbo the
  # redirect would be followed by fetch, arriving here as "empty", and every
  # signup would end on the login form instead of the dashboard.
  def navigation?
    request.headers["Sec-Fetch-Dest"].in?([ nil, "document" ]) &&
      request.headers["Sec-Fetch-Site"].in?(SAFE_SITES)
  end
end
