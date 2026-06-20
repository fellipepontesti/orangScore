module Jogos
  module TeamMapping
    WORLD_CUP_TEAM_SEARCH = {
      'Brasil' => 'Brazil',
      'Canadá' => 'Canada',
      'Bósnia e Herzegovina' => 'Bosnia and Herzegovina',
      'Catar' => 'Qatar',
      'Qatar' => 'Qatar',
      'Suíça' => 'Switzerland',
      'Suiça' => 'Switzerland',
      'Marrocos' => 'Morocco',
      'Haiti' => 'Haiti',
      'Escócia' => 'Scotland',
      'Bélgica' => 'Belgium',
      'Estados Unidos' => 'United States',
      'Paraguai' => 'Paraguay',
      'Austrália' => 'Australia',
      'Egito' => 'Egypt',
      'Turquia' => 'Türkiye',
      'Alemanha' => 'Germany',
      'Curação' => 'Curaçao',
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
      'RD Congo' => 'DR Congo',
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
      'RD Congo' => 'COD',
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

    ADDITIONAL_COUNTRY_TRANSLATIONS = {
      'Korea Republic' => 'Coréia do Sul',
      'Republic of Korea' => 'Coréia do Sul',
      'Côte d\'Ivoire' => 'Costa do Marfim',
      'Cote d\'Ivoire' => 'Costa do Marfim',
      'IR Iran' => 'Irã',
      'Congo DR' => 'RD Congo',
      'DR Congo' => 'RD Congo',
      'England' => 'Inglaterra',
      'Italy' => 'Itália',
      'Spain' => 'Espanha',
      'Germany' => 'Alemanha',
      'France' => 'França',
      'Portugal' => 'Portugal',
      'Netherlands' => 'Holanda',
      'Belgium' => 'Bélgica',
      'Brazil' => 'Brasil',
      'Argentina' => 'Argentina',
      'Uruguay' => 'Uruguai',
      'Colombia' => 'Colômbia',
      'Chile' => 'Chile',
      'Paraguay' => 'Paraguai',
      'Peru' => 'Peru',
      'Ecuador' => 'Equador',
      'Venezuela' => 'Venezuela',
      'Mexico' => 'México',
      'United States' => 'Estados Unidos',
      'USA' => 'Estados Unidos',
      'Canada' => 'Canadá',
      'Japan' => 'Japão',
      'South Korea' => 'Coreia do Sul',
      'China' => 'China',
      'Saudi Arabia' => 'Arábia Saudita',
      'Qatar' => 'Catar',
      'United Arab Emirates' => 'Emirados Árabes Unidos',
      'UAE' => 'Emirados Árabes Unidos',
      'Turkey' => 'Turquia',
      'Türkiye' => 'Turquia',
      'Greece' => 'Grécia',
      'Russia' => 'Rússia',
      'Ukraine' => 'Ucrânia',
      'Croatia' => 'Croácia',
      'Switzerland' => 'Suíça',
      'Austria' => 'Áustria',
      'Sweden' => 'Suécia',
      'Norway' => 'Noruega',
      'Denmark' => 'Dinamarca',
      'Poland' => 'Polônia',
      'Scotland' => 'Escócia',
      'Wales' => 'País de Gales',
      'Northern Ireland' => 'Irlanda do Norte',
      'Ireland' => 'Irlanda',
      'Morocco' => 'Marrocos',
      'Egypt' => 'Egito',
      'South Africa' => 'África do Sul',
      'Ghana' => 'Gana',
      'Nigeria' => 'Nigéria',
      'Senegal' => 'Senegal',
      'Tunisia' => 'Tunísia',
      'Algeria' => 'Argélia',
      'Ivory Coast' => 'Costa do Marfim',
      'Cameroon' => 'Camarões',
      'Australia' => 'Austrália',
      'New Zealand' => 'Nova Zelândia',
      'Czech Republic' => 'República Tcheca',
      'Czechia' => 'República Tcheca',
      'Slovakia' => 'Eslováquia',
      'Slovenia' => 'Eslovênia',
      'Hungary' => 'Hungria',
      'Romania' => 'Romênia',
      'Bulgaria' => 'Bulgária',
      'Serbia' => 'Sérvia',
      'Bosnia and Herzegovina' => 'Bósnia e Herzegovina',
      'Montenegro' => 'Montenegro',
      'Albania' => 'Albânia',
      'North Macedonia' => 'Macedônia do Norte',
      'Cyprus' => 'Chipre',
      'Israel' => 'Israel',
      'Finland' => 'Finlândia',
      'Iceland' => 'Islândia',
      'Singapore' => 'Singapura',
      'India' => 'Índia',
      'Thailand' => 'Tailândia',
      'Malaysia' => 'Malásia',
      'Indonesia' => 'Indonésia',
      'Vietnam' => 'Vietnã',
      'Iran' => 'Irã',
      'Iraq' => 'Iraque',
      'Uzbekistan' => 'Uzbequistão'
    }.freeze

    def self.translate_country(country_en)
      return nil if country_en.nil? || country_en.to_s.strip.empty?
      
      name = country_en.to_s.strip
      
      # 1. Tenta correspondência direta no hash complementar
      translated = ADDITIONAL_COUNTRY_TRANSLATIONS[name]
      return translated if translated
      
      # 2. Tenta busca case-insensitive no hash complementar
      translated = ADDITIONAL_COUNTRY_TRANSLATIONS.find { |en, _pt| en.downcase == name.downcase }&.last
      return translated if translated
      
      # 3. Tenta inverter o WORLD_CUP_TEAM_SEARCH
      matched_pt = WORLD_CUP_TEAM_SEARCH.find { |_pt, en| en.downcase == name.downcase }&.first
      return matched_pt if matched_pt
      
      # 4. Caso não encontre nada, retorna o nome original
      name
    end
  end
end
