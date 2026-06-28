class SimuladorController < ApplicationController
  before_action :authenticate_user!
  include JogosHelper

  def index
    # Carrega todos os jogos do mata-mata ordenados por data cronologicamente
    @jogos = Jogo.where.not(tipo: :grupo).includes(:mandante, :visitante).order(:data, :id)

    # Serializa os confrontos mantendo a ordenação cronológica
    @jogos_json = @jogos.map do |j|
      {
        id: j.id,
        uuid: j.uuid,
        tipo: j.tipo,
        data_formatada: horario_jogo(j, "%d/%m %H:%M"),
        data_iso: j.data&.in_time_zone("America/Sao_Paulo")&.strftime("%Y-%m-%dT%H:%M"),
        estadio: j.estadio,
        mandante_id: j.mandante_id,
        mandante_nome: j.mandante&.nome || j.nome_provisorio_mandante || "A definir",
        mandante_logo: j.mandante&.logo.present? ? ActionController::Base.helpers.image_path("selecoes/#{j.mandante.logo}") : nil,
        visitante_id: j.visitante_id,
        visitante_nome: j.visitante&.nome || j.nome_provisorio_visitante || "A definir",
        visitante_logo: j.visitante&.logo.present? ? ActionController::Base.helpers.image_path("selecoes/#{j.visitante.logo}") : nil,
        gols_mandante: j.gols_mandante,
        gols_visitante: j.gols_visitante,
        status: j.status,
        definir: j.definir,
        nome_provisorio_mandante: j.nome_provisorio_mandante,
        nome_provisorio_visitante: j.nome_provisorio_visitante
      }
    end
  end
end
