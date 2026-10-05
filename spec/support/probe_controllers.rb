class LayoutProbeController < ApplicationController
  def show
    render Views::Layouts::Application.new(title: "Zubio", branding: ActsAsTenant.current_tenant.branding_or_default)
  end
end

class CacheKeyPrefixProbeController < ApplicationController
  def show
    render plain: cache_key_prefix
  end
end

class TenantResolutionProbeController < ApplicationController
  def show
    render plain: ActsAsTenant.current_tenant.subdomain
  end
end
