class Owner::PasswordResetsController < ApplicationController
  include Owner::SessionStart

  CONFIRMATION = "Se houver uma conta com esse e-mail neste estabelecimento, enviamos o link para escolher uma nova senha.".freeze
  REFUSED = "Este link expirou. Entre com seu e-mail e senha ou peça um novo link.".freeze

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

  def edit
    owner = owner_from_token
    return redirect_to(new_owner_session_path, alert: REFUSED) unless owner

    render Views::Owner::PasswordResets::Edit.new(branding: current_branding, user: owner, token: params[:token])
  end

  def update
    owner = owner_from_token
    return redirect_to(new_owner_session_path, alert: REFUSED) unless owner

    if owner.reset_password(params[:password])
      start_owner_session(owner)
    else
      render Views::Owner::PasswordResets::Edit.new(branding: current_branding, user: owner, token: params[:token]),
        status: :unprocessable_entity
    end
  end

  private

  def owner_from_token
    user = User.find_by_password_reset_token(params[:token])
    user if user&.owner? && user.tenant_id == ActsAsTenant.current_tenant&.id
  end
end
