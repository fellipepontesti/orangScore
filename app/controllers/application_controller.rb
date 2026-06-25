class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :check_terms_acceptance, if: -> { user_signed_in? && !devise_controller? }
  before_action :store_referral_id
  before_action :restrict_semi_root_access, if: -> { user_signed_in? }
  before_action :update_last_seen_at, if: -> { user_signed_in? && (current_user.last_seen_at.nil? || current_user.last_seen_at < 5.minutes.ago) }
  before_action :check_retroactive_achievements, if: -> { user_signed_in? && !devise_controller? }
  before_action :check_new_achievements, if: -> { user_signed_in? && !devise_controller? }
  
  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(
      :sign_up,
      keys: [:name, :selecao_id, :terms_of_service, :referred_by_id]
    )

    devise_parameter_sanitizer.permit(
      :account_update,
      keys: [:name, :selecao_id]
    )
  end

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || root_path
  end

  def after_sign_out_path_for(_resource_or_scope)
    new_user_session_path
  end

  private

  def check_terms_acceptance
    return if current_user.root? || current_user.semi_root?
    
    # Se já aceitou, segue o jogo
    return if current_user.terms_accepted_at.present?

    # Se estiver tentando acessar a própria página de aceite ou termos/privacidade, não redireciona (evita loop)
    # Essas rotas já estão com skip_before_action no StaticPagesController
    redirect_to aceitar_termos_path unless request.path == "/aceitar-termos"
  end

  def authorize_root!
    return if current_user&.root?

    redirect_to root_path, alert: 'Acesso não autorizado.'
  end

  def authorize_root_or_semi_root!
    return if current_user&.root? || current_user&.semi_root?

    redirect_to root_path, alert: 'Acesso não autorizado.'
  end

  def restrict_semi_root_access
    return unless current_user.semi_root?
    return if devise_controller?

    allowed_routes = [
      { controller: "dashboard", action: "index" },
      { controller: "jogos", action: "index" },
      { controller: "jogos", action: "show" },
      { controller: "jogos", action: "start" },
      { controller: "jogos", action: "update" },
      { controller: "jogos", action: "finish" },
      { controller: "jogos", action: "palpites" },
      { controller: "jogos", action: "sync_statistics" },
      { controller: "users", action: "update_password" },
      { controller: "devise/sessions", action: "destroy" }
    ]

    is_allowed = allowed_routes.any? do |route|
      params[:controller] == route[:controller] && params[:action] == route[:action]
    end

    unless is_allowed
      redirect_to authenticated_root_path, alert: "Acesso restrito para usuários operacionais."
    end
  end

  def store_referral_id
    session[:referral_id] = params[:ref] if params[:ref].present?
  end

  def update_last_seen_at
    current_user.update_columns(last_seen_at: Time.current)
  end

  def check_new_achievements
    session[:shown_achievement_ids] ||= []
    
    # Busca conquistas desbloqueadas nos últimos 15 segundos que não foram exibidas nesta sessão
    new_conquistas = current_user.user_conquistas
                                 .includes(:conquista)
                                 .where("user_conquistas.created_at > ?", 15.seconds.ago)
                                 .where.not(id: session[:shown_achievement_ids])
                                 .to_a

    if new_conquistas.any?
      @new_achievements_to_show = new_conquistas.map(&:conquista)
      session[:shown_achievement_ids] += new_conquistas.map(&:id)
    end
  end

  def check_retroactive_achievements
    unless session[:retroactive_checked]
      Users::AwardAchievements.check_retroactive_achievements(current_user)
      session[:retroactive_checked] = true

      # Recupera e celebra conquistas históricas já salvas no banco
      unless session[:historical_achievements_checked]
        all_user_conquistas = current_user.user_conquistas.includes(:conquista).to_a
        if all_user_conquistas.any?
          session[:shown_achievement_ids] ||= []
          new_to_show = all_user_conquistas.reject { |uc| session[:shown_achievement_ids].include?(uc.id) }
          
          if new_to_show.any?
            @new_achievements_to_show ||= []
            @new_achievements_to_show += new_to_show.map(&:conquista)
            session[:shown_achievement_ids] += new_to_show.map(&:id)
          end
        end
        session[:historical_achievements_checked] = true
      end
    end
  end
end
