class Owner::BrandColorsController < Owner::BrandQuestionsController
  include Owner::ColorSubmission

  self.question_body = Components::Owner::BrandQuestion::Colors

  private

  def edit_path = edit_owner_brand_colors_path

  def submit_path = owner_brand_colors_path

  def page_stylesheet = palette_stylesheet_path(v: Branding::Palette.stylesheet_digest)

  def branding_attrs = color_attrs
end
