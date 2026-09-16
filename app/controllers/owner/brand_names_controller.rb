class Owner::BrandNamesController < Owner::BrandQuestionsController
  self.question_body = Components::Owner::BrandQuestion::Name

  private

  def edit_path = edit_owner_brand_name_path

  def tenant_attrs = params.require(:tenant).permit(:name)
end
