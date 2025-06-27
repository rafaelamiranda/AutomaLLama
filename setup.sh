#!/bin/bash

# Script de configuração para Open Web UI + Ollama + SearxNG
# Para Linux Mint / Ubuntu

set -e

echo "🚀 Configurando ambiente Open Web UI + Ollama"
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
mkdir -p data/open-webui

# Gerar chaves secretas aleatórias se não existirem
if [ ! -f .env ]; then
    echo "🔑 Gerando chaves secretas..."
    
    WEBUI_SECRET=$(openssl rand -base64 32)
    
    cat > .env << EOF
# Chaves secretas geradas automaticamente
WEBUI_SECRET_KEY=${WEBUI_SECRET}


# Configurações do ambiente
COMPOSE_PROJECT_NAME=ai-local-stack
EOF
    
    echo "✅ Arquivo .env criado com chaves secretas"
fi

# Verificar se os arquivos de configuração existem
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Arquivo docker-compose.yml não encontrado!"
    echo "Certifique-se de que todos os arquivos estão no diretório correto."
    exit 1
fi

# Baixar imagens Docker
echo "⬇️  Baixando imagens Docker..."
docker-compose pull

echo ""
echo "✅ Configuração concluída!"
echo ""
echo "Para iniciar o sistema:"
echo "  docker-compose up -d"
echo ""
echo "Para baixar modelos do Ollama:"
echo "  docker exec -it ollama ollama pull llama3.2:3b"
echo "  docker exec -it ollama ollama pull llama3.2:1b"
echo ""
echo "URLs de acesso:"
echo "  • Open Web UI: http://localhost:3000"
echo "  • Ollama API: http://localhost:11434"
echo ""
echo "Para parar os serviços:"
echo "  docker-compose down"
echo ""
echo "Para ver logs:"
echo "  docker-compose logs -f"