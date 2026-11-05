class Branding::PreviewSheet
  def initialize(bg:, accent:)
    @bg = bg
    @accent = accent
  end

  def stylesheet
    bg_rule + accent_rule
  end

  private

  def bg_rule
    return "" if @bg.blank?

    %([data-preview-bg="#{@bg}"]{#{Branding::Theme.background_variables(@bg)}})
  end

  def accent_rule
    return "" if @accent.blank?

    %([data-preview-accent="#{@accent}"]{#{Branding::Theme.accent_variables(@accent)}})
  end
end
