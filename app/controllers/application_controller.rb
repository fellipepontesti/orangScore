class ApplicationController < ActionController::Base
  before_action :log_request_details
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
      { controller: "users", action: "dismiss_penaltis_scoring_notice" },
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
    # Busca conquistas desbloqueadas que ainda não foram exibidas/visualizadas
    new_conquistas = current_user.user_conquistas
                                 .includes(:conquista)
                                 .where(visualizada: false)
                                 .to_a

    if new_conquistas.any?
      @new_achievements_to_show = new_conquistas.map(&:conquista)
      # Marca as conquistas como visualizadas no banco de dados para nunca mais exibir em modais
      current_user.user_conquistas.where(id: new_conquistas.map(&:id)).update_all(visualizada: true)
    end
  end

  def check_retroactive_achievements
    unless session[:retroactive_checked]
      Users::AwardAchievements.check_retroactive_achievements(current_user)
      session[:retroactive_checked] = true
    end
  end

  def log_request_details
    return if request.path.start_with?("/assets", "/rails")

    user_info = if user_signed_in?
                  "User: ID #{current_user.id} (#{current_user.email})"
                else
                  "User: Guest"
                end

    parameter_filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
    filtered_params = parameter_filter.filter(params.to_unsafe_h).except(:controller, :action)

    params_str = filtered_params.any? ? " | Params: #{filtered_params.to_json}" : ""

    Rails.logger.info "[Audit] #{request.method} #{request.fullpath} | #{user_info} | IP: #{request.remote_ip}#{params_str}"
  end
end
