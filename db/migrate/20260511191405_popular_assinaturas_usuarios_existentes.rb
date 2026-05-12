class PopularAssinaturasUsuariosExistentes < ActiveRecord::Migration[7.1]
  class User < ApplicationRecord
    self.table_name = 'users'
  end

  class Assinatura < ApplicationRecord
    self.table_name = 'assinaturas'

    enum :plano, {
      basic: 0,
      plus: 1,
      premium: 2
    }
  end

  def up
    User.find_each do |usuario|
      next if Assinatura.exists?(usuario_id: usuario.id)

      Assinatura.create!(
        usuario_id: usuario.id,
        plano: :basic,
        ativa: true
      )
    end
  end

  def down
    Assinatura.where(plano: :basic).delete_all
  end
end