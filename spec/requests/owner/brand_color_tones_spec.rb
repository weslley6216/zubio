require "rails_helper"

RSpec.describe "Owner brand color tones", type: :request do
  let(:tenant) { create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé") }
  let(:owner) { create(:user, tenant: tenant, name: "José Souza", email: "ze@example.com", password: "s3cr3t123") }

  describe "GET /owner/brand_color_tones" do
    it "redirects to login when there is no owner session" do
      host! "#{tenant.subdomain}.zubio.com.br"

      get owner_brand_color_tones_path(role: "brand_600", bg: "#0000FF", hue: 0)

      expect(response).to redirect_to(new_owner_session_path)
    end

    it "responds for an authenticated owner" do
      sign_in_owner(owner)

      get owner_brand_color_tones_path(role: "brand_600", bg: "#0000FF", hue: 0)

      expect(response).to have_http_status(:ok)
    end

    it "responds even while the owner's onboarding gate is still open" do
      tenant = create(:tenant, :onboarding, subdomain: "aberta", name: "Aberta")
      owner = create(:user, tenant: tenant, name: "Dono", email: "dono@example.com", password: "s3cr3t123")
      sign_in_owner(owner)

      get owner_brand_color_tones_path(role: "brand_600", bg: "#0000FF", hue: 0)

      expect(response).to have_http_status(:ok)
      expect(response).not_to be_redirect
    end

    it "returns only valid tones for the requested hue, as a tones turbo frame" do
      sign_in_owner(owner)

      get owner_brand_color_tones_path(role: "brand_600", bg: "#0000FF", hue: 0)

      document = Nokogiri::HTML5.fragment(response.body)
      expect(document.at_css(%(turbo-frame#tones-brand_600))).to be_present
      expect(response.body).not_to include(%(value="#FF0000"))
      document.css(%(input[type="radio"])).each do |radio|
        tones = Branding::Tones.new(role: :brand_600, background: "#0000FF")

        expect(tones.valid?(radio["value"])).to be true
      end
    end

    it "advertises the nearest valid tone, selected, when given an invalid hex instead of a hue" do
      sign_in_owner(owner)

      get owner_brand_color_tones_path(role: "brand_600", bg: "#0000FF", hex: "#FF0000")

      document = Nokogiri::HTML5.fragment(response.body)
      checked = document.at_css(%(input[type="radio"][checked]))
      expect(checked).to be_present
      expect(checked["value"]).not_to eq("#FF0000")
      expect(document.at_css(%([data-tone-advice]))).to be_present
    end

    it "does not advertise an adjustment when the given hex is already valid" do
      sign_in_owner(owner)

      get owner_brand_color_tones_path(role: "brand_600", bg: "#16324A", hex: "#F0617A")

      document = Nokogiri::HTML5.fragment(response.body)
      expect(document.at_css(%([data-tone-advice]))).to be_nil
    end

    it "caches the response publicly" do
      sign_in_owner(owner)

      get owner_brand_color_tones_path(role: "brand_600", bg: "#0000FF", hue: 0)

      expect(response.headers["Cache-Control"]).to include("public")
    end

    it "rejects an unknown role" do
      sign_in_owner(owner)

      get owner_brand_color_tones_path(role: "not_a_role", hue: 0)

      expect(response).to have_http_status(:not_found)
    end

    it "rejects a background outside the hex format" do
      sign_in_owner(owner)

      get owner_brand_color_tones_path(role: "brand_600", bg: "not-a-hex", hue: 0)

      expect(response).to have_http_status(:not_found)
    end

    it "rejects a hue outside the 0..359 range" do
      sign_in_owner(owner)

      get owner_brand_color_tones_path(role: "brand_600", bg: "#0000FF", hue: 360)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /owner/brand_accent_swatches" do
    it "returns an accent-swatches turbo frame with as many samples as the palette offers" do
      sign_in_owner(owner)

      get owner_brand_accent_swatches_path(bg: "#F6EEF2", selected: "#F0617A")

      document = Nokogiri::HTML5.fragment(response.body)
      expect(document.at_css(%(turbo-frame#accent-swatches))).to be_present
      expect(document.css(%(input[type="radio"])).size).to eq(Branding::Palette::ACCENTS.size)
    end

    it "offers only tones valid over the given background" do
      sign_in_owner(owner)

      get owner_brand_accent_swatches_path(bg: "#F6EEF2", selected: "#F0617A")

      document = Nokogiri::HTML5.fragment(response.body)
      tones = Branding::Tones.new(role: :brand_600, background: "#F6EEF2")
      document.css(%(input[type="radio"])).each do |radio|
        expect(tones.valid?(radio["value"])).to be true
      end
    end

    it "reajusts the selected accent to the nearest valid tone when the background invalidates it" do
      sign_in_owner(owner)

      get owner_brand_accent_swatches_path(bg: "#F0617A", selected: "#F0617A")

      document = Nokogiri::HTML5.fragment(response.body)
      checked = document.at_css(%(input[type="radio"][checked]))
      expect(checked).to be_present
      expect(checked["value"]).not_to eq("#F0617A")
    end

    it "caches the response publicly" do
      sign_in_owner(owner)

      get owner_brand_accent_swatches_path(bg: "#F6EEF2", selected: "#F0617A")

      expect(response.headers["Cache-Control"]).to include("public")
    end
  end
end
