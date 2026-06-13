module JogosHelper
  FASES = [
    { key: "grupo", label: "Grupos" },
    { key: "segunda_fase", label: "2ª Fase" },
    { key: "oitavas", label: "Oitavas" },
    { key: "quartas", label: "Quartas" },
    { key: "semi", label: "Semi" },
    { key: "terceiro_lugar", label: "3º Lugar" },
    { key: "final", label: "Final" }
  ].freeze

  def next_jogo_rapido(user)
    Jogo.where(status: :programado, definir: false)
        .where.not(id: user.palpites.select(:jogo_id))
        .order(:data)
        .first
  end

  def jogos_pendentes_count(user)
    Jogo.where(status: :programado, definir: false)
        .where.not(id: user.palpites.select(:jogo_id))
        .count
  end

  def fase_ativa?(tipo_ativo, fase_key)
    tipo_ativo.to_s == fase_key.to_s
  end

  def fase_tab_classes(ativo)
    base = "flex items-center gap-1.5 px-4 py-2.5 rounded-xl text-sm font-bold whitespace-nowrap transition-all duration-200"
    if ativo
      "#{base} bg-primary text-primary-content shadow-lg shadow-primary/30 scale-105"
    else
      "#{base} bg-base-100/80 text-base-content/70 hover:bg-base-100 hover:text-base-content border border-base-300/50 hover:border-primary/30"
    end
  end

  def grupo_tab_classes(ativo)
    base = "flex items-center justify-center w-11 h-11 rounded-xl text-sm font-black transition-all duration-200"
    if ativo
      "#{base} bg-primary text-primary-content shadow-lg shadow-primary/30 scale-110 ring-2 ring-primary ring-offset-2 ring-offset-base-200"
    else
      "#{base} bg-base-100 text-base-content/60 hover:bg-base-100 hover:text-base-content border border-base-300/50 hover:border-primary/40 hover:scale-105"
    end
  end

  def grupo_letra(grupo)
    grupo.nome.to_s.strip.last&.upcase || "?"
  end
end
