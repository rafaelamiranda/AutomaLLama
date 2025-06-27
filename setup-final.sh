#!/bin/bash

# Script de configuração FINAL para Open Web UI + Ollama + SearxNG
# Para Linux Mint / Ubuntu - Versão Completa

set -e

echo "🚀 Configurando ambiente completo: Open Web UI + Ollama + SearxNG"
echo "=================================================================="

# Verificar se o Docker está instalado
if ! command -v docker &> /dev/null; then
    echo "❌ Docker não encontrado. Instalando Docker..."
    
    # Atualizar sistema
    sudo apt update
    
    # Instalar dependências
    sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release openssl
    
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

# Verificar dependências adicionais
echo "📦 Verificando dependências..."
sudo apt install -y openssl curl wget netstat-nat || true

# Criar diretórios necessários
echo "📁 Criando estrutura de diretórios..."
mkdir -p data/ollama
mkdir -p data/webui
mkdir -p data/redis
mkdir -p searxng
mkdir -p backups

# Definir permissões corretas
sudo chown -R $USER:$USER data/ 2>/dev/null || true

# Gerar chaves secretas aleatórias
echo "🔑 Gerando chaves secretas..."
WEBUI_SECRET=$(openssl rand -hex 32)
SEARXNG_SECRET=$(openssl rand -hex 32)

# Criar arquivo .env se não existir ou atualizar chaves
if [ ! -f .env ]; then
    echo "📝 Criando arquivo .env..."
    cp .env.example .env
fi

# Atualizar as chaves secretas no arquivo .env
sed -i "s/WEBUI_SECRET_KEY=.*/WEBUI_SECRET_KEY=${WEBUI_SECRET}/" .env
sed -i "s/SEARXNG_SECRET=.*/SEARXNG_SECRET=${SEARXNG_SECRET}/" .env

echo "✅ Chaves secretas atualizadas no .env"

# Criar configuração otimizada do SearxNG
echo "⚙️  Criando configuração otimizada do SearxNG..."

cat > searxng/settings.yml << EOF
# Configuração otimizada do SearxNG para AutomaLLama
use_default_settings: true

general:
  debug: false
  instance_name: "AutomaLLama Search"
  privacypolicy_url: false
  donation_url: false
  contact_url: false
  enable_metrics: false

search:
  safe_search: 0
  autocomplete: "google"
  autocomplete_min: 2
  default_lang: "pt-BR"
  ban_time_on_fail: 5
  max_ban_time_on_fail: 120
  suspended_times:
    - 86400    # 1 dia
    - 259200   # 3 dias
    - 604800   # 7 dias
    - 2592000  # 30 dias
  formats:
    - html
    - json

server:
  port: 8080
  bind_address: "0.0.0.0"
  secret_key: "${SEARXNG_SECRET}"
  base_url: false
  image_proxy: true
  http_protocol_version: "1.1"
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
  query_in_title: true
  infinite_scroll: false
  center_alignment: false
  cache_url: true
  search_on_category_select: true
  hotkeys: default
  theme_args:
    simple_style: auto

# Configurações essenciais de mecanismos de busca
engines:
  # Busca geral - principais
  - name: google
    engine: google
    shortcut: g
    use_mobile_ui: false
    disabled: false
    
  - name: bing
    engine: bing
    shortcut: b
    disabled: false
    
  - name: duckduckgo
    engine: duckduckgo
    no_cache: true
    shortcut: ddg
    disabled: false
    
  - name: startpage
    engine: startpage
    shortcut: sp
    timeout: 6.0
    disabled: false
    
  # Imagens
  - name: google images
    engine: google_images
    shortcut: goi
    disabled: false
    
  # Notícias
  - name: google news
    engine: google_news
    shortcut: gon
    disabled: false
    
  # Conhecimento
  - name: wikipedia
    engine: wikipedia
    shortcut: wp
    base_url: 'https://{language}.wikipedia.org/'
    number_of_results: 10
    disabled: false
    
  # Desenvolvimento
  - name: github
    engine: github
    shortcut: gh
    disabled: false
    
  - name: stackoverflow
    engine: stackoverflow
    shortcut: so
    disabled: false
    
  # Redes sociais
  - name: reddit
    engine: reddit
    shortcut: re
    page_size: 25
    disabled: false
    
  # Vídeos
  - name: youtube
    engine: youtube_noapi
    shortcut: yt
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
  
  videos:
    - youtube
  
  news:
    - google news
  
  social:
    - reddit
  
  it:
    - github
    - stackoverflow

# Localização
locales:
  pt: Português
  pt-BR: Português (Brasil)
  en: English

