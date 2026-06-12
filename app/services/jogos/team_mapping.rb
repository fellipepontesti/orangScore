module Jogos
  module TeamMapping
    WORLD_CUP_TEAM_SEARCH = {
      'Brasil' => 'Brazil',
      'Canadá' => 'Canada',
      'Bósnia e Herzegovina' => 'Bosnia', # Na API é apenas Bosnia
      'Catar' => 'Qatar',
      'Qatar' => 'Qatar',
      'Suíça' => 'Switzerland',
      'Suiça' => 'Switzerland',
      'Marrocos' => 'Morocco',
      'Haiti' => 'Haiti',
      'Escócia' => 'Scotland',
      'Bélgica' => 'Belgium',
      'Estados Unidos' => 'USA', # A API aceita a sigla USA comercialmente
      'Paraguai' => 'Paraguay',
      'Austrália' => 'Australia',
      'Egito' => 'Egypt',
      'Turquia' => 'Turkey',
      'Alemanha' => 'Germany',
      'Curação' => 'Curacao',
      'Costa do Marfim' => 'Ivory Coast',
      'Equador' => 'Ecuador',
      'Irã' => 'Iran',
      'Holanda' => 'Netherlands',
      'Japão' => 'Japan',
      'Nova Zelândia' => 'New Zealand',
      'Espanha' => 'Spain',
      'Cabo Verde' => 'Cape Verde',
      'Suécia' => 'Sweden',
      'Tunísia' => 'Tunisia',
      'Arábia Saudita' => 'Saudi Arabia',
      'Uruguai' => 'Uruguay',
      'França' => 'France',
      'Argentina' => 'Argentina',
      'Senegal' => 'Senegal',
      'Argélia' => 'Algeria',
      'Iraque' => 'Iraq',
      'Noruega' => 'Norway',
      'Portugal' => 'Portugal',
      'RD Congo' => 'Congo DR',
      'Áustria' => 'Austria',
      'Uzbequistão' => 'Uzbekistan',
      'Colômbia' => 'Colombia',
      'Jordânia' => 'Jordan',
      'Gana' => 'Ghana',
      'Inglaterra' => 'England',
      'Cróacia' => 'Croatia',
      'Croácia' => 'Croatia',
      'Panamá' => 'Panama',
      'Coreia do Sul' => 'South Korea',
      'Coréia do Sul' => 'South Korea',
      'República Tcheca' => 'Czech Republic',
      'México' => 'Mexico',
      'África do Sul' => 'South Africa'
    }.freeze

    WORLD_CUP_TEAM_CODES = {
      'Brasil' => 'BRA',
      'Canadá' => 'CAN',
      'Bósnia e Herzegovina' => 'BIH',
      'Catar' => 'QAT',
      'Suíça' => 'SUI',
      'Suiça' => 'SUI',
      'Marrocos' => 'MAR',
      'Haiti' => 'HAI',
      'Escócia' => 'SCO',
      'Bélgica' => 'BEL',
      'Estados Unidos' => 'USA',
      'Paraguai' => 'PAR',
      'Austrália' => 'AUS',
      'Egito' => 'EGY',
      'Turquia' => 'TUR',
      'Alemanha' => 'GER',
      'Curação' => 'CUW',
      'Costa do Marfim' => 'CIV',
      'Equador' => 'ECU',
      'Irã' => 'IRN',
      'Holanda' => 'NED',
      'Japão' => 'JPN',
      'Nova Zelândia' => 'NZL',
      'Espanha' => 'ESP',
      'Cabo Verde' => 'CPV',
      'Suécia' => 'SWE',
      'Tunísia' => 'TUN',
      'Arábia Saudita' => 'KSA',
      'Uruguai' => 'URU',
      'França' => 'FRA',
      'Argentina' => 'ARG',
      'Senegal' => 'SEN',
      'Argélia' => 'ALG',
      'Iraque' => 'IRQ',
      'Noruega' => 'NOR',
      'Portugal' => 'POR',
      'RD Congo' => 'CON',
      'Áustria' => 'AUT',
      'Uzbequistão' => 'UZB',
      'Colômbia' => 'COL',
      'Jordânia' => 'JOR',
      'Jordania' => 'JOR',
      'Gana' => 'GHA',
      'Inglaterra' => 'ENG',
      'Cróacia' => 'CRO',
      'Croácia' => 'CRO',
      'Panamá' => 'PAN',
      'Coreia do Sul' => 'KOR',
      'Coréia do Sul' => 'KOR',
      'República Tcheca' => 'CZE',
      'México' => 'MEX',
      'África do Sul' => 'RSA'
    }.freeze

    def self.api_search_name(local_name)
      return nil if local_name.nil? || local_name.to_s.strip.empty?

      normalized = local_name.to_s.strip
      WORLD_CUP_TEAM_SEARCH.fetch(normalized, normalized)
    end

    def self.api_team_code(local_name)
      return nil if local_name.nil? || local_name.to_s.strip.empty?

      normalized = local_name.to_s.strip
      WORLD_CUP_TEAM_CODES[normalized] || code_by_normalized_name(normalized)
    end

    def self.code_by_normalized_name(local_name)
      normalized_lookup = I18n.transliterate(local_name).downcase

      WORLD_CUP_TEAM_CODES.find do |name, _code|
        I18n.transliterate(name).downcase == normalized_lookup
      end&.last
    end
  end
end
