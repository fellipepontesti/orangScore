class StaticPagesController < ApplicationController
  skip_before_action :check_terms_acceptance, only: [:termos, :privacidade, :aceitar_termos]

  def termos
  end

  def privacidade
  end

  def aceitar_termos
    if request.post?
      current_user.update!(terms_accepted_at: Time.current)
      redirect_to authenticated_root_path, notice: "Obrigado por aceitar nossos termos! Acesso liberado."
    else
      render :aceitar_termos, layout: "application"
    end
  end
end
