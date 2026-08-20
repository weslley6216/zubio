class Owner::DomainsController < Owner::BaseController
  def edit
    @tenant = ActsAsTenant.current_tenant

    render Views::Owner::Domains::Edit.new(tenant: @tenant)
  end

  def update
    @tenant = ActsAsTenant.current_tenant

    if remove_domain?
      @tenant.remove_custom_domain!
    else
      @tenant.register_custom_domain!(domain_params[:custom_domain])
    end

    redirect_to edit_owner_domain_path, notice: "Domínio atualizado."
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    render Views::Owner::Domains::Edit.new(tenant: @tenant), status: :unprocessable_entity
  end

  private

  def remove_domain?
    ActiveModel::Type::Boolean.new.cast(params.dig(:domain, :remove_domain))
  end

  def domain_params = params.require(:domain).permit(:custom_domain)
end
