class Owner::BrandLogosController < Owner::BrandQuestionsController
  self.question_body = Components::Owner::BrandQuestion::Logo

  private

  def edit_path = edit_owner_brand_logo_path

  def submit_path = owner_brand_logo_path

  def branding_attrs = params.require(:branding).permit(:logo)

  def remove_logo? = ActiveModel::Type::Boolean.new.cast(params.dig(:branding, :remove_logo))
end
