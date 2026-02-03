class HomeController < ActionController::Base
  def index 
    if user_signed_in?
      redirect_to ligas_path
    else
      redirect_to new_user_session_path
    end
  end
end
