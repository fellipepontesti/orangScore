module PasswordRecovery
  class RequestNewPassword
    def initialize(email)
      @email = email
    end

    def call
      user = User.find_by(email: email)
      return unless user

      token = user.generate_password_recovery!
      PasswordMailer.reset(user, token).deliver_later
    end

    private

    attr_reader :email
  end
end
