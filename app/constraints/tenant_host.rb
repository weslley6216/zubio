class TenantHost
  def self.matches?(request)
    !Tenant.platform_root_host?(request) && !Tenant.www_host?(request)
  end
end
