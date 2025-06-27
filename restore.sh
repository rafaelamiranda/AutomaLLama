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
    tar czf "$CURRENT_BACKUP" data/ searxng/ .env 2>/dev/null || true
fi

# Restaurar backup
echo "📦 Restaurando backup..."