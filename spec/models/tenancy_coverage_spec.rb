require "rails_helper"

RSpec.describe "Tenancy coverage", type: :model do
  EXEMPT = %w[Tenant ApplicationRecord].freeze

  it "every model with tenant_id declares acts_as_tenant" do
    Rails.application.eager_load!

    offenders = ApplicationRecord.descendants.reject do |model|
      EXEMPT.include?(model.name) ||
        !model.column_names.include?("tenant_id") ||
        model.respond_to?(:scoped_by_tenant?)
    end

    expect(offenders).to be_empty, "Models with tenant_id but no acts_as_tenant: #{offenders.map(&:name).join(', ')}"
  end

  it "every business table has tenant_id" do
    infra = %w[schema_migrations ar_internal_metadata tenants
               active_storage_blobs active_storage_attachments
               active_storage_variant_records solid_queue_jobs]

    missing = (ActiveRecord::Base.connection.tables - infra).reject do |table|
      ActiveRecord::Base.connection.column_exists?(table, :tenant_id)
    end

    expect(missing).to be_empty, "Tables without tenant_id: #{missing.join(', ')}"
  end
end
