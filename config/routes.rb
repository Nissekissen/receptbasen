Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  resources :recipes, only: [ :index, :new, :create, :show, :destroy ] do
    member do
      post :extract_tags
      post :add_to_shopping_list
      get :cook
      post :log_cook
    end
    resource :note, only: [ :create ], controller: "recipe_notes"
  end
  resources :saved_recipes, only: [ :create, :destroy ]
  resources :users, only: %i[new create]
  resources :collections, only: %i[index show create update destroy] do
    resources :collaborators, only: %i[create update destroy], controller: "collection_collaborators" do
      collection do
        get :search
      end
    end
  end
  resources :shopping_list_items, only: %i[index create update destroy], path: "shopping-list" do
    collection do
      delete :destroy_all
    end
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

  get "utforska", to: "explore#index", as: :explore

  get "login", to: "sessions#new", as: :login

  get "signup", to: "users#new", as: :signup

  post "saved_recipes/toggle", to: "saved_recipes#toggle", as: :toggle_saved_recipe
end
