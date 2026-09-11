module StylesheetProducer
  DIGEST_LENGTH = 16

  def stylesheet_digest = Digest::SHA256.hexdigest(stylesheet).first(DIGEST_LENGTH)
end
