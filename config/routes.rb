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

  resources :users, path: 'usuarios', only: [:index, :show, :edit, :update, :destroy] do
    get :pontuacao, on: :collection
  end

  get "/perfil", to: "users#perfil", as: :perfil
  get "/perfil/editar", to: "users#edit_perfil", as: :edit_perfil
  patch "/perfil", to: "users#update_perfil"

  post "/checkout/stripe", to: "checkout#stripe"
  post "/checkout/mercado_pago/pix", to: "checkout#mercado_pago_pix"
  post "/checkout/mercado_pago/pix_direto", to: "checkout#mercado_pago_pix_direto", as: :checkout_mercado_pago_pix_direto
  get "/checkout/pix/:id", to: "checkout#pix", as: :checkout_pix
  get "/checkout/sucesso", to: "checkout#sucesso", as: :checkout_sucesso
  post "/stripe/webhook", to: "stripe_webhooks#create"
  post "/mercado_pago/webhook", to: "mercado_pago_webhooks#create", as: :mercado_pago_webhook

  get 'checkout/obrigado', to: 'checkout#obrigado', as: :checkout_obrigado

  get  '/password/forgot', to: 'passwords#new', as: :new_password
  post '/password/forgot', to: 'passwords#request_recovery', as: :password_recovery

  get   '/password/reset/:token', to: 'passwords#edit',   as: :edit_password
  patch '/password/reset/:token', to: 'passwords#update'

  post '/ligas/:id/aceitar_admin', to: 'ligas#accept_admin', as: :aceitar_admin_liga
  post '/ligas/:id/recusar_admin', to: 'ligas#recuse_admin', as: :recusar_admin_liga

  resources :ligas do
    collection do
      get :publicas
    end
    member do
      get :preview
      post :set_admin
      post :accept_invite
      post :recuse_invite
      post :invite_member
      post :join
      match :remove_member, via: [:delete, :patch]
      delete :quit
    end
  end

  resources :pagamentos, only: [:index]

  get '/planos', to: 'assinaturas#index', as: :planos
  get '/convite/:token', to: 'liga_convites#show', as: :liga_convite
  post '/convite/:token/aceitar', to: 'liga_convites#accept', as: :aceitar_liga_convite
  
  resources :jogos do
    member do
      patch :start
      get :finalize
      patch :finish
    end
  end

  resources :grupos
  resources :selecoes

  get '/termos', to: 'static_pages#termos', as: :termos
  get '/privacidade', to: 'static_pages#privacidade', as: :privacidade
  match '/aceitar-termos', to: 'static_pages#aceitar_termos', as: :aceitar_termos, via: [:get, :post]

  get "up" => "rails/health#show", as: :rails_health_check
end
