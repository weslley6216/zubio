class Components::SocialMeta < Components::Base
  OG_TYPE = "website".freeze
  TWITTER_CARD = "summary".freeze

  def initialize(title:, description:, url:, image_url: nil)
    @title = title
    @description = description
    @url = url
    @image_url = image_url
  end

  def view_template
    meta(property: "og:title", content: @title)
    meta(property: "og:description", content: @description)
    meta(property: "og:type", content: OG_TYPE)
    meta(property: "og:url", content: @url)
    meta(property: "og:image", content: @image_url) if @image_url
    meta(name: "twitter:card", content: TWITTER_CARD)
  end
end
