Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  get "health" => "health#show", as: :health_check

  # Auth
  get  "login",    to: "sessions#new",    as: :login
  post "login",    to: "sessions#create"
  delete "logout", to: "sessions#destroy", as: :logout
  get  "signup",   to: "registrations#new",   as: :signup
  post "signup",   to: "registrations#create"

  # Dashboard
  root "dashboard#index"

  # Organizations
  resources :organizations, param: :slug, only: [ :new, :create, :show, :edit, :update, :destroy ] do
    resources :projects do
      resources :webhook_endpoints, as: :endpoints do
        member do
          post :toggle
          post :rotate_secret
          get  :test
          post :test
        end
      end
      resources :events, only: [ :index, :show ]
      resources :deliveries, only: [ :index, :show ] do
        member do
          post :retry
        end
      end
      resources :api_keys, only: [ :index, :create, :destroy ]
    end
  end

  # Public REST API
  namespace :api do
    namespace :v1 do
      post "projects/:project_id/events", to: "events#create"
    end
  end

  # Sidekiq Web UI (development only)
  require "sidekiq/web"
  mount Sidekiq::Web => "/sidekiq" if Rails.env.development?
end
