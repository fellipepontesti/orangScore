module Users
  class Edit
    def initialize(user_id, params = {})
      @user_id = user_id
      @params  = params
    end

    def call
      usuario = User.find(@user_id)

      usuario.update!(@params)

      usuario
    end
  end
end