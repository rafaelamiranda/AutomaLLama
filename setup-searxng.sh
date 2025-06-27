#!/bin/bash

# Script para configurar e verificar o SearxNG
# Garante que todas as configurações estejam corretas

set -e

echo "🔍 Configurando SearxNG para AutomaLLama"
echo "========================================"

# Verificar se o arquivo .env existe
if [ ! -f ".env" ]; then
    echo "❌ Arquivo .env não encontrado!"
    echo "Execute: ./setup.sh primeiro"
    exit 1
fi

# Carregar variáveis do .env
source .env

# Criar diretório do SearxNG se não existir
mkdir -p searxng

# Verificar se settings.yml existe e tem configuração correta
if [ ! -f "searxng/settings.yml" ] || grep -q "__SEARXNG_SECRET__" searxng/settings.yml; then
    echo "⚙️  Criando/atualizando configuração do SearxNG..."
    
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

# Configurações de mecanismos de busca
engines:
  # Busca geral
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
    
  - name: bing images
    engine: bing_images
    shortcut: bii
    disabled: false
    
  # Notícias
  - name: google news
    engine: google_news
    shortcut: gon
    disabled: false
    
  - name: bing news
    engine: bing_news
    shortcut: bin
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
    
  - name: gitlab
    engine: gitlab
    shortcut: gl
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
    
  # Mapas
  - name: openstreetmap
    engine: openstreetmap
    shortcut: osm
    disabled: false
    
  # Ciência
  - name: arxiv
    engine: arxiv
    shortcut: arx
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
  
  videos:
    - youtube
  
  news:
    - google news
    - bing news
  
  social:
    - reddit
  
  map:
    - openstreetmap
  
  it:
    - github
    - stackoverflow
    - gitlab
  
  science:
    - arxiv
    - wikipedia

# Localização
locales:
  pt: Português
  pt-BR: Português (Brasil)
  en: English
  es: Español

# Configurações de saída
outgoing:
  request_timeout: 10.0
  max_request_timeout: 60.0
  pool_connections: 100
  pool_maxsize: 20
  enable_http2: true
EOF
    
    echo "✅ Configuração do SearxNG atualizada!"
fi

# Configurar permissões corretas
echo "🔧 Configurando permissões..."
sudo chown -R 977:977 searxng/ 2>/dev/null || {
    echo "⚠️  Não foi possível definir permissões com sudo, tentando sem..."
    chown -R 977:977 searxng/ 2>/dev/null || true
}

# Verificar se os serviços estão rodando
echo "📊 Verificando serviços..."

if docker-compose ps | grep -q "Up"; then
    echo "✅ Alguns serviços estão rodando"
    
    # Reiniciar SearxNG para aplicar novas configurações
    echo "🔄 Reiniciando SearxNG..."
    docker-compose restart searxng
    
    # Aguardar um pouco
    sleep 5
    
    # Testar SearxNG
    echo "🔍 Testando SearxNG..."
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep -q "200"; then
        echo "✅ SearxNG está funcionando!"
        
        # Teste de busca
        if curl -s "http://localhost:8080/search?q=test&format=json" | grep -q "results"; then
            echo "✅ Teste de busca bem-sucedido!"
        else
            echo "⚠️  SearxNG está rodando mas a busca pode não estar funcionando"
        fi
    else
        echo "❌ SearxNG não está respondendo"
        echo "💡 Verifique os logs: docker-compose logs searxng"
    fi
else
    echo "ℹ️  Serviços não estão rodando. Execute: docker-compose up -d"
fi

# Verificar integração com Open Web UI
echo ""
echo "🔗 Verificando integração com Open Web UI..."
if grep -q "SEARXNG_QUERY_URL" docker-compose.yml; then
    echo "✅ Open Web UI está configurado para usar SearxNG"
else
    echo "⚠️  Configuração de integração pode estar faltando"
fi

echo ""
echo "📋 Informações importantes:"
echo "• SearxNG URL: http://localhost:8080"
echo "• Para usar no Open Web UI, a busca web deve estar habilitada"
echo "• O Open Web UI detectará automaticamente o SearxNG"
echo ""

echo "🧪 Comandos de teste:"
echo "• Teste básico: curl http://localhost:8080"
echo "• Busca simples: curl 'http://localhost:8080/search?q=teste'"
echo "• Ver logs: docker-compose logs searxng"
echo ""

echo "✅ Configuração do SearxNG finalizada!"