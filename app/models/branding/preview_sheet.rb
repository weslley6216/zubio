class Branding::PreviewSheet
  include StylesheetProducer

  def initialize(brand:, secondary:)
    @brand = brand
    @secondary = secondary
  end

  def stylesheet
    rule("brand", @brand) + rule("secondary", @secondary)
  end

  private

  def rule(prefix, hex)
    return "" if hex.blank?

    %([data-preview-#{prefix}="#{hex}"]{#{Branding.ramp_variables(prefix, Branding::ColorScale.new(hex))}})
  end
end
