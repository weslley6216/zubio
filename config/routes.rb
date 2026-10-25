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
  get "preview.css" => "stylesheets#preview", as: :preview_stylesheet

  resource :signup, only: %i[new create]
  resource :login_link, only: %i[new create]

  get "/entrar/google", to: "client/auth/omniauth#new", as: :google_entry
  get "/auth/:provider/callback", to: "client/auth/omniauth#callback"
  get "/auth/failure", to: "client/auth/omniauth#failure"

  namespace :owner do
    resource :onboarding, only: %i[show create], controller: "onboarding"
    namespace :onboarding do
      resource :final, only: :show, controller: "final"
    end

    resource :session, only: %i[new create destroy]
    resource :handoff, only: :show
    resource :password_reset, only: %i[new create edit update]
    resources :appointments, only: %i[index show] do
      resource :cancellation, only: :create, module: :appointments
      resource :completion, only: :create, module: :appointments
      resource :no_show, only: :create, module: :appointments
    end
    resources :services, only: %i[index new create edit update]
    resources :clients, only: :index
    resource :brand_colors, only: %i[edit update]
    resource :brand_name, only: %i[edit update]
    resource :brand_logo, only: %i[edit update]
    resource :settings, only: :show
    resource :working_hours, only: %i[edit update]
    resources :schedule_exceptions, only: %i[index create destroy]
  end

  constraints TenantHost do
    root to: "client/establishments#show", as: :establishment
    scope module: :client, as: :client do
      resource :session, only: %i[new destroy]
      resource :handoff, only: :show
      resource :account_phone, only: %i[new create]
      resources :services, only: [] do
        resource :booking, only: %i[new create]
      end
      get "meus-agendamentos", to: "my_appointments#index", as: :my_appointments
      get "a/:token", to: "appointments#show", as: :appointment
      scope "a/:token", module: :appointments do
        resource :cancellation, only: %i[new create]
      end
    end
  end

  root "pages#home"
end
