#!/bin/bash
#
# Script final e robusto para limpar e reiniciar o ambiente Docker.
# Este script força a reconstrução da imagem do open-webui para evitar problemas de cache.
#

# Saia imediatamente se qualquer comando falhar.
set -e

# O nome do projeto é derivado do nome da pasta atual, formatado para ser um nome de imagem válido.
PROJECT_NAME=$(basename "$PWD" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9_.-]//g')
WEBUI_IMAGE_NAME="${PROJECT_NAME}-open-webui"


echo "🛑 Parando todos os serviços e limpando o ambiente do projeto..."
docker compose down --volumes --remove-orphans

echo ""
echo "🔥 Forçando a remoção da imagem antiga do Open WebUI para garantir uma reconstrução limpa..."
# O '|| true' garante que o script não falhe se a imagem não existir na primeira execução.
docker rmi "${WEBUI_IMAGE_NAME}" 2>/dev/null || true

echo ""
echo "🚀 Subindo e reconstruindo os serviços em background..."
# --build: Garante que a imagem seja reconstruída do zero, pois a antiga foi removida.
docker compose up --build --force-recreate -d

echo ""
echo "✅ Stack iniciado com sucesso!"
echo ""
echo "🌐 Acesse as aplicações através do Nginx nos seguintes links:"
echo "  - Open WebUI: http://localhost/open-webui/"
echo "  - SearxNG:    http://localhost/searxng/"
echo ""
echo "📦 Containers em execução:"
docker ps --format "  - {{.Names}} ({{.Status}})"