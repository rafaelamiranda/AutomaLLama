#!/bin/bash

# Script de configuração para Open Web UI + Ollama + SearxNG
# Para Linux Mint / Ubuntu

set -e

echo "🚀 Configurando ambiente Open Web UI + Ollama + SearxNG"
echo "========================================================"

# Verificar se o Docker está instalado
if ! command -v docker &> /dev/null; then
    echo "❌ Docker não encontrado. Instalando Docker..."
    
    # Atualizar sistema
    sudo apt update
    
    # Instalar dependências
    sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
    
    # Adicionar chave GPG do Docker
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Adicionar repositório do Docker
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Instalar Docker
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io
    
    # Adicionar usuário ao grupo docker
    sudo usermod -aG docker $USER
    
    echo "✅ Docker instalado com sucesso!"
    echo "⚠️  Você precisa fazer logout e login novamente para usar o Docker sem sudo"
fi

# Verificar se o Docker Compose está instalado
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose não encontrado. Instalando..."
    
    # Baixar Docker Compose
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    
    # Dar permissão de execução
    sudo chmod +x /usr/local/bin/docker-compose
    
    echo "✅ Docker Compose instalado com sucesso!"
fi

# Criar diretórios necessários
echo "📁 Criando estrutura de diretórios..."
mkdir -p data/ollama
mkdir -p data/webui
mkdir -p data/redis
mkdir -p searxng
mkdir -p backups

# Definir permissões corretas
sudo chown -R $USER:$USER data/
sudo chown -R $USER:$USER searxng/

# Criar configuração do SearxNG se não existir
if [ ! -f "searxng/settings.yml" ]; then
    echo "⚙️  Criando configuração do SearxNG..."
    
    cat > searxng/settings.yml << 'EOF'
# Configuração do SearxNG
use_default_settings: true

general:
  debug: false
  instance_name: "SearxNG Local"
  privacypolicy_url: false
  donation_url: false
  contact_url: false
  enable_metrics: false

search:
  safe_search: 0
  autocomplete: "google"
  autocomplete_min: 4
  default_lang: "pt-BR"
  ban_time_on_fail: 5
  max_ban_time_on_fail: 120
  formats:
    - html
    - json

server:
  port: 8080
  bind_address: "0.0.0.0"
  secret_key: "changeme"
  base_url: false
  image_proxy: false
  http_protocol_version: "1.0"
  method: "POST"
  default_http_headers:
    X-Content-Type-Options: nosniff
    X-XSS-Protection: 1; mode=block
    X-Download-Options: noopen
    X-Robots-Tag: noindex, nofollow
    Referrer-Policy: no-referrer

redis:
  url: redis://redis:6379/0

ui:
  static_use_hash: false
  default_locale: "pt-BR"
  query_in_title: false
  infinite_scroll: false
  center_alignment: false
  cache_url: false
  search_on_category_select: true
  hotkeys: default
  theme_args:
    simple_style: auto

# Configurações de mecanismos de busca
engines:
  - name: google
    engine: google
    shortcut: g
    disabled: false
    
  - name: bing
    engine: bing
    shortcut: b
    disabled: false
    
  - name: duckduckgo
    engine: duckduckgo
    shortcut: ddg
    disabled: false
    
  - name: startpage
    engine: startpage
    shortcut: sp
    disabled: false
    
  - name: wikipedia
    engine: wikipedia
    shortcut: wp
    disabled: false
    
  - name: reddit
    engine: reddit
    shortcut: re
    disabled: false
    
  - name: github
    engine: github
    shortcut: gh
    disabled: false
    
  - name: stackoverflow
    engine: stackoverflow
    shortcut: so
    disabled: false

# Configurações de categorias
categories_as_tabs:
  general:
    - google
    - bing
    - duckduckgo
    - startpage
  
  images:
    - google images
    - bing images
  
  news:
    - google news
    - bing news
  
  social:
    - reddit
  
  it:
    - github
    - stackoverflow
EOF
    
    echo "✅ Configuração do SearxNG criada"
fi

# Gerar chaves secretas aleatórias se não existirem
if [ ! -f .env ]; then
    echo "🔑 Gerando arquivo .env com chaves secretas..."
    
    WEBUI_SECRET=$(openssl rand -hex 32)
    SEARXNG_SECRET=$(openssl rand -hex 32)
    
    cp .env .env
    
    # Atualizar as chaves secretas no arquivo .env
    sed -i "s/WEBUI_SECRET_KEY=.*/WEBUI_SECRET_KEY=${WEBUI_SECRET}/" .env
    sed -i "s/SEARXNG_SECRET=.*/SEARXNG_SECRET=${SEARXNG_SECRET}/" .env
    
    echo "✅ Chaves secretas atualizadas no .env"
fi

# Verificar se os arquivos de configuração existem
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Arquivo docker-compose.yml não encontrado!"
    echo "Certifique-se de que todos os arquivos estão no diretório correto."
    exit 1
fi

# Criar network se não existir
docker network create ai-network 2>/dev/null || true

# Baixar imagens Docker
echo "⬇️  Baixando imagens Docker..."
docker-compose pull

# Configurar permissões do SearxNG
echo "🔧 Configurando permissões..."
sudo chown -R 977:977 searxng/ 2>/dev/null || true

echo ""
echo "✅ Configuração concluída!"
echo ""
echo "Para iniciar o sistema:"
echo "  docker-compose up -d"
echo ""
echo "Para baixar alguns modelos do Ollama:"
echo "  # Modelo pequeno e rápido (1.3GB)"
echo "  docker exec -it ollama ollama pull llama3.2:1b"
echo ""
echo "  # Modelo médio e balanceado (2GB)"
echo "  docker exec -it ollama ollama pull llama3.2:3b"
echo ""
echo "  # Modelo português otimizado (4GB)"
echo "  docker exec -it ollama ollama pull sabia-2:7b"
echo ""
echo "URLs de acesso:"
echo "  • Open Web UI: http://localhost:3000"
echo "  • SearxNG: http://localhost:8080"
echo "  • Ollama API: http://localhost:11434"
echo ""
echo "Para parar os serviços:"
echo "  docker-compose down"
echo ""
echo "Para ver logs:"
echo "  docker-compose logs -f"
echo ""
echo "Para reiniciar um serviço:"
echo "  docker-compose restart searxng"