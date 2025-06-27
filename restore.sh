#!/bin/bash

# Script de restauração para Open Web UI + Ollama + SearxNG
# Restaura backup completo dos dados e configurações

set -e

if [ $# -eq 0 ]; then
    echo "❌ Uso: $0 <arquivo_backup.tar.gz>"
    echo ""
    echo "Backups disponíveis:"
    ls -lah ./backups/automa_llama_backup_*.tar.gz 2>/dev/null | tail -5 || echo "   Nenhum backup encontrado"
    exit 1
fi

BACKUP_FILE="$1"

# Verificar se o arquivo existe
if [ ! -f "./backups/$BACKUP_FILE" ] && [ ! -f "$BACKUP_FILE" ]; then
    echo "❌ Arquivo de backup não encontrado: $BACKUP_FILE"
    exit 1
fi

# Usar caminho completo
if [ -f "./backups/$BACKUP_FILE" ]; then
    BACKUP_PATH="./backups/$BACKUP_FILE"
else
    BACKUP_PATH="$BACKUP_FILE"
fi

echo "🔄 Iniciando restauração do AutomaLLama..."
echo "Arquivo: $BACKUP_PATH"
echo "==============================================="

# Confirmar ação
read -p "⚠️  Esta ação irá sobrescrever os dados atuais. Continuar? [y/N]: " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Restauração cancelada"
    exit 1
fi

# Parar serviços
echo "⏹️  Parando serviços..."
docker-compose down

# Fazer backup dos dados atuais
if [ -d "data" ] || [ -d "searxng" ]; then
    CURRENT_BACKUP="./backups/pre_restore_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
    echo "💾 Fazendo backup dos dados atuais em: $CURRENT_BACKUP"
    mkdir -p ./backups
    tar czf "$CURRENT_BACKUP" data/ searxng/ .env 2>/dev/null || true
    echo "✅ Backup atual salvo!"
fi

# Restaurar backup
echo "📦 Restaurando backup..."
tar xzf "$BACKUP_PATH" -C .

# Corrigir permissões após restauração
echo "🔧 Corrigindo permissões..."
sudo chown -R $USER:$USER data/ 2>/dev/null || true
sudo chown -R 977:977 searxng/ 2>/dev/null || true
chmod +x *.sh 2>/dev/null || true

# Verificar se o arquivo .env foi restaurado corretamente
if [ ! -f ".env" ]; then
    echo "⚠️  Arquivo .env não encontrado no backup, criando um novo..."
    cp .env.example .env
    
    # Gerar novas chaves secretas
    WEBUI_SECRET=$(openssl rand -hex 32)
    SEARXNG_SECRET=$(openssl rand -hex 32)
    
    sed -i "s/WEBUI_SECRET_KEY=.*/WEBUI_SECRET_KEY=${WEBUI_SECRET}/" .env
    sed -i "s/SEARXNG_SECRET=.*/SEARXNG_SECRET=${SEARXNG_SECRET}/" .env
    
    echo "✅ Novo arquivo .env criado com chaves atualizadas"
fi

# Verificar estrutura de diretórios
echo "📁 Verificando estrutura de diretórios..."
mkdir -p data/{ollama,webui,redis}
mkdir -p searxng
mkdir -p backups

# Atualizar configuração do SearxNG com as chaves do .env
if [ -f "searxng/settings.yml" ] && [ -f ".env" ]; then
    echo "🔑 Atualizando chaves secretas no SearxNG..."
    source .env
    
    # Substituir a chave secreta no arquivo de configuração do SearxNG
    if grep -q "__SEARXNG_SECRET__" searxng/settings.yml; then
        sed -i "s/__SEARXNG_SECRET__/$SEARXNG_SECRET/" searxng/settings.yml
    fi
fi

# Recriar network se necessário
echo "🌐 Configurando rede Docker..."
docker network create ai-network 2>/dev/null || true

# Iniciar serviços
echo "▶️  Iniciando serviços..."
docker-compose up -d

# Aguardar serviços iniciarem
echo "⏳ Aguardando serviços iniciarem..."
sleep 10

# Verificar status dos serviços
echo "📊 Verificando status dos serviços..."
services_ok=0

# Teste Open Web UI
if curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 | grep -q "200\|302"; then
    echo "✅ Open Web UI respondendo"
    ((services_ok++))
else
    echo "⚠️  Open Web UI ainda não está respondendo"
fi

# Teste SearxNG
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep -q "200"; then
    echo "✅ SearxNG respondendo"
    ((services_ok++))
else
    echo "⚠️  SearxNG ainda não está respondendo"
fi

# Teste Ollama
if curl -s http://localhost:11434/api/tags &>/dev/null; then
    echo "✅ Ollama API respondendo"
    ((services_ok++))
else
    echo "⚠️  Ollama API ainda não está respondendo"
fi

# Teste Redis
if docker exec redis redis-cli ping 2>/dev/null | grep -q "PONG"; then
    echo "✅ Redis respondendo"
    ((services_ok++))
else
    echo "⚠️  Redis ainda não está respondendo"
fi

echo ""
if [ $services_ok -eq 4 ]; then
    echo "🎉 Restauração concluída com sucesso!"
    echo "Todos os serviços estão funcionando corretamente."
else
    echo "⚠️  Restauração concluída, mas alguns serviços podem ainda estar iniciando."
    echo "Execute 'docker-compose logs -f' para verificar os logs."
fi

echo ""
echo "🌐 URLs de Acesso:"
echo "• Open Web UI: http://localhost:3000"
echo "• SearxNG: http://localhost:8080"
echo "• Ollama API: http://localhost:11434"
echo ""
echo "📋 Comandos úteis:"
echo "• Ver status: docker-compose ps"
echo "• Ver logs: docker-compose logs -f"
echo "• Reiniciar: docker-compose restart"
echo "• Parar: docker-compose down"
echo ""

# Mostrar informações sobre modelos se Ollama estiver funcionando
if curl -s http://localhost:11434/api/tags &>/dev/null; then
    echo "🧠 Modelos Ollama disponíveis:"
    docker exec ollama ollama list 2>/dev/null || echo "   Nenhum modelo instalado ainda"
    echo ""
    echo "Para instalar modelos básicos:"
    echo "  docker exec -it ollama ollama pull llama3.2:1b  # Modelo pequeno (1.3GB)"
    echo "  docker exec -it ollama ollama pull llama3.2:3b  # Modelo médio (2GB)"
fi

echo "==============================================="
echo "✅ Processo de restauração finalizado!"