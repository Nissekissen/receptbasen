Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  resources :recipes, only: [ :index, :new, :create, :show, :destroy ] do
    member do
      post :extract_tags
    end
  end
  resources :saved_recipes, only: [ :create, :destroy ]
  resources :users, only: %i[new create]
  resources :collections, only: %i[index create update destroy]
  resources :groups, only: %i[index new create show edit update destroy] do
    member do
      post :join
    end
    resources :collections, only: %i[index create update destroy], controller: "group_collections"
    resources :memberships, only: %i[index update destroy], controller: "group_memberships"
    resources :invites, only: %i[index new create destroy], controller: "group_invites"
  end
  resource :profile, only: [ :show ]
  resource :manual_recipe, only: [ :new, :create ]
  get "home/index"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
  root "home#index"

  get "login", to: "sessions#new", as: :login

  get "signup", to: "users#new", as: :signup

  get "/invite/:token", to: "invites#show", as: :invite

  post "saved_recipes/toggle", to: "saved_recipes#toggle", as: :toggle_saved_recipe
end