# Configurações de saída
outgoing:
  request_timeout: 10.0
  max_request_timeout: 60.0
  pool_connections: 100
  pool_maxsize: 20
  enable_http2: true
EOF

echo "✅ Configuração do SearxNG criada"

# Verificar se os arquivos de configuração existem
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Arquivo docker-compose.yml não encontrado!"
    echo "Certifique-se de que todos os arquivos estão no diretório correto."
    exit 1
fi

# Tornar scripts executáveis
chmod +x *.sh 2>/dev/null || true

# Criar network se não existir
docker network create ai-network 2>/dev/null || true

# Baixar imagens Docker
echo "⬇️  Baixando imagens Docker..."
echo "Isso pode demorar alguns minutos na primeira vez..."
docker-compose pull

# Configurar permissões finais
echo "🔧 Configurando permissões finais..."
sudo chown -R $USER:$USER data/ 2>/dev/null || true
sudo chown -R 977:977 searxng/ 2>/dev/null || {
    echo "⚠️  Aviso: Não foi possível definir permissões do SearxNG. Pode ser necessário executar com sudo"
}

# Iniciar serviços
echo "▶️  Iniciando serviços pela primeira vez..."
docker-compose up -d

# Aguardar serviços iniciarem
echo "⏳ Aguardando serviços iniciarem (30 segundos)..."
sleep 30

# Verificar status dos serviços
echo ""
echo "📊 Verificando status dos serviços..."

services_ok=0
total_services=4

# Teste Open Web UI
echo "🌐 Testando Open Web UI..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 | grep -q "200\|302"; then
    echo "  ✅ Open Web UI: OK (http://localhost:3000)"
    ((services_ok++))
else
    echo "  ❌ Open Web UI: Não responde"
fi

# Teste SearxNG
echo "🔍 Testando SearxNG..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep -q "200"; then
    echo "  ✅ SearxNG: OK (http://localhost:8080)"
    ((services_ok++))
    
    # Teste de busca
    if curl -s "http://localhost:8080/search?q=test&format=json" | grep -q "results"; then
        echo "  ✅ SearxNG: Busca funcionando"
    else
        echo "  ⚠️  SearxNG: Interface OK mas busca pode ter problemas"
    fi
else
    echo "  ❌ SearxNG: Não responde"
fi

# Teste Ollama
echo "🧠 Testando Ollama..."
if curl -s http://localhost:11434/api/tags &>/dev/null; then
    echo "  ✅ Ollama API: OK (http://localhost:11434)"
    ((services_ok++))
else
    echo "  ❌ Ollama API: Não responde"
fi

# Teste Redis
echo "💾 Testando Redis..."
if docker exec redis redis-cli ping 2>/dev/null | grep -q "PONG"; then
    echo "  ✅ Redis: OK"
    ((services_ok++))
else
    echo "  ❌ Redis: Não responde"
fi

echo ""
echo "=============================================="

if [ $services_ok -eq $total_services ]; then
    echo "🎉 CONFIGURAÇÃO CONCLUÍDA COM SUCESSO!"
    echo "Todos os $total_services serviços estão funcionando!"
else
    echo "⚠️  CONFIGURAÇÃO CONCLUÍDA COM AVISOS"
    echo "$services_ok de $total_services serviços estão funcionando"
    echo "Alguns serviços podem ainda estar iniciando..."
fi

echo ""
echo "🌐 URLS DE ACESSO:"
echo "• Open Web UI: http://localhost:3000"
echo "• SearxNG: http://localhost:8080" 
echo "• Ollama API: http://localhost:11434"
echo ""

echo "🧠 PRÓXIMOS PASSOS - INSTALAR MODELOS:"
echo ""
echo "1. Modelo pequeno e rápido (1.3GB):"
echo "   docker exec -it ollama ollama pull llama3.2:1b"
echo ""
echo "2. Modelo médio e balanceado (2GB):"
echo "   docker exec -it ollama ollama pull llama3.2:3b"
echo ""
echo "3. Modelo otimizado para português (4GB):"
echo "   docker exec -it ollama ollama pull sabia-2:7b"
echo ""

echo "📋 COMANDOS ÚTEIS:"
echo "• Ver status: docker-compose ps"
echo "• Ver logs: docker-compose logs -f"
echo "• Parar tudo: docker-compose down"
echo "• Reiniciar: docker-compose restart"
echo "• Gerenciar: ./manage.sh help"
echo ""

echo "🔧 EM CASO DE PROBLEMAS:"
echo "• Diagnóstico: ./diagnostics.sh"
echo "• Logs específ