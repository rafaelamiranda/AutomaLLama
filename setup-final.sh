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
echo "• Logs específicos: docker-compose logs [serviço]"
echo "• Reiniciar serviço: docker-compose restart [serviço]"
echo "• Backup: ./backup.sh"
echo "• Restaurar: ./restore.sh [arquivo]"
echo ""

echo "💡 DICAS DE USO:"
echo "• Primeiro acesso ao Open Web UI: crie uma conta de administrador"
echo "• Configure o SearxNG como mecanismo de busca padrão"
echo "• Use modelos menores para testes e maiores para produção"
echo "• Monitore o uso de recursos com: docker stats"
echo ""

echo "🌟 RECURSOS AVANÇADOS:"
echo "• Integração automática SearxNG + Open Web UI"
echo "• Backup automático dos dados"
echo "• Monitoramento de saúde dos serviços"
echo "• Logs centralizados e rotativos"
echo "• Configuração otimizada para performance"
echo ""

# Criar arquivo de primeiros passos
echo "📝 Criando guia de primeiros passos..."
cat > PRIMEIROS_PASSOS.md << 'EOF'
# 🚀 Primeiros Passos - AutomaLLama

## 1. Primeiro Acesso

### Open Web UI (Interface Principal)
- Acesse: http://localhost:3000
- Na primeira vez, crie uma conta de administrador
- Esta será sua interface principal para conversar com os modelos

### SearxNG (Busca Privada)
- Acesse: http://localhost:8080
- Teste uma busca para verificar funcionamento
- Já está integrado automaticamente com o Open Web UI

## 2. Instalar Modelos de IA

### Modelos Recomendados (ordem de instalação):

```bash
# 1. Modelo pequeno para testes (1.3GB)
docker exec -it ollama ollama pull llama3.2:1b

# 2. Modelo balanceado (2GB)
docker exec -it ollama ollama pull llama3.2:3b

# 3. Modelo em português (4GB)
docker exec -it ollama ollama pull sabia-2:7b

# 4. Modelo avançado (opcional - 4.7GB)
docker exec -it ollama ollama pull llama3.2:7b
```

### Verificar modelos instalados:
```bash
docker exec -it ollama ollama list
```

## 3. Configurar Integração com Busca

1. No Open Web UI, vá em Settings (Configurações)
2. Procure por "Web Search" ou "Busca Web"
3. Configure a URL: `http://searxng:8080`
4. Teste fazendo uma pergunta que precise de informações atuais

## 4. Comandos Essenciais

```bash
# Ver status de todos os serviços
docker-compose ps

# Ver logs em tempo real
docker-compose logs -f

# Ver logs de um serviço específico
docker-compose logs -f webui
docker-compose logs -f ollama
docker-compose logs -f searxng

# Parar todos os serviços
docker-compose down

# Iniciar todos os serviços
docker-compose up -d

# Reiniciar um serviço específico
docker-compose restart webui

# Ver uso de recursos
docker stats
```

## 5. Solução de Problemas Comuns

### Serviço não responde:
```bash
# Verificar logs
docker-compose logs [nome-do-serviço]

# Reiniciar serviço
docker-compose restart [nome-do-serviço]

# Diagnóstico completo
./diagnostics.sh
```

### Falta de espaço em disco:
```bash
# Limpar containers parados
docker system prune

# Limpar imagens não utilizadas
docker image prune

# Ver uso de espaço
docker system df
```

### Performance lenta:
- Use modelos menores (1b, 3b) para testes
- Monitore uso de RAM: `htop` ou `docker stats`
- Considere aumentar swap se necessário

## 6. Backup e Restauração

```bash
# Fazer backup
./backup.sh

# Restaurar backup
./restore.sh backup-YYYY-MM-DD.tar.gz

# Backups ficam em: ./backups/
```

## 7. Atualização

```bash
# Parar serviços
docker-compose down

# Atualizar imagens
docker-compose pull

# Iniciar com novas versões
docker-compose up -d
```

## 8. URLs Importantes

- **Open Web UI**: http://localhost:3000
- **SearxNG**: http://localhost:8080
- **Ollama API**: http://localhost:11434
- **Health Check**: http://localhost:3000/health

## 9. Arquivos de Configuração

- `.env` - Variáveis de ambiente
- `docker-compose.yml` - Configuração dos serviços
- `searxng/settings.yml` - Configuração do SearxNG
- `data/` - Dados persistentes

## 10. Suporte

- Logs: `docker-compose logs`
- Diagnóstico: `./diagnostics.sh`
- Monitoramento: `./monitor.sh`
- Documentação: README.md
EOF

