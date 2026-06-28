class Selecao < ApplicationRecord
  include HasPublicUuid
  belongs_to :grupo
  has_many :users, foreign_key: "selecao_id"
  has_many :jogadores, class_name: 'Jogador', dependent: :destroy
  
  has_many :jogos_como_mandante,
           class_name: 'Jogo',
           foreign_key: :mandante_id,
           dependent: :destroy

  has_many :jogos_como_visitante,
           class_name: 'Jogo',
           foreign_key: :visitante_id,
           dependent: :destroy

  validates :nome, presence: true, uniqueness: {
    message: 'já está sendo utilizado por outra seleção'
  }, unless: -> { nome == 'A definir' }

  validates :logo, presence: true, uniqueness: {
    message: 'já está sendo utilizada por outra seleção'
  }, unless: -> { logo == 'sem-escudo.png' }

  def nome_en
    Jogos::TeamMapping.api_search_name(nome)
  end

  def qtd_torcedores
    attributes['qtd_torcedores'] || users.count
  end
  
  scope :ordenadas, -> { 
    order(Arel.sql('pontos DESC, (gols - gols_sofridos) DESC, gols DESC, nome ASC')) 
  }

  scope :classificadas, -> { where(desclassificada: false) }

  def estilo_card
    nome_limpo = nome.to_s.strip.downcase.gsub('í', 'i').gsub('é', 'e').gsub('ó', 'o').gsub('á', 'a').gsub('ã', 'a').gsub('ç', 'c')
    
    case nome_limpo
    when 'brasil'
      { gradient: 'linear-gradient(135deg, #009739 0%, #007a2e 50%, #FEDF00 100%)', text: '#ffffff', border: 'rgba(254, 223, 0, 0.4)', text_shadow: '0 1px 2px rgba(0,0,0,0.6)' }
    when 'catar'
      { gradient: 'linear-gradient(135deg, #8A1538 0%, #5c0e25 100%)', text: '#ffffff', border: 'rgba(255,255,255,0.2)' }
    when 'suiça', 'suica'
      { gradient: 'linear-gradient(135deg, #DA291C 0%, #a81c12 100%)', text: '#ffffff', border: 'rgba(255,255,255,0.3)' }
    when 'marrocos'
      { gradient: 'linear-gradient(135deg, #C1272D 0%, #006233 100%)', text: '#ffffff', border: 'rgba(0,98,51,0.4)' }
    when 'haiti'
      { gradient: 'linear-gradient(135deg, #00209F 0%, #D21034 100%)', text: '#ffffff', border: 'rgba(255,255,255,0.2)' }
    when 'escocia'
      { gradient: 'linear-gradient(135deg, #005EB8 0%, #003B75 100%)', text: '#ffffff', border: 'rgba(255,255,255,0.2)' }
    when 'belgica'
      { gradient: 'linear-gradient(135deg, #000000 0%, #ED2939 50%, #FFE300 100%)', text: '#ffffff', border: 'rgba(255,227,0,0.3)', text_shadow: '0 1px 2px rgba(0,0,0,0.8)' }
    when 'estados unidos'
      { gradient: 'linear-gradient(135deg, #0A3161 0%, #B31942 100%)', text: '#ffffff', border: 'rgba(255,255,255,0.3)' }
    when 'paraguai'
      { gradient: 'linear-gradient(135deg, #D52B1E 0%, #0038A8 100%)', text: '#ffffff', border: 'rgba(255,255,255,0.2)' }
    when 'egito'
      { gradient: 'linear-gradient(135deg, #CE1126 0%, #000000 50%, #C0930C 100%)', text: '#ffffff', border: 'rgba(192,147,12,0.3)', text_shadow: '0 1px 2px rgba(0,0,0,0.8)' }
    when 'alemanha'
      { gradient: 'linear-gradient(135deg, #000000 0%, #DD0000 50%, #FFCC00 100%)', text: '#ffffff', border: 'rgba(255,204,0,0.4)', text_shadow: '0 1px 2px rgba(0,0,0,0.8)' }
    when 'curaçao', 'curacao', 'curaço', 'curacao'
      { gradient: 'linear-gradient(135deg, #002B7F 0%, #F9E814 100%)', text: '#ffffff', border: 'rgba(255,255,255,0.2)' }
    when 'costa do marfim'
      { gradient: 'linear-gradient(135deg, #F77F00 0%, #009E60 100%)', text: '#ffffff', border: 'rgba(255,255,255,0.2)' }
    when 'equador'
      { gradient: 'linear-gradient(135deg, #FFDD00 0%, #0033A0 50%, #D52B1E 100%)', text: '#ffffff', border: 'rgba(0,51,160,0.3)', text_shadow: '0 1px 2px rgba(0,0,0,0.6)' }
    when 'ira'
      { gradient: 'linear-gradient(135deg, #239E46 0%, #DA251D 100%)', text: '#ffffff', border: 'rgba(255,255,255,0.2)' }
    when 'holanda'
      { gradient: 'linear-gradient(135deg, #F36C21 0%, #21468B 100%)', text: '#ffffff', border: 'rgba(255,255,255,0.2)' }
    when 'japao'
      { gradient: 'linear-gradient(135deg, #0005a0 0%, #000361 70%, #BC002D 100%)', text: '#ffffff', border: 'rgba(255,255,255,0.25)' }
    when 'nova zelandia'
      { gradient: 'linear-gradient(135deg, #000000 0%, #222222 100%)', text: '#ffffff', border: 'rgba(255,255,255,0.3)' }
    when 'espanha'
      { gradient: 'linear-gradient(135deg, #AD1519 0%, #FFC400 100%)', text: '#ffffff', border: 'rgba(255,196,0,0.3)', text_shadow: '0 1px 2px rgba(0,0,0,0.6)' }
    when 'cabo verde'
      { gradient: 'linear-gradient(135deg, #003893 0%, #D21034 50%, #FFC400 100%)', text: '#ffffff', border: 'rgba(255,255,255,0.2)' }
    when 'suecia'
      { gradient: 'linear-gradient(135deg, #006AA7 0%, #FECC00 100%)', text: '#ffffff', border: 'rgba(254,204,0,0.3)', text_shadow: '0 1px 2px rgba(0,0,0,0.5)' }
    when 'tunisia'
      { gradient: 'linear-gradient(135deg, #E20909 0%, #a60505 100%)', text: '#ffffff', border: 'rgba(255,255,255,0.2)' }
    when 'arabia saudita'
      { gradient: 'linear-gradient(135deg, #006C35 0%, #004b24 100%)', text: '#ffffff', border: 'rgba(255,255,255,0.2)' }
    when 'uruguai'
      { gradient: 'linear-gradient(135deg, #87ADDF 0%, #FCD116 100%)', text: '#002244', border: 'rgba(0,34,68,0.2)', text_shadow: 'none' }
    when 'frança', 'franca'
      { gradient: 'linear-gradient(135deg, #002395 0%, #FFFFFF 50%, #ED2939 100%)', text: '#002395', border: 'rgba(0,35,149,0.3)', text_shadow: 'none' }
    when 'argentina'
      { gradient: 'linear-gradient(135deg, #74ACDF 0%, #FFFFFF 50%, #74ACDF 100%)', text: '#004b8d', border: 'rgba(0,75,141,0.3)', text_shadow: 'none' }
    when 'senegal'
      { gradient: 'linear-gradient(135deg, #00853F 0%, #FDEF42 50%, #E31B23 100%)', text: '#ffffff', border: 'rgba(227,27,35,0.3)', text_shadow: '0 1px 2px rgba(0,0,0,0.6)' }
    when 'argelia'
      { gradient: 'linear-gradient(135deg, #006633 0%, #D21034 100%)', text: '#ffffff', border: 'rgba(255,255,255,0.2)' }
    when 'iraque'
      { gradient: 'linear-gradient(135deg, #CE1126 0%, #007A3D 100%)', text: '#ffffff', border: 'rgba(255,255,255,0.2)' }
    when 'noruega'
      { gradient: 'linear-gradient(135deg, #BA0C2F 0%, #00205B 100%)', text: '#ffffff', border: 'rgba(255,255,255,0.2)' }
    when 'portugal'
      { gradient: 'linear-gradient(135deg, #006600 0%, #FF0000 100%)', text: '#ffffff', border: 'rgba(255,255,0,0.3)' }
    when 'rd congo'
      { gradient: 'linear-gradient(135deg, #007FFF 0%, #CE1126 100%)', text: '#ffffff', border: 'rgba(255,255,255,0.2)' }
    when 'austria'
      { gradient: 'linear-gradient(135deg, #ED2939 0%, #FFFFFF 50%, #ED2939 100%)', text: '#ED2939', border: 'rgba(237,41,57,0.3)' }
    when 'uzbequistao'
      { gradient: 'linear-gradient(135deg, #0099B5 0%, #1EB53A 100%)', text: '#ffffff', border: 'rgba(255,255,255,0.2)' }
    when 'colombia'
      { gradient: 'linear-gradient(135deg, #FCD116 0%, #003893 50%, #CE1126 100%)', text: '#ffffff', border: 'rgba(0,56,147,0.3)', text_shadow: '0 1px 2px rgba(0,0,0,0.6)' }
    when 'jordania'
      { gradient: 'linear-gradient(135deg, #007A3D 0%, #CE1126 100%)', text: '#ffffff', border: 'rgba(255,255,255,0.2)' }
    when 'gana'
      { gradient: 'linear-gradient(135deg, #CE1126 0%, #FCD116 50%, #006B3F 100%)', text: '#ffffff', border: 'rgba(0,107,63,0.3)', text_shadow: '0 1px 2px rgba(0,0,0,0.6)' }
    when 'inglaterra'
      { gradient: 'linear-gradient(135deg, #ffffff 0%, #CE1126 50%, #00205B 100%)', text: '#00205B', border: 'rgba(0,32,91,0.3)', text_shadow: 'none' }
    when 'croacia'
      { gradient: 'linear-gradient(135deg, #FF0000 0%, #FFFFFF 50%, #000099 100%)', text: '#000099', border: 'rgba(0,0,153,0.3)' }
    when 'panama'
      { gradient: 'linear-gradient(135deg, #00205B 0%, #D21034 100%)', text: '#ffffff', border: 'rgba(255,255,255,0.2)' }
    when 'coreia do sul'
      { gradient: 'linear-gradient(135deg, #CD1A3A 0%, #0B2F64 100%)', text: '#ffffff', border: 'rgba(255,255,255,0.2)' }
    when 'republica tcheca'
      { gradient: 'linear-gradient(135deg, #11457E 0%, #D7141A 100%)', text: '#ffffff', border: 'rgba(255,255,255,0.2)' }
    when 'mexico'
      { gradient: 'linear-gradient(135deg, #006847 0%, #CE1126 100%)', text: '#ffffff', border: 'rgba(255,255,255,0.3)' }
    when 'africa do sul'
      { gradient: 'linear-gradient(135deg, #DE3831 0%, #007A4D 50%, #002395 100%)', text: '#ffffff', border: 'rgba(255,255,255,0.25)', text_shadow: '0 1px 2px rgba(0,0,0,0.5)' }
    when 'canada'
      { gradient: 'linear-gradient(135deg, #FF0000 0%, #FFFFFF 50%, #FF0000 100%)', text: '#FF0000', border: 'rgba(255,0,0,0.3)' }
    when 'bosnia e herzegovina'
      { gradient: 'linear-gradient(135deg, #00209F 0%, #FECB00 100%)', text: '#ffffff', border: 'rgba(254,203,0,0.3)' }
    when 'australia'
      { gradient: 'linear-gradient(135deg, #008751 0%, #FFCD00 100%)', text: '#ffffff', border: 'rgba(255,205,0,0.3)' }
    when 'turquia'
      { gradient: 'linear-gradient(135deg, #E30A17 0%, #9c040d 100%)', text: '#ffffff', border: 'rgba(255,255,255,0.25)' }
    else
      { gradient: 'linear-gradient(135deg, #374151 0%, #1f2937 100%)', text: '#9ca3af', border: 'rgba(75,85,99,0.4)' }
    end
  end
end