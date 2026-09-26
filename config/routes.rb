Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  get "manifest.webmanifest" => "pwa#manifest", as: :pwa_manifest
  get "service-worker.js" => "pwa#service_worker", as: :pwa_service_worker

  post "/rails/active_storage/direct_uploads" => "direct_uploads#create", as: :authenticated_direct_uploads

  get "branding.css" => "stylesheets#branding", as: :branding_stylesheet
  get "showcase.css" => "stylesheets#showcase", as: :showcase_stylesheet
  get "palette.css" => "stylesheets#palette", as: :palette_stylesheet

  resource :signup, only: %i[new create]

  namespace :owner do
    resource :onboarding, only: %i[show create], controller: "onboarding"
    namespace :onboarding do
      resource :final, only: :show, controller: "final"
    end

    resource :session, only: %i[new create destroy]
    resource :handoff, only: :show
    resource :dashboard, only: :show, controller: "dashboard"
    resources :services, only: %i[index new create edit update]
    resource :brand_colors, only: %i[edit update]
    resource :brand_name, only: %i[edit update]
    resource :brand_logo, only: %i[edit update]
    resource :settings, only: :show
    resource :working_hours, only: %i[edit update]
  end

  root "pages#home"
end
