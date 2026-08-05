module Owner
  class BaseController < ApplicationController
    before_action :require_owner!

    private

    def require_owner!
      redirect_to root_path unless current_user&.owner?
    end
  end
end

module Owner
  class ChangeMesController < BaseController
    def create
      change_me = current_tenant.change_mes.new(change_me_params)

      if change_me.save
        redirect_to owner_change_mes_path, notice: t(".success")
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

    def change_me_params
      params.require(:change_me).permit(:name)
    end
  end
end
