class ApplicationController < ActionController::Base
  before_action :auto_login_dev_user

  protected

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

  def auto_login_dev_user
    return unless Rails.env.development?
    return if user_signed_in?

    user = User.find_by(email: "teste2@teste.com")
    sign_in(user) if user
  end
end
