module Owner::ColorSubmission
  extend ActiveSupport::Concern

  private

  def submitted_colors
    @submitted_colors ||= params.require(:branding).permit(:brand_600, :brand_600_custom, :brand_secondary_600, :brand_secondary_600_custom)
  end

  def color_attrs
    resolved_color(:brand_600).merge(resolved_color(:brand_secondary_600))
  end

  def resolved_color(attribute)
    return {} unless submitted_colors.key?(attribute)

    { attribute => Branding.resolve_color(submitted_colors[attribute], submitted_colors[:"#{attribute}_custom"]) }
  end
end
