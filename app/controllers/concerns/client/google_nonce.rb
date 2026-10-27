module Client::GoogleNonce
  extend ActiveSupport::Concern

  COOKIE = :client_google_nonce
  TTL = 10.minutes

  private

  def issue_google_nonce
    SecureRandom.urlsafe_base64(24).tap do |nonce|
      cookies.encrypted[COOKIE] = { value: nonce, httponly: true, expires: TTL.from_now }
    end
  end

  def consume_google_nonce(nonce)
    expected = cookies.encrypted[COOKIE]
    cookies.delete(COOKIE)
    expected.present? && nonce.present? && ActiveSupport::SecurityUtils.secure_compare(expected, nonce)
  end
end
