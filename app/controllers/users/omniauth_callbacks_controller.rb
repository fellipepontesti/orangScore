class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :verify_authenticity_token, only: :failure

  def google_oauth2
    ref_id = session.delete('referral_id')
    @user = User.from_omniauth(request.env['omniauth.auth'], ref_id)

    if @user.persisted?
      flash[:notice] = I18n.t 'devise.omniauth_callbacks.success', kind: 'Google'
      omniauth_params = request.env['omniauth.params'] || {}
      if omniauth_params['remember_me'] == '1'
        @user.remember_me!
      else
        @user.forget_me!
      end
      sign_in_and_redirect @user, event: :authentication
    else
      session['devise.google_data'] = request.env['omniauth.auth'].except(:extra)
      redirect_to new_user_registration_url, alert: @user.errors.full_messages.join("\n")
    end
  end

  def failure
    redirect_to root_path
  end
end

