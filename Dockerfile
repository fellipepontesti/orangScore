# syntax = docker/dockerfile:1

# Define versão do Ruby (tem que bater com seu projeto)
ARG RUBY_VERSION=3.3.10
FROM ruby:${RUBY_VERSION}-slim as base

# Evita prompts interativos (importante em Docker)
ENV DEBIAN_FRONTEND=noninteractive

# Diretório da aplicação
WORKDIR /rails

# Variáveis de ambiente padrão de produção
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development"

# =========================
# STAGE 1 — BUILD
# =========================
FROM base as build

# Instala dependências necessárias para:
# - compilar gems
# - rodar Node (Tailwind + DaisyUI)
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    git \
    curl \
    libvips \
    pkg-config \
    libyaml-dev && \
    rm -rf /var/lib/apt/lists/*

# Instala Node.js (versão leve via NodeSource)
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs

# Copia apenas arquivos de dependência primeiro (cache de build)
COPY Gemfile Gemfile.lock ./

# Instala gems
RUN bundle install && \
    # Limpa cache pra reduzir tamanho
    rm -rf ~/.bundle \
           "${BUNDLE_PATH}"/ruby/*/cache \
           "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

# Copia o restante da aplicação
COPY . .

# Instala dependências JS (incluindo daisyUI via package.json)
RUN npm install && npm cache clean --force

# Pré-compila bootsnap (melhora performance)
RUN bundle exec bootsnap precompile app/ lib/

# Compila assets (CSS/JS)
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# =========================
# STAGE 2 — RUNTIME (leve)
# =========================
FROM base

# Apenas libs necessárias para rodar (sem build tools)
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    curl \
    libsqlite3-0 \
    libvips && \
    rm -rf /var/lib/apt/lists/*

# Copia gems e app já buildado
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /rails /rails

# Cria usuário seguro (não root)
RUN useradd rails --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp

USER rails:rails

# Script padrão do Rails (migrations, etc)
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Porta padrão
EXPOSE 3000

# Inicializa o Puma
CMD ["bundle","exec","puma","-C","config/puma.rb"]