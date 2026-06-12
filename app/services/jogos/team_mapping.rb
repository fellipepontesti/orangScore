module Jogos
  module TeamMapping
    WORLD_CUP_TEAM_SEARCH = {
      'Brasil' => 'Brazil',
      'Canadá' => 'Canada',
      'Bósnia e Herzegovina' => 'Bosnia',
      'Catar' => 'Qatar',
      'Qatar' => 'Qatar',
      'Suíça' => 'Switzerland',
      'Suiça' => 'Switzerland',
      'Marrocos' => 'Morocco',
      'Haiti' => 'Haiti',
      'Escócia' => 'Scotland',
      'Bélgica' => 'Belgium',
      'Bélgica ' => 'Belgium',
      'Estados Unidos' => 'USA',
      'Paraguai' => 'Paraguay',
      'Austrália' => 'Australia',
      'Egito' => 'Egypt',
      'Turquia' => 'Turkey',
      'Alemanha' => 'Germany',
      'Curação' => 'Curacao',
      'Costa do Marfim' => 'Ivory-Coast',
      'Equador' => 'Ecuador',
      'Irã' => 'Iran',
      'Holanda' => 'Netherlands',
      'Japão' => 'Japan',
      'Nova Zelândia' => 'New-Zealand',
      'Nova Zelândia ' => 'New-Zealand',
      'Espanha' => 'Spain',
      'Espanha ' => 'Spain',
      'Cabo Verde' => 'Cape-Verde',
      'Suécia' => 'Sweden',
      'Tunísia' => 'Tunisia',
      'Arábia Saudita' => 'Saudi-Arabia',
      'Arábia Saudita ' => 'Saudi-Arabia',
      'Uruguai' => 'Uruguay',
      'França' => 'France',
      'Argentina' => 'Argentina',
      'Argentina ' => 'Argentina',
      'Senegal' => 'Senegal',
      'Argélia' => 'Algeria',
      'Iraque' => 'Iraq',
      'Noruega' => 'Norway',
      'Portugal' => 'Portugal',
      'RD Congo' => 'Congo-DR',
      'Áustria' => 'Austria',
      'Uzbequistão' => 'Uzbekistan',
      'Colômbia' => 'Colombia',
      'Jordânia' => 'Jordan',
      'Gana' => 'Ghana',
      'Inglaterra' => 'England',
      'Inglaterra ' => 'England',
      'Cróacia' => 'Croatia',
      'Croácia' => 'Croatia',
      'Panamá' => 'Panama',
      'Coreia do Sul' => 'South-Korea',
      'Coréia do Sul' => 'South-Korea',
      'República Tcheca' => 'Czech-Republic',
      'México' => 'Mexico',
      'África do Sul' => 'South-Africa'
    }.freeze

    def self.api_search_name(local_name)
      return nil if local_name.nil? || local_name.to_s.strip.empty?

      normalized = local_name.to_s.strip
      WORLD_CUP_TEAM_SEARCH.fetch(normalized, normalized)
    end
  end
end