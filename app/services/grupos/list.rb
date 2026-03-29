module Grupos
  class List
    def initialize(grupo:)
      @grupo = grupo
    end

    def call
      {
        classificacao: classificacao,
        jogos: jogos
      }
    end

    private

    attr_reader :grupo

    def classificacao
      Selecoes::ClassificacaoPorGrupo.call(grupo)
    end

    def jogos
      Jogo.grupo
          .joins(:mandante)
          .where(selecoes: { grupo_id: grupo_id })
          .order(:data)
    end

    def grupo_id
      Grupo.find_by(nome: grupo)&.id
    end
  end
end