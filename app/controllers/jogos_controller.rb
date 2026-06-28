class JogosController < ApplicationController
  before_action :authenticate_user!
  before_action :set_jogo, only: %i[ show edit update destroy start finalize finish sync_statistics palpites remove_goal update_goal ]
  before_action :load_selecoes, only: %i[new create edit update finalize]
  before_action :authorize_root_or_semi_root!, only: %i[start update finish sync_statistics]
  before_action :authorize_root!, except: %i[index show start update finish sync_statistics palpites]

  def index
    filtro_por_data = params[:data].present? || params[:start_date].present? || params[:end_date].present?
    @view_mode = params[:view_mode].presence || 'lista'
    
    @tipo_ativo = params[:tipo].presence
    if @view_mode == 'grupo'
      @tipo_ativo ||= 'grupo' unless filtro_por_data
    else
      @tipo_ativo = nil if params[:tipo].blank?
    end

    @grupos = Grupo.order(:nome)

    @grupo_ativo = if @tipo_ativo == 'grupo' && @view_mode == 'grupo'
      params[:grupo].presence || @grupos.first&.uuid
    end
    
    @status_filtro = params[:status]
    @data_inicio = params[:start_date].presence || params[:data]
    @data_fim = params[:end_date].presence || params[:data]

    @jogos = Jogos::List.new(params: {
      tipo: @tipo_ativo,
      grupo: @grupo_ativo,
      status: @status_filtro,
      start_date: @data_inicio,
      end_date: @data_fim
    }).call
  end

  def show
    @palpite = current_user.palpites.find_by(jogo_id: @jogo.id)
    @user_point = current_user.user_points.find_by(jogo_id: @jogo.id)

    if current_user.root?
      ja_palpitaram_ids = @jogo.palpites.pluck(:user_id)
      @usuarios_sem_palpite = User.where.not(id: ja_palpitaram_ids).order(:name)
      @usuarios_com_palpite = User.where(id: ja_palpitaram_ids).order(:name)
    end
  end

  def palpites
    if @jogo.programado? && !current_user.root?
      redirect_to @jogo, alert: "Os palpites só estarão visíveis após o início da partida."
      return
    end

    @usuarios_para_filtro = User.order(:name) if current_user.root?
    @usuario_filtrado = @usuarios_para_filtro&.find { |usuario| usuario.id.to_s == params[:user_id].to_s } if params[:user_id].present?
    @palpite_usuario_filtrado = @jogo.palpites.find_by(user_id: @usuario_filtrado.id) if @usuario_filtrado

    @palpites = @jogo.palpites.includes(:user)
    @palpites = @palpites.where(user_id: @usuario_filtrado.id) if @usuario_filtrado
    @palpites = @palpites.to_a
    @user_points_by_user = @jogo.user_points.index_by(&:user_id)

    @pontos_por_palpite = {}
    @palpites.each do |p|
      pontos = if @jogo.finalizado? && @user_points_by_user[p.user_id]
        @user_points_by_user[p.user_id].pontos.to_i
      elsif @jogo.em_andamento? || @jogo.suspenso? || @jogo.finalizado?
        Jogos::CalculaPontuacao.calcular_pontos_em_memoria(p, @jogo.gols_mandante, @jogo.gols_visitante)
      else
        0
      end
      @pontos_por_palpite[p.id] = pontos
    end

    @palpites.sort_by! do |p|
      pontos = @pontos_por_palpite[p.id]
      [pontos, p.user.name.to_s.downcase]
    end

    @total_palpites = @palpites.size
    mais_comum = @palpites.map { |p| "#{p.gols_casa}x#{p.gols_fora}" }.tally.max_by { |_, count| count }
    @palpite_mais_comum = mais_comum ? mais_comum.first.gsub('x', ' - ') : "—"
    
    @media_gols_palpitados = if @palpites.any?
      (@palpites.sum { |p| p.gols_casa + p.gols_fora }.to_f / @total_palpites).round(1)
    else
      "—"
    end
  end

  def new
    @jogo = Jogo.new
    @grupos = Grupo.order(:nome)
  end

  def edit
    @grupos = Grupo.order(:nome)
  end

  def create
    @jogo = Jogos::Create.new(params: jogo_params).call

    respond_to do |format|
      if @jogo.persisted?
        format.html { redirect_to @jogo, notice: "Jogo criado com sucesso!." }
        format.json { render :show, status: :created, location: @jogo }
      else
        @grupos = Grupo.order(:nome)
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @jogo.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    @jogo = Jogos::Update.new(jogo: @jogo, params: jogo_params).call

    respond_to do |format|
      if @jogo.errors.empty?
        format.html do
          if params[:redirect_to_dashboard] == 'true'
            redirect_to authenticated_root_path, notice: "Placar atualizado com sucesso!"
          else
            redirect_to @jogo, notice: "Jogo atualizado com sucesso!.", status: :see_other
          end
        end
        format.json { render :show, status: :ok, location: @jogo }
      else
        @grupos = Grupo.order(:nome)
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @jogo.errors, status: :unprocessable_entity }
      end
    end
  end

  def start
    Jogos::Start.new(jogo: @jogo).call
    redirect_to @jogo, notice: "Jogo iniciado com sucesso! Notificações enviadas."
  rescue => e
    redirect_to @jogo, alert: e.message
  end

  def finalize
  end

  def finish
    @jogo = Jogos::Update.new(jogo: @jogo, params: jogo_params.merge(status: 'finalizado')).call

    if @jogo.errors.empty?
      # Tenta sincronizar as estatísticas reais de chutes/posse da partida na API Zafronix
      Jogos::SyncMatchStatistics.new(jogo: @jogo).call rescue nil

      redirect_to @jogo, notice: "Jogo finalizado com sucesso! Pontuações calculadas."
    else
      render :finalize, status: :unprocessable_entity
    end
  end

  def sync_statistics
    result = Jogos::SyncMatchStatistics.new(jogo: @jogo).call

    if current_user.root?
      texto = if result[:success]
        "Sincronização de estatísticas do jogo #{@jogo.mandante&.nome} x #{@jogo.visitante&.nome} concluída com sucesso!"
      else
        "Sincronização de estatísticas do jogo #{@jogo.mandante&.nome} x #{@jogo.visitante&.nome} falhou: #{result[:error]}"
      end
      Notificacao.create!(
        user: current_user,
        tipo: :info,
        status: :unread,
        texto: texto
      )
    end

    if result[:success]
      redirect_to @jogo, notice: "Estatísticas sincronizadas com sucesso da API Zafronix!"
    else
      redirect_to @jogo, alert: "Erro ao sincronizar estatísticas: #{result[:error]}"
    end
  end




  def sync_odds
    result = Jogos::FetchOdds.sync_all
    if result[:errors].empty?
      redirect_to authenticated_root_path,
        notice: "Odds recalculadas com sucesso para #{result[:updated]} jogo(s)."
    else
      redirect_to authenticated_root_path,
        alert: "Odds calculadas para #{result[:updated]} jogo(s), mas #{result[:errors].size} erro(s) ocorreram."
    end
  rescue => e
    redirect_to authenticated_root_path, alert: "Falha ao calcular odds: #{e.message}"
  end

  def sync_all_statistics
    year = params[:year].presence || '2026'
    SyncAllStatisticsJob.perform_later(year: year, user_id: current_user.id)
    redirect_back fallback_location: authenticated_root_path, notice: "A sincronização de todas as estatísticas de jogo foi iniciada em segundo plano. Os dados de posse de bola, chutes e passes serão atualizados em breve!"
  rescue => e
    redirect_back fallback_location: authenticated_root_path, alert: "Erro ao agendar sincronização de estatísticas: #{e.message}"
  end

  def destroy
    Jogos::Destroy.new(jogo: @jogo).call

    respond_to do |format|
      format.html { redirect_to jogos_path, notice: "Jogo excluído com sucesso!.", status: :see_other }
      format.json { head :no_content }
    end
  end

  def remove_goal
    info = @jogo.informacao_jogo
    if info && info.dados.present? && info.dados['goals'].present?
      index = params[:index].to_i
      goals = info.dados['goals'].to_a
      
      if index >= 0 && index < goals.size
        removed_goal = goals.delete_at(index)
        info.dados['goals'] = goals
        info.save!

        # Re-consolida a artilharia
        Jogos::SyncSquads.new(import_squad: false, import_goals: true).call

        redirect_to @jogo, notice: "Gol de #{removed_goal['scorer']} removido com sucesso!"
      else
        redirect_to @jogo, alert: "Gol não encontrado para remoção."
      end
    else
      redirect_to @jogo, alert: "Nenhuma informação de gol cadastrada para este jogo."
    end
  end

  def update_goal
    info = @jogo.informacao_jogo
    if info && info.dados.present? && info.dados['goals'].present?
      index = params[:index].to_i
      goals = info.dados['goals'].to_a
      
      if index >= 0 && index < goals.size
        # Atualiza os dados do gol
        goals[index]['scorer'] = params[:scorer]
        goals[index]['minute'] = params[:minute].to_i
        goals[index]['team'] = params[:team]
        goals[index]['assist'] = params[:assist].presence
        goals[index]['type'] = params[:type].presence || 'normal'
        
        info.dados['goals'] = goals
        info.save!

        # Re-consolida a artilharia
        Jogos::SyncSquads.new(import_squad: false, import_goals: true).call

        redirect_to @jogo, notice: "Gol atualizado com sucesso!"
      else
        redirect_to @jogo, alert: "Gol não encontrado para atualização."
      end
    else
      redirect_to @jogo, alert: "Nenhuma informação de gol cadastrada para este jogo."
    end
  end

  def salvar_placares
    inicio_dia = Time.use_zone("America/Sao_Paulo") { Time.zone.parse("2026-06-28 00:00:00") }
    # Filtra jogos a partir do dia 28 de junho que estão programados e têm palpites
    jogos = Jogo.where("data >= ?", inicio_dia)
                .where(status: :programado)
                .joins(:palpites)
                .distinct

    dados_jogos = jogos.map do |j|
      {
        mandante_id: j.mandante_id,
        visitante_id: j.visitante_id,
        nome_provisorio_mandante: j.nome_provisorio_mandante,
        nome_provisorio_visitante: j.nome_provisorio_visitante,
        gols_mandante: j.gols_mandante,
        gols_visitante: j.gols_visitante,
        status: j.status,
        definir: j.definir,
        palpites: j.palpites.map do |p|
          {
            user_id: p.user_id,
            gols_casa: p.gols_casa,
            gols_fora: p.gols_fora
          }
        end
      }
    end

    dados_salvos = { "jogos" => dados_jogos }

    FileUtils.mkdir_p(Rails.root.join("tmp"))
    File.write(Rails.root.join("tmp/placares_salvos_28_junho.json"), JSON.pretty_generate(dados_salvos))

    total_palpites = dados_jogos.sum { |j| j[:palpites].size }
    redirect_back fallback_location: authenticated_root_path, notice: "#{dados_jogos.size} jogos programados e #{total_palpites} palpites de usuários do dia 28 de Junho em diante foram salvos com sucesso!"
  end

  def realocar_placares
    caminho = Rails.root.join("tmp/placares_salvos_28_junho.json")
    unless File.exist?(caminho)
      redirect_back fallback_location: authenticated_root_path, alert: "Nenhum palpite ou placar do dia 28 de Junho em diante foi salvo anteriormente!"
      return
    end

    conteudo = JSON.parse(File.read(caminho))
    dados_jogos = conteudo["jogos"] || []

    inicio_dia = Time.use_zone("America/Sao_Paulo") { Time.zone.parse("2026-06-28 00:00:00") }
    jogos_futuros = Jogo.where("data >= ?", inicio_dia).to_a

    jogos_atualizados = 0
    palpites_realocados = 0

    dados_jogos.each do |registro|
      jogo = if registro["definir"] == false && registro["mandante_id"].present? && registro["visitante_id"].present?
        jogos_futuros.find { |j| j.mandante_id == registro["mandante_id"] && j.visitante_id == registro["visitante_id"] }
      elsif registro["nome_provisorio_mandante"].present? && registro["nome_provisorio_visitante"].present?
        jogos_futuros.find { |j| j.nome_provisorio_mandante == registro["nome_provisorio_mandante"] && j.nome_provisorio_visitante == registro["nome_provisorio_visitante"] }
      end

      if jogo
        jogo.update(
          gols_mandante: registro["gols_mandante"],
          gols_visitante: registro["gols_visitante"],
          status: registro["status"]
        )
        jogos_atualizados += 1

        (registro["palpites"] || []).each do |p_salvo|
          palpite = Palpite.find_or_initialize_by(user_id: p_salvo["user_id"], jogo_id: jogo.id)
          palpite.gols_casa = p_salvo["gols_casa"]
          palpite.gols_fora = p_salvo["gols_fora"]
          if palpite.save
            palpites_realocados += 1
          end
        end
      end
    end

    redirect_back fallback_location: authenticated_root_path, notice: "Placares restaurados em #{jogos_atualizados} jogos e #{palpites_realocados} palpites de usuários realocados!"
  end

  private
    def set_jogo
      @jogo = Jogo.find_by_uuid_param!(params[:id])
    end

    def load_selecoes
      if @jogo.present?
        classificadas_ids = Selecao.classificadas.pluck(:id)
        classificadas_ids << @jogo.mandante_id if @jogo.mandante_id.present?
        classificadas_ids << @jogo.visitante_id if @jogo.visitante_id.present?
        @selecoes = Selecao.where(id: classificadas_ids.uniq).order(:nome)
      else
        @selecoes = Selecao.classificadas.order(:nome)
      end
    end

    def jogo_params
      params.require(:jogo).permit(
        :mandante_id, 
        :visitante_id, 
        :gols_mandante, 
        :gols_visitante, 
        :data, 
        :tipo, 
        :definir,
        :estadio,
        :nome_provisorio_mandante,
        :nome_provisorio_visitante,
        :status,
        :grupo_id,
        :vencedor_penaltis_id
      )
    end
end
