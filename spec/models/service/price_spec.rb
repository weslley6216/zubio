require "rails_helper"

RSpec.describe Service::Price do
  describe ".parse" do
    {
      "90" => 9_000,
      "90,00" => 9_000,
      "90,5" => 9_050,
      "90.5" => 9_050,
      "90.50" => 9_050,
      "1.234,56" => 123_456,
      "1234,56" => 123_456,
      "1234.56" => 123_456,
      "1.500" => 150_000,
      "1.234.567,89" => 123_456_789,
      "R$ 90,00" => 9_000,
      "R$90,00" => 9_000,
      "R$\u00A090,00" => 9_000,
      "  90,00  " => 9_000,
      "\u00A090,00\u00A0" => 9_000,
      "0,00" => 0
    }.each do |text, cents|
      it "reads #{text.dump} as #{cents} cents" do
        expect(described_class.parse(text).cents).to eq(cents)
      end
    end

    [
      "noventa", "1.23,45", "90,555", "-90", "90,", ",50", "R$", "", "   ",
      "9 0", "12.345.67", "1234.567", "90,00 reais", "R$ -90,00", "９０"
    ].each do |text|
      it "refuses #{text.dump} instead of guessing a value" do
        expect(described_class.parse(text)).to be_nil
      end
    end

    it "refuses nothing at all" do
      expect(described_class.parse(nil)).to be_nil
    end
  end

  describe "#to_s" do
    {
      0 => "0,00",
      5 => "0,05",
      50 => "0,50",
      9_000 => "90,00",
      123_456 => "1.234,56",
      9_999_999 => "99.999,99"
    }.each do |cents, text|
      it "writes #{cents} cents as #{text.dump}" do
        expect(described_class.new(cents).to_s).to eq(text)
      end
    end
  end

  describe "#with_currency" do
    it "puts the currency ahead of the amount" do
      expect(described_class.new(9_000).with_currency).to eq("R$ 90,00")
    end
  end

  describe ".label" do
    it "shows a stored price with the currency" do
      expect(described_class.label(9_000)).to eq("R$ 90,00")
    end

    it "shows a price of zero as a price, not as sob consulta" do
      expect(described_class.label(0)).to eq("R$ 0,00")
    end

    it "shows a service with no price as sob consulta" do
      expect(described_class.label(nil)).to eq("Sob consulta")
    end
  end

  describe "round trip" do
    [ 0, 5, 50, 9_000, 9_050, 123_456, 9_999_999 ].each do |cents|
      it "reads #{cents} cents back from the text it wrote, with or without the currency" do
        price = described_class.new(cents)

        expect(described_class.parse(price.to_s).cents).to eq(cents)
        expect(described_class.parse(price.with_currency).cents).to eq(cents)
      end
    end
  end
end
