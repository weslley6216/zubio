require "rails_helper"

RSpec.describe "Active Storage service configuration" do
  let(:storage_config) { ActiveSupport::ConfigurationFile.parse(Rails.root.join("config/storage.yml")) }

  it "points production at the Supabase service instead of the ephemeral local disk" do
    production_config = Rails.root.join("config/environments/production.rb").read

    expect(production_config).to match(/^\s*config\.active_storage\.service = :supabase$/)
    expect(production_config).not_to match(/^\s*config\.active_storage\.service = :local$/)
  end

  it "configures the supabase service as S3 on a path-style custom endpoint" do
    supabase = storage_config["supabase"]

    expect(supabase["service"]).to eq("S3")
    expect(supabase["force_path_style"]).to be(true)
    expect(supabase["public"]).to be(false)
    expect(supabase).to include("endpoint", "region", "bucket", "access_key_id", "secret_access_key")
  end

  it "keeps development and test on local disk so the suite never touches the network" do
    development_config = Rails.root.join("config/environments/development.rb").read
    test_config = Rails.root.join("config/environments/test.rb").read

    expect(development_config).to match(/^\s*config\.active_storage\.service = :local$/)
    expect(test_config).to match(/^\s*config\.active_storage\.service = :test$/)
    expect(storage_config["local"]["service"]).to eq("Disk")
    expect(storage_config["test"]["service"]).to eq("Disk")
  end
end
