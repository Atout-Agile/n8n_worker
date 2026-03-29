Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :tokens, only: [:index, :new, :create, :show, :destroy] do
        member do
          patch :revoke
          patch :renew
        end
      end
    end
  end
  
  # Admin routes
  namespace :admin do
    resources :roles, only: [:index, :edit, :update]
  end

  # Authentication routes
  get '/login', to: 'sessions#new', as: 'login'
  post '/sessions', to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy', as: 'logout'
  
  # Dashboard (protected)
  get '/dashboard', to: 'dashboard#index', as: 'dashboard'
  
  # Root path
  root 'home#index'
  
  # GraphQL endpoint
  post "/graphql", to: "graphql#execute"
  
  # GraphiQL in development
  if Rails.env.development?
    mount GraphiQL::Rails::Engine, at: "/graphiql", graphql_path: "/graphql"
  end
  
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
