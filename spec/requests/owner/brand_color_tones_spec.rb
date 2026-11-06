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

    it "answers the same tones on any establishment's host, reading nothing of its brand" do
      aurora = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
      create(:branding, tenant: aurora, brand_600: "#F2B33D", brand_background: "#1F4D3A")
      create(:branding, :with_background, tenant: tenant)
      sign_in_owner(create(:user, tenant: aurora, email: "ana@example.com", password: "s3cr3t123"))
      get owner_brand_color_tones_path(role: "brand_600", bg: "#0000FF", hue: 0)
      on_aurora = response.body
      sign_in_owner(owner)

      get owner_brand_color_tones_path(role: "brand_600", bg: "#0000FF", hue: 0)

      expect(response.body).to eq(on_aurora)
      expect(response.body).to include("data-tone=")
      expect(response.body).not_to include("#F2B33D", "#1F4D3A", "#16324A", "#F0617A")
    end

    it "brings the swatch sheet that colors the tones it returns" do
      sign_in_owner(owner)

      get owner_brand_color_tones_path(role: "brand_600", bg: "#0000FF", hue: 0)

      document = Nokogiri::HTML5.fragment(response.body)
      tones = document.css("[data-tone]").map { |radio| radio["value"] }
      expect(document.at_css("turbo-frame#tones-brand_600 link[rel=stylesheet]")["href"]).to eq("/swatches.css?colors=#{Branding::SwatchSheet.param(tones)}")
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

    it "checks the adjusted tone among the offered ones when the typed hex has a fractional hue" do
      sign_in_owner(owner)

      get owner_brand_color_tones_path(role: "brand_600", bg: "#F6EEF2", hex: "#F0617A")

      document = Nokogiri::HTML5.fragment(response.body)
      expect(document.at_css(%(input[type="radio"][checked]))["value"]).to eq(Branding::Tones.new(role: :brand_600, background: "#F6EEF2").nearest_valid("#F0617A"))
      expect(document.at_css(%([data-tone-advice]))).to be_present
    end

    it "tells the hue of a typed hex, so the hue bar can follow the code" do
      sign_in_owner(owner)

      get owner_brand_color_tones_path(role: "brand_600", bg: "#F6EEF2", hex: "#F0617A")

      document = Nokogiri::HTML5.fragment(response.body)
      expect(document.at_css("[data-tone-row]")["data-tone-hue"]).to eq(Branding::Tones.hue_of("#F0617A").to_s)
    end

    it "does not tell a hue back when the hue bar asked for it" do
      sign_in_owner(owner)

      get owner_brand_color_tones_path(role: "brand_600", bg: "#0000FF", hue: 0)

      document = Nokogiri::HTML5.fragment(response.body)
      expect(document.at_css("[data-tone-row]")["data-tone-hue"]).to be_nil
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

    it "keeps each sample's palette slot, so a second background change still finds the chosen one" do
      sign_in_owner(owner)

      get owner_brand_accent_swatches_path(bg: "#F0617A", selected: "#F0617A")

      document = Nokogiri::HTML5.fragment(response.body)
      expect(document.css(%(input[type="radio"])).map { |radio| radio["data-accent"] }).to eq(Branding::Palette::ACCENTS)
      expect(document.at_css("turbo-frame#accent-swatches link[rel=stylesheet]")["href"]).to start_with("/swatches.css?colors=")
    end

    it "caches the response publicly" do
      sign_in_owner(owner)

      get owner_brand_accent_swatches_path(bg: "#F6EEF2", selected: "#F0617A")

      expect(response.headers["Cache-Control"]).to include("public")
    end
  end
end
