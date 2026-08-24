Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  get "manifest.webmanifest" => "pwa#manifest", as: :pwa_manifest
  get "service-worker.js" => "pwa#service_worker", as: :pwa_service_worker

  resource :signup, only: %i[new create]

  namespace :owner do
    resource :session, only: %i[new create destroy]
    resource :dashboard, only: :show, controller: "dashboard"
    resource :branding, only: %i[edit update]
  end

  root "pages#home"
end
