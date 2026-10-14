class Owner::PasswordResetsController < ApplicationController
  include Owner::SessionStart

  CONFIRMATION = "Se houver uma conta com esse e-mail neste estabelecimento, enviamos o link para escolher uma nova senha.".freeze

  rate_limit to: 5, within: 1.hour, only: :create, name: "password_reset",
    with: -> { redirect_to new_owner_password_reset_path, alert: "Muitas tentativas. Tente novamente mais tarde." }

  def new
    render Views::Owner::PasswordResets::New.new(branding: current_branding)
  end

  def create
    owner = User.owner.find_by(email: params[:email].to_s)
    OwnerMailer.password_reset(owner.tenant_id, owner.id, owner.issue_password_reset_token!).deliver_later if owner

    redirect_to new_owner_password_reset_path, notice: CONFIRMATION
  end
end
