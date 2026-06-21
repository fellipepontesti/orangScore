# 🍊 OrangScore - Bolão da Copa do Mundo 2026

O **OrangScore** é uma plataforma premium de bolão de futebol focada na Copa do Mundo de 2026. Desenvolvido em Ruby on Rails, o sistema combina uma interface moderna, dinâmica e elegante com regras robustas de pontuação, integração com APIs de dados esportivos em tempo real e processamento de pagamentos.

---

## 🚀 Tecnologias Utilizadas

* **Framework Principal:** Ruby on Rails 7.1
* **Linguagem:** Ruby 3.x
* **Banco de Dados:** PostgreSQL
* **Estilização e UI:** TailwindCSS & DaisyUI (Layout moderno com suporte a temas, cards dinâmicos e design responsivo)
* **Autenticação:** Devise (Login tradicional por e-mail/senha e Omniauth)
* **Pagamentos & Assinaturas:** Checkout Transparente e Webhooks do Mercado Pago (com suporte a Pix Direto)
* **Jobs em Segundo Plano:** ActiveJob

---

## 🎯 Principais Funcionalidades

### 👥 Área do Participante
* **Dashboard Premium:** Visão consolidada com jogos do dia (em andamento e programados), ranking global, ligas ativas e resumo de pontos acumulados.
* **Sistema de Palpites:** Registro e edição de palpites (gols do mandante e visitante) para partidas programadas.
* **Visualização de Palpites:** Painel interativo para visualizar os palpites de todos os participantes do bolão assim que o jogo começar (em andamento ou finalizado), com estatísticas em tempo real (palpite mais comum, média de gols e pontos conquistados).
* **Ranking Global e Pódio:** Pódio tridimensional 3D interativo com os três primeiros colocados e barra flutuante dinâmica para rastrear a posição do usuário logado na tabela geral.

### 🏆 Ligas (Públicas e Privadas)
* **Criação de Ligas:** Usuários de todos os planos podem criar suas próprias ligas para disputar com amigos.
* **Controle de Entrada:** Ligas privadas que exigem convite/aprovação do administrador e ligas públicas com entrada livre.
* **Ligas com Pontuação Zerada:** Opção exclusiva onde os pontos de novos membros só começam a contar a partir do momento do ingresso na liga, ideal para ligas criadas com o torneio em andamento.
* **Ligas com Pontuação Retroativa:** Ligas tradicionais que computam todo o histórico de pontos dos membros retroativamente.

### 🛡️ Painel Administrativo (Root)
* **Sincronização de Estatísticas e Elencos:** Importação automática de dados de partidas, escalações e elencos de jogadores a partir da API Zafronix.
* **Mural de Auditoria e Integridade:** Painel exclusivo que analisa os jogos finalizados, comparando o placar local, placar da API e artilharia de jogadores, sinalizando discrepâncias ou problemas de sincronização.
* **Timeline Interativa (Edição de Gols):** Capacidade de alterar autores de gols, minutos, assistências e tipo de gol (incluindo gols contra e pênaltis) diretamente na timeline da partida, disparando o recálculo automático da artilharia do campeonato.
* **Gerenciamento de Numeração:** Painel para o administrador ajustar a numeração oficial das camisas de cada seleção.

---

## 🔌 Integração com APIs

O projeto consome a **API Zafronix (World Cup v1)** para manter a base de dados sincronizada:
* **Estatísticas de Partida:** Posse de bola, finalizações, chutes no gol, passes (totais e precisão), faltas, impedimentos, cartões amarelos e vermelhos.
* **Acontecimentos (Gols & Subs):** Minuto a minuto de gols, assistências, substituições e ocorrências de gols contra.
* **Elencos:** Sincronização automática dos elencos de jogadores de todas as seleções.

---

## ⚙️ Como Executar o Projeto

### Pré-requisitos
Certifique-se de possuir instalado em sua máquina:
* Ruby (versão especificada em `.ruby-version` ou `Gemfile`)
* PostgreSQL
* Node.js & Yarn (ou npm)

### Configuração do Ambiente

1. Clone o repositório e acesse a pasta:
   ```bash
   git clone https://github.com/fellipepontesti/orangScore.git
   cd orangScore
   ```

2. Instale as dependências de Ruby e Javascript:
   ```bash
   bundle install
   yarn install
   ```

3. Configure o banco de dados e rode as migrações:
   ```bash
   rails db:create db:migrate db:seed
   ```

4. Defina suas variáveis de ambiente no arquivo `.env` (se necessário):
   * `ZAFRONIX_API_KEY` (Chave de autenticação da API de estatísticas)

### Executando o Servidor de Desenvolvimento

Para rodar a aplicação localmente compilando os arquivos CSS/JS com o Tailwind:
```bash
./bin/dev
```

> **Dica:** Você pode configurar um alias no seu terminal para iniciar o projeto mais rapidamente. Adicione ao seu `.zshrc` ou `.bashrc`:
> ```bash
> alias dev="./bin/dev"
> ```
> Depois, basta rodar `dev` no terminal do projeto.

---

## 🧪 Rodando os Testes

Para garantir o bom funcionamento do bolão, da pontuação e da integridade de dados:
```bash
rails test
```