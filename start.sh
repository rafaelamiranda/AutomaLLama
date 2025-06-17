#!/bin/bash
# Saia imediatamente se qualquer comando falhar
set -e
echo "🧹 Limpando containers, redes e volumes antigos..."
# Derruba o stack atual e remove volumes anônimos
docker compose down -v
# Força remoção de qualquer container existente (mesmo fora do compose)
echo "🗑️ Removendo todos os containers antigos..."
docker rm -f $(docker ps -aq) 2>/dev/null || true
# Remove redes não utilizadas
echo "🔌 Limpando redes órfãs..."
docker network prune -f
# Remove volumes não utilizados
echo "💾 Limpando volumes órfãos..."
docker volume prune -f
echo "🚀 Subindo os serviços..."
docker compose up -d --force-recreate
echo ""
echo "✅ Stack iniciado com sucesso!"
echo ""
echo "🌐 Endpoints disponíveis (via Nginx):"
echo "  - N8N:                   http://localhost/n8n/"
echo "  - Open WebUI:            http://localhost/open-webui/"
echo "  - Nginx (raiz, redireciona para N8N): http://localhost"
echo ""
echo "⚙️ Portas diretas dos serviços (para uso avançado/interno):"
echo "  - N8N (direto):          http://localhost:5678"
echo "  - Open WebUI (direto):   http://localhost:3000"
echo "  - Ollama API:            http://localhost:11434"
echo ""
echo "📦 Containers em execução:"
docker ps --format "  - {{.Names}} ({{.Status}})"
echo ""
echo "🧠 Dica: use 'docker logs -f <nome>' para ver os logs de qualquer container."