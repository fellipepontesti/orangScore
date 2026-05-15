class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?
  
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

  def authorize_root!
    return if current_user&.root?

    redirect_to root_path, alert: 'Acesso não autorizado.'
  end
end
