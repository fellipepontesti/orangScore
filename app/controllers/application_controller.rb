class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :check_terms_acceptance, if: -> { user_signed_in? && !devise_controller? }
  
  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(
      :sign_up,
      keys: [:name, :selecao_id, :terms_of_service]
    )

    devise_parameter_sanitizer.permit(
      :account_update,
      keys: [:name, :selecao_id]
    )
  end

  def after_sign_in_path_for(_resource)
    root_path
  end

  def after_sign_out_path_for(_resource_or_scope)
    new_user_session_path
  end

  private

  def check_terms_acceptance
    # Se for root (tipo 1), não precisa travar (opcional, mas você pediu tipo diferente de 1)
    return if current_user.root?
    
    # Se já aceitou, segue o jogo
    return if current_user.terms_accepted_at.present?

    # Se estiver tentando acessar a própria página de aceite ou termos/privacidade, não redireciona (evita loop)
    # Essas rotas já estão com skip_before_action no StaticPagesController
    redirect_to aceitar_termos_post_path unless request.path == "/aceitar-termos"
  end

  def authorize_root!
    return if current_user&.root?

    redirect_to root_path, alert: 'Acesso não autorizado.'
  end
end
