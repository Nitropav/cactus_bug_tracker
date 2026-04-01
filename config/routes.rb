Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  get "login", to: "sessions#new", as: :login
  delete "logout", to: "sessions#destroy", as: :logout
  resources :users, except: %i[show destroy] do
    member do
      get :reset_password
      patch :reset_password, action: :update_password
      patch :deactivate
      patch :reactivate
    end
  end
  resources :training_examples, only: %i[index show] do
    collection do
      get :export
    end
    member do
      patch :approve
      patch :reject
    end
  end
  resources :tickets do
    resource :gate_one, only: :update, controller: "ticket_gate_ones"
    resource :gate_two, only: :update, controller: "ticket_gate_twos"
    resources :comments, only: :create, controller: "ticket_comments"
    resources :commit_links, only: %i[create destroy], controller: "ticket_commits"
  end

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  resource :session, only: %i[new create destroy]
  root "home#index"
end
