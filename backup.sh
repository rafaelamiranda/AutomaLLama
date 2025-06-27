#!/bin/bash

# Script de backup para Open Web UI + Ollama + SearxNG
# Cria backup completo dos dados e configurações

set -e

BACKUP_DIR="./backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="automa_llama_backup_${DATE}.tar.gz"

echo "🔄 Iniciando backup do AutomaLLama..."
echo "==============================================="

# Criar diretório de backup se não existir
mkdir -p "$BACKUP_DIR"

# Parar serviços temporariamente para backup consistente
echo "⏸️  Pausando serviços para backup consistente..."
docker-compose pause

# Criar backup
echo "📦 Criando backup..."
tar czf "$BACKUP_DIR/$BACKUP_FILE" \
    --exclude='./backups' \
    --exclude='.git' \
    --exclude='*.log' \
    data/ \
    searxng/ \
    .env \
    docker-compose.yml \
    README.md \
    setup.sh

# Retomar serviços
echo "▶️  Retomando serviços..."
docker-compose unpause

# Informações do backup
BACKUP_SIZE=$(du -h "$BACKUP_DIR/$BACKUP_FILE" | cut -f1)
echo "✅ Backup criado com sucesso!"
echo "   Arquivo: $BACKUP_FILE"
echo "   Tamanho: $BACKUP_SIZE"
echo "   Local: $BACKUP_DIR/"

# Limpar backups antigos (manter apenas os 5 mais recentes)
echo "🧹 Limpando backups antigos..."
cd "$BACKUP_DIR"
ls -t automa_llama_backup_*.tar.gz | tail -n +6 | xargs rm -f 2>/dev/null || true
cd ..

echo "📊 Backups disponíveis:"
ls -lah "$BACKUP_DIR"/automa_llama_backup_*.tar.gz 2>/dev/null | tail -5 || echo "   Nenhum backup encontrado"

echo ""
echo "Para restaurar este backup:"
echo "  ./restore.sh $BACKUP_FILE"