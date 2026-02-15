Rails.application.routes.draw do
  root to: "dashboard#index"

  devise_for :users
  get  '/password/forgot', to: 'passwords#new', as: :new_password
  post '/password/forgot', to: 'passwords#request_recovery', as: :password_recovery

  get   '/password/reset/:token', to: 'passwords#edit',   as: :edit_password
  patch '/password/reset/:token', to: 'passwords#update'

  resources :ligas do
      member do
        post :invite_member
        match :remove_member, via: [:delete, :patch]
        delete :quit
      end
  end
  
  resources :jogos
  resources :grupos
  resources :selecoes
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.

  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
