#!/bin/bash

# Script de diagnóstico para Open Web UI + Ollama + SearxNG
# Verifica o status e configuração de todos os serviços

echo "🔍 Diagnóstico do AutomaLLama"
echo "=========================================="
echo "Data: $(date)"
echo ""

# Informações do sistema
echo "💻 INFORMAÇÕES DO SISTEMA:"
echo "OS: $(lsb_release -d | cut -f2)"
echo "Kernel: $(uname -r)"
echo "Arquitetura: $(uname -m)"
echo "RAM Total: $(free -h | grep Mem | awk '{print $2}')"
echo "RAM Disponível: $(free -h | grep Mem | awk '{print $7}')"
echo "Espaço em Disco: $(df -h . | tail -1 | awk '{print $4}')"
echo ""

# Verificar Docker
echo "🐳 DOCKER:"
if command -v docker &> /dev/null; then
    echo "✅ Docker instalado: $(docker --version)"
    echo "✅ Docker rodando: $(sudo systemctl is-active docker)"
else
    echo "❌ Docker não encontrado"
fi

if command -v docker-compose &> /dev/null; then
    echo "✅ Docker Compose: $(docker-compose --version)"
else
    echo "❌ Docker Compose não encontrado"
fi
echo ""

# Verificar arquivos de configuração
echo "📁 ARQUIVOS DE CONFIGURAÇÃO:"
files=("docker-compose.yml" ".env" "searxng/settings.yml")
for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file existe"
    else
        echo "❌ $file não encontrado"
    fi
done
echo ""

# Status dos containers
echo "📦 STATUS DOS CONTAINERS:"
if docker-compose ps &>/dev/null; then
    docker-compose ps
else
    echo "❌ Não foi possível verificar containers"
fi
echo ""

# Verificar portas
echo "🌐 PORTAS:"
ports=(3000 8080 11434 6379)
for port in "${ports[@]}"; do
    if netstat -tlnp 2>/dev/null | grep -q ":$port "; then
        echo "✅ Porta $port está em uso"
    else
        echo "❌ Porta $port não está em uso"
    fi
done
echo ""

# Testar conectividade
echo "🔗 TESTES DE CONECTIVIDADE:"

# Teste Open Web UI
if curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 | grep -q "200\|302"; then
    echo "✅ Open Web UI responde (http://localhost:3000)"
else
    echo "❌ Open Web UI não responde"
fi

# Teste SearxNG
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep -q "200"; then
    echo "✅ SearxNG responde (http://localhost:8080)"
else
    echo "❌ SearxNG não responde"
fi

# Teste Ollama
if curl -s http://localhost:11434/api/tags &>/dev/null; then
    echo "✅ Ollama API responde (http://localhost:11434)"
else
    echo "❌ Ollama API não responde"
fi

# Teste Redis
if docker exec redis redis-cli ping 2>/dev/null | grep -q "PONG"; then
    echo "✅ Redis responde"
else
    echo "❌ Redis não responde"
fi
echo ""

# Modelos do Ollama
echo "🧠 MODELOS OLLAMA:"
if docker exec ollama ollama list 2>/dev/null; then
    echo ""
else
    echo "❌ Não foi possível listar modelos"
fi

# Uso de recursos
echo "📊 USO DE RECURSOS:"
if docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" 2>/dev/null; then
    echo ""
else
    echo "❌ Não foi possível verificar uso de recursos"
fi

# Logs recentes de erro
echo "📝 LOGS RECENTES (ERROS):"
echo "Últimas 10 linhas com erro:"
docker-compose logs --tail=50 2>/dev/null | grep -i error | tail -10 || echo "Nenhum erro encontrado nos logs recentes"
echo ""

# Espaço em disco detalhado
echo "💾 ESPAÇO EM DISCO:"
echo "Dados dos containers:"
du -sh data/* 2>/dev/null || echo "Diretório data/ não encontrado"
echo ""
echo "Imagens Docker:"
docker system df 2>/dev/null || echo "Não foi possível verificar uso do Docker"
echo ""

# Configurações de rede
echo "🌐 CONFIGURAÇÃO DE REDE:"
echo "Redes Docker:"
docker network ls | grep ai-network || echo "Rede ai-network não encontrada"
echo ""

# Teste de busca no SearxNG
echo "🔍 TESTE DE BUSCA:"
if curl -s "http://localhost:8080/search?q=test&format=json" | grep -q "results"; then
    echo "✅ SearxNG consegue fazer buscas"
else
    echo "❌ SearxNG não consegue fazer buscas"
fi
echo ""

# Recomendações
echo "💡 RECOMENDAÇÕES:"
echo ""

# Verificar RAM
total_ram=$(free -m | grep Mem | awk '{print $2}')
if [ "$total_ram" -lt 4096 ]; then
    echo "⚠️  RAM baixa ($total_ram MB). Recomendado: 8GB+ para melhor performance"
fi

# Verificar espaço
available_space=$(df . | tail -1 | awk '{print $4}')
if [ "$available_space" -lt 10485760 ]; then  # 10GB em KB
    echo "⚠️  Pouco espaço em disco. Recomendado: 20GB+ livres"
fi

# Verificar se containers estão rodando
running_containers=$(docker-compose ps | grep "Up" | wc -l)
if [ "$running_containers" -lt 4 ]; then
    echo "⚠️  Nem todos os containers estão rodando. Execute: docker-compose up -d"
fi

echo ""
echo "🔧 COMANDOS ÚTEIS PARA SOLUÇÃO DE PROBLEMAS:"
echo ""
echo "Reiniciar todos os serviços:"
echo "  docker-compose restart"
echo ""
echo "Ver logs em tempo real:"
echo "  docker-compose logs -f"
echo ""
echo "Reconstruir containers:"
echo "  docker-compose down && docker-compose up -d --build"
echo ""
echo "Limpar cache do Docker:"
echo "  docker system prune -f"
echo ""
echo "=========================================="
echo "Diagnóstico concluído!"