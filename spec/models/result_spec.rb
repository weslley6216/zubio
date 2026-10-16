require "rails_helper"

RSpec.describe Result do
  it "a success carries its value and answers success?" do
    result = Result::Success.new(:appointment)

    expect([ result.success?, result.failure?, result.value ]).to eq([ true, false, :appointment ])
  end

  it "a failure carries its reason and answers failure?" do
    result = Result::Failure.new(:taken)

    expect([ result.failure?, result.success?, result.reason, result.record ]).to eq([ true, false, :taken, nil ])
  end

  it "a failure can carry the rejected record for field errors" do
    record = Object.new

    result = Result::Failure.new(:invalid_client, record: record)

    expect(result.record).to be(record)
  end
end
