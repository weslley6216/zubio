class Owner::BrandColorsController < Owner::BrandQuestionsController
  self.question_body = Components::Owner::BrandQuestion::Colors

  private

  def edit_path = edit_owner_brand_colors_path

  def page_stylesheet = palette_stylesheet_path(v: Branding::Palette.stylesheet_digest)

  def branding_attrs
    submitted = params.require(:branding).permit(:brand_600, :brand_600_custom, :brand_secondary_600, :brand_secondary_600_custom)

    resolved_color(submitted, :brand_600).merge(resolved_color(submitted, :brand_secondary_600))
  end

  def resolved_color(submitted, attribute)
    return {} unless submitted.key?(attribute)

    { attribute => Branding.resolve_color(submitted[attribute], submitted[:"#{attribute}_custom"]) }
  end
end
