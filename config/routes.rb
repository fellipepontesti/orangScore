Rails.application.routes.draw do
  root to: "dashboard#index"

  resources :palpites
  resources :notificacoes do
    member do
      patch :accept_admin_invite
      patch :reject_admin_invite
    end
  end

  devise_for :users
  get  '/password/forgot', to: 'passwords#new', as: :new_password
  post '/password/forgot', to: 'passwords#request_recovery', as: :password_recovery

  get   '/password/reset/:token', to: 'passwords#edit',   as: :edit_password
  patch '/password/reset/:token', to: 'passwords#update'
  post '/ligas/:id/aceitar_admin', to: 'ligas#accept_admin', as: :aceitar_admin_liga
  post '/ligas/:id/recusar_admin', to: 'ligas#recuse_admin', as: :recusar_admin_liga

  resources :ligas do
      member do
        post :set_admin
        post :accept_invite
        post :recuse_invite
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
