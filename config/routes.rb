Rails.application.routes.draw do
  devise_for :users, path: "", path_names: {
    sign_in: "login",
    sign_out: "logout"
  }, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }

  authenticated :user do
    root to: "dashboard#index", as: :authenticated_root
  end

  get "/dashboard/convites", to: "dashboard#convites_pendentes", as: :dashboard_convites_pendentes
  get "/dashboard/artilharia", to: "dashboard#artilharia", as: :dashboard_artilharia
  get "/dashboard/jogos/detalhamento", to: "dashboard#detalhamento_jogos", as: :dashboard_detalhamento_jogos
  patch "/dashboard/convites/:liga_membro_id/aceitar", to: "dashboard#aceitar_convite", as: :dashboard_aceitar_convite
  delete "/dashboard/convites/:liga_membro_id/negar", to: "dashboard#negar_convite", as: :dashboard_negar_convite
  get "/dashboard/usuarios/novo", to: "dashboard#new_user", as: :dashboard_new_user
  post "/dashboard/usuarios", to: "dashboard#create_user", as: :dashboard_create_user
  post "/dashboard/preencher_mata_mata", to: "dashboard#preencher_mata_mata", as: :dashboard_preencher_mata_mata
  post "/dashboard/resetar_mata_mata", to: "dashboard#resetar_mata_mata", as: :dashboard_resetar_mata_mata

  # Numeração de Jogadores para Root
  get "/dashboard/jogadores/numeracao", to: "dashboard#editar_numeracao_selecoes", as: :dashboard_editar_numeracao_selecoes
  get "/dashboard/jogadores/numeracao/:selecao_id", to: "dashboard#editar_numeracao_jogadores", as: :dashboard_editar_numeracao_jogadores
  patch "/dashboard/jogadores/numeracao/:selecao_id", to: "dashboard#salvar_numeracao_jogadores", as: :dashboard_salvar_numeracao_jogadores

  unauthenticated do
    devise_scope :user do
      root to: "devise/sessions#new"
    end
  end

  resources :palpites, except: [:destroy]

  resources :emails, only: %i[new create]

  resources :notificacoes do
    member do
      patch :accept_admin_invite
      patch :reject_admin_invite
    end
    collection do
      post :read_all
    end
  end

  resources :users, path: 'usuarios', only: [:index, :show, :edit, :update, :destroy] do
    member do
      patch :change_plan
    end
    collection do
      get :pontuacao
      get :ranking
    end
  end

  get "/perfil", to: "users#perfil", as: :perfil
  get "/simulador", to: "simulador#index", as: :simulador
  get "/perfil/editar", to: "users#edit_perfil", as: :edit_perfil
  patch "/perfil", to: "users#update_perfil"
  patch "/perfil/conquistas", to: "users#update_conquistas", as: :update_perfil_conquistas
  patch "/perfil/alterar_senha", to: "users#update_password", as: :update_password
  patch "/perfil/aviso-pontuacao-penaltis", to: "users#dismiss_penaltis_scoring_notice", as: :dismiss_penaltis_scoring_notice
  patch "/toggle_odds", to: "users#toggle_odds", as: :toggle_odds

  post "/checkout/mercado_pago/pix", to: "checkout#mercado_pago_pix"
  post "/checkout/mercado_pago/pix_direto", to: "checkout#mercado_pago_pix_direto", as: :checkout_mercado_pago_pix_direto
  get "/checkout/pix/:id", to: "checkout#pix", as: :checkout_pix
  get "/checkout/sucesso", to: "checkout#sucesso", as: :checkout_sucesso
  post "/mercado_pago/webhook", to: "mercado_pago_webhooks#create", as: :mercado_pago_webhook

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
      patch :accept_member
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
    collection do
      post :sync_odds
      post :sync_all_statistics
      post :salvar_placares
      post :realocar_placares
    end

    member do
      patch :start
      get :finalize
      patch :finish
      post :sync_statistics
      get :palpites
      delete :remove_goal
      patch :update_goal
    end
  end

  resources :grupos

  resources :selecoes do
    collection do
      post :sync_squads
      post :sync_squads_only
      post :sync_players_data
    end
  end

  get '/termos', to: 'static_pages#termos', as: :termos
  get '/privacidade', to: 'static_pages#privacidade', as: :privacidade
  match '/aceitar-termos', to: 'static_pages#aceitar_termos', as: :aceitar_termos, via: [:get, :post]

  get "up" => "rails/health#show", as: :rails_health_check
end