# Verificar se o usuário está no grupo docker
if ! groups $USER | grep -q docker; then
    echo ""
    echo "⚠️  IMPORTANTE: REINICIALIZAÇÃO NECESSÁRIA"
    echo "============================================"
    echo "O usuário foi adicionado ao grupo 'docker', mas as mudanças"
    echo "só terão efeito após logout/login ou reinicialização."
    echo ""
    echo "Para aplicar as mudanças sem reiniciar:"
    echo "1. Execute: newgrp docker"
    echo "2. Ou faça logout e login novamente"
    echo "3. Ou reinicie o sistema"
    echo ""
    echo "Depois disso, você poderá usar docker sem 'sudo'"
fi

# Verificar se há atualizações de sistema pendentes
echo ""
echo "🔄 Verificando atualizações do sistema..."
updates=$(apt list --upgradable 2>/dev/null | wc -l)
if [ $updates -gt 1 ]; then
    echo "⚠️  Há $((updates-1)) atualizações disponíveis para o sistema"
    echo "Recomendamos executar: sudo apt update && sudo apt upgrade"
fi

# Status final detalhado
echo ""
echo "📊 RESUMO FINAL DA INSTALAÇÃO"
echo "=============================================="
echo "Data/Hora: $(date)"
echo "Sistema: $(lsb_release -d | cut -f2)"
echo "Docker: $(docker --version | cut -d' ' -f3 | cut -d',' -f1)"
echo "Docker Compose: $(docker-compose --version | cut -d' ' -f3 | cut -d',' -f1)"
echo "Usuário: $USER"
echo "Diretório: $(pwd)"
echo ""

# Informações de sistema
echo "💻 RECURSOS DO SISTEMA:"
echo "CPU: $(nproc) cores"
echo "RAM: $(free -h | awk '/^Mem:/ {print $2}') total"
echo "Disco: $(df -h . | awk 'NR==2 {print $4}') disponível"
echo ""

# Portas utilizadas
echo "🔌 PORTAS UTILIZADAS:"
echo "• 3000 - Open Web UI"
echo "• 8080 - SearxNG" 
echo "• 11434 - Ollama API"
echo "• 6379 - Redis (interno)"
echo ""

# Criar script de verificação rápida
cat > quick-check.sh << 'EOF'
#!/bin/bash
echo "🔍 Verificação Rápida dos Serviços"
echo "================================="

services=("webui:3000" "searxng:8080" "ollama:11434")
all_ok=true

for service in "${services[@]}"; do
    name=$(echo $service | cut -d':' -f1)
    port=$(echo $service | cut -d':' -f2)
    
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:$port | grep -q "200\|302"; then
        echo "✅ $name (porta $port): OK"
    else
        echo "❌ $name (porta $port): FALHOU"
        all_ok=false
    fi
done

if $all_ok; then
    echo "🎉 Todos os serviços estão funcionando!"
else
    echo "⚠️  Alguns serviços têm problemas. Execute: docker-compose logs"
fi
EOF

chmod +x quick-check.sh

# Script de primeiro modelo
cat > install-first-model.sh << 'EOF'
#!/bin/bash
echo "🧠 Instalando primeiro modelo recomendado..."
echo "==========================================="
echo ""
echo "Instalando llama3.2:1b (modelo pequeno e rápido - 1.3GB)"
echo "Este é ideal para testes e conversas básicas."
echo ""
echo "⏳ Aguarde, isso pode demorar alguns minutos..."

if docker exec -it ollama ollama pull llama3.2:1b; then
    echo ""
    echo "✅ Modelo instalado com sucesso!"
    echo ""
    echo "🎯 Próximos passos:"
    echo "1. Acesse: http://localhost:3000"
    echo "2. Faça login ou crie uma conta"
    echo "3. Selecione o modelo 'llama3.2:1b'"
    echo "4. Comece a conversar!"
    echo ""
    echo "💡 Para instalar mais modelos:"
    echo "   docker exec -it ollama ollama pull llama3.2:3b"
    echo "   docker exec -it ollama ollama pull sabia-2:7b"
else
    echo "❌ Erro ao instalar o modelo. Verifique:"
    echo "• Se o Ollama está rodando: docker-compose ps"
    echo "• Se há espaço em disco suficiente: df -h"
    echo "• Os logs: docker-compose logs ollama"
fi
EOF

chmod +x install-first-model.sh

echo ""
echo "🎯 INSTALAÇÃO CONCLUÍDA!"
echo "=============================================="
echo ""
echo "✨ Scripts adicionais criados:"
echo "• quick-check.sh - Verificação rápida dos serviços"
echo "• install-first-model.sh - Instala o primeiro modelo"
echo "• PRIMEIROS_PASSOS.md - Guia completo"
echo ""
echo "🚀 PRÓXIMO PASSO RECOMENDADO:"
echo "Execute: ./install-first-model.sh"
echo ""
echo "🌟 Sua instalação AutomaLLama está pronta!"
echo "Acesse http://localhost:3000 para começar a usar."
echo ""
echo "📚 Para mais informações, leia: PRIMEIROS_PASSOS.md"
echo "=============================================="