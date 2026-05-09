class Rack::Attack

  # =========================
  # Limite geral por IP
  # =========================
  throttle('requests por ip', limit: 300, period: 5.minutes) do |req|
    req.ip
  end

  # =========================
  # Proteção login Devise
  # =========================
  throttle('logins por ip', limit: 5, period: 20.seconds) do |req|
    if req.path == '/users/sign_in' && req.post?
      req.ip
    end
  end

  # =========================
  # Proteção cadastro
  # =========================
  throttle('cadastros por ip', limit: 3, period: 1.minute) do |req|
    if req.path == '/users' && req.post?
      req.ip
    end
  end

  # =========================
  # Bloquear scanners comuns
  # =========================
  blocklist('bloquear scanners') do |req|
    malicious_paths = [
      '/wp-admin',
      '/wp-login',
      '/phpmyadmin',
      '/.env',
      '/config',
      '/admin'
    ]

    malicious_paths.any? { |path| req.path.include?(path) }
  end

end