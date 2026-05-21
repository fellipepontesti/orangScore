class CreateReferralCampaignNotifications < ActiveRecord::Migration[7.1]
  TEXTO = 'Indique 5 amigos até o dia 01/06/2026 e ganhe o plano Semi-Plus: sua liga passa a ter limite de 10 membros gratuitamente.'.freeze

  def up
    execute sanitize_sql([<<~SQL, TEXTO, TEXTO])
      INSERT INTO notificacoes (user_id, tipo, texto, status, created_at, updated_at)
      SELECT users.id, 3, ?, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      FROM users
      WHERE NOT EXISTS (
        SELECT 1
        FROM notificacoes
        WHERE notificacoes.user_id = users.id
          AND notificacoes.tipo = 3
          AND notificacoes.texto = ?
      )
    SQL
  end

  def down
    execute sanitize_sql([<<~SQL, TEXTO])
      DELETE FROM notificacoes
      WHERE tipo = 3
        AND texto = ?
    SQL
  end

  private

  def sanitize_sql(sql)
    ActiveRecord::Base.sanitize_sql_array(sql)
  end
end
