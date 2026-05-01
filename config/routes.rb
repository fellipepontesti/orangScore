Rails.application.routes.draw do
  devise_for :users, path: "", path_names: {
    sign_in: "login",
    sign_out: "logout"
  }

  authenticated :user do
    root to: "dashboard#index", as: :authenticated_root
  end

  unauthenticated do
    devise_scope :user do
      root to: "devise/sessions#new"
    end
  end

  resources :palpites

  resources :notificacoes do
    member do
      patch :accept_admin_invite
      patch :reject_admin_invite
    end
  end

  resources :users, path: 'usuarios', only: [:index, :show, :edit, :update, :destroy]

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
  
  resources :jogos do
    member do
      patch :start
      get :finalize
      patch :finish
    end
  end

  resources :grupos
  resources :selecoes

  get "up" => "rails/health#show", as: :rails_health_check
end