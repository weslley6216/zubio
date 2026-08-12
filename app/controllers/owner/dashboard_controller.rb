class Owner::DashboardController < Owner::BaseController
  def show
    render Views::Owner::Dashboard::Show.new(branding: current_branding)
  end
end
