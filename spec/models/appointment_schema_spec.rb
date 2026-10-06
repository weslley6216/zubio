require "rails_helper"

RSpec.describe "appointments schema", type: :model do
  it "enables the btree_gist extension" do
    expect(ActiveRecord::Base.connection.extensions).to include("btree_gist")
  end

  it "keeps the positive-duration check constraint" do
    names = ActiveRecord::Base.connection.check_constraints("appointments").map(&:name)

    expect(names).to include("appointments_positive_duration")
  end

  it "keeps the no-overlap exclusion constraint" do
    names = ActiveRecord::Base.connection.exclusion_constraints("appointments").map(&:name)

    expect(names).to include("appointments_no_overlap")
  end
end
