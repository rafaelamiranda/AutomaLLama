#!/bin/bash

# Script de gerenciamento completo do AutomaLLama
# Open Web UI + Ollama + SearxNG

set -e

show_help() {
    echo "🚀 AutomaLLama - Gerenciador"
    echo "=============================="
    echo ""
    echo "Uso: $0 [comando]"
    echo ""
    echo "Comandos disponíveis:"
    echo ""
    echo "  📋 STATUS E INFORMAÇÕES:"
    echo "    status       - Mostrar status dos serviços"
    echo "    ps           - Listar containers ativos"
    echo "    logs         - Ver logs em tempo real"
    echo "    info         - Informações do sistema"
    echo "    urls         - Mostrar URLs de acesso"
    echo ""
    echo "  ⚙️  CONTROLE DE SERVIÇOS:"
    echo "    start        - Iniciar todos os serviços"
    echo "    stop         - Parar todos os serviços"
    echo "    restart      - Reiniciar todos os serviços"
    echo "    update       - Atualizar imagens Docker"
    echo ""
    echo "  🧠 GERENCIAR MODELOS:"
    echo "    models       - Listar modelos instalados"
    echo "    install      - Instalar modelos recomendados"
    echo "    pull <model> - Baixar modelo específico"
    echo ""
    echo "  🔍 SEARXNG:"
    echo "    search-test  - Testar funcionamento do SearxNG"
    echo "    search-stats - Ver estatísticas de busca"
    echo "    search-config - Ver configuração do SearxNG"
    echo ""
    echo "  💾 BACKUP E RESTORE:"
    echo "    backup       - Criar backup completo"
    echo "    restore      - Restaurar backup"
    echo "    clean        - Limpar dados antigos"
    echo ""
    echo "  🔧 MANUTENÇÃO:"
    echo "    health       - Diagnóstico completo"
    echo "    fix-perms    - Corrigir permissões"
    echo "    reset        - Reset completo (cuidado!)"
    echo ""
    echo "  📊 MONITORAMENTO:"
    echo "    monitor      - Monitor de recursos"
    echo "    disk         - Uso de disco"
    echo "    mem          - Uso de memória"
    echo ""
}

check_requirements() {
    if ! command -v docker &> /dev/null; then
        echo "❌ Docker não encontrado. Execute: ./setup.sh"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        echo "❌ Docker Compose não encontrado. Execute: ./setup.sh"
        exit 1
    fi
    
    if [ ! -f "docker-compose.yml" ]; then
        echo "❌ docker-compose.yml não encontrado"
        exit 1
    fi
}

show_status() {
    echo "📊 Status dos Serviços AutomaLLama"
    echo "===================================="
    docker-compose ps
    echo ""
    
    echo "🌐 Conectividade:"
    services=(
        "Open Web UI:http://localhost:3000"
        "SearxNG:http://localhost:8080"
        "Ollama API:http://localhost:11434/api/tags"
    )
    
    for service in "${services[@]}"; do
        name=$(echo $service | cut -d: -f1)
        url=$(echo $service | cut -d: -f2-)
        
        if curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "200\|302"; then
            echo "✅ $name"
        else
            echo "❌ $name"
        fi
    done
}

show_urls() {
    echo "🌐 URLs de Acesso"
    echo "=================="
    echo "• Open Web UI: http://localhost:3000"
    echo "• SearxNG: http://localhost:8080"
    echo "• Ollama API: http://localhost:11434"
    echo ""
    echo "📱 Para acesso remoto, substitua 'localhost' pelo IP do servidor"
}

manage_services() {
    case $1 in
        "start")
            echo "▶️  Iniciando serviços..."
            docker-compose up -d
            echo "✅ Serviços iniciados!"
            show_urls
            ;;
        "stop")
            echo "⏹️  Parando serviços..."
            docker-compose down
            echo "✅ Serviços parados!"
            ;;
        "restart")
            echo "🔄 Reiniciando serviços..."
            docker-compose restart
            echo "✅ Serviços reiniciados!"
            ;;
        "update")
            echo "📦 Atualizando imagens..."
            docker-compose pull
            docker-compose up -d
            echo "✅ Imagens atualizadas!"
            ;;
    esac
}

manage_models() {
    case $1 in
        "models")
            echo "🧠 Modelos Instalados:"
            echo "====================="
            docker exec ollama ollama list 2>/dev/null || echo "❌ Ollama não está rodando"
            ;;
        "install")
            echo "📥 Instalando modelos recomendados..."
            models=(
                "llama3.2:1b:Modelo pequeno e rápido (1.3GB)"
                "llama3.2:3b:Modelo médio e balanceado (2GB)"
                "sabia-2:7b:Modelo otimizado para português (4GB)"
            )
            
            for model_info in "${models[@]}"; do
                model=$(echo $model_info | cut -d: -f1,2)
                desc=$(echo $model_info | cut -d: -f3)
                
                echo ""
                echo "📥 Baixando $model - $desc"
                docker exec ollama ollama pull "$model"
            done
            echo "✅ Modelos instalados!"
            ;;
        "pull")
            if [ -z "$2" ]; then
                echo "❌ Especifique o modelo: $0 pull <nome-do-modelo>"
                echo "Exemplo: $0 pull llama3.2:3b"
                exit 1
            fi
            echo "📥 Baixando modelo: $2"
            docker exec ollama ollama pull "$2"
            ;;
    esac
}

searxng_commands() {
    case $1 in
        "search-test")
            echo "🔍 Testando SearxNG..."
            if curl -s "http://localhost:8080/search?q=test&format=json" | grep -q "results"; then
                echo "✅ SearxNG funcionando corretamente"
                echo "📊 Teste de busca bem-sucedido"
            else
                echo "❌ SearxNG não está funcionando"
                echo "💡 Tente: $0 restart"
            fi
            ;;
        "search-stats")
            echo "📊 Estatísticas do SearxNG:"
            curl -s "http://localhost:8080/stats" || echo "❌ Não foi possível obter estatísticas"
            ;;
        "search-config")
            echo "⚙️  Configuração do SearxNG:"
            curl -s "http://localhost:8080/config" | head -20 || echo "❌ Não foi possível obter configuração"
            ;;
    esac
}

backup_restore() {
    case $1 in
        "backup")
            if [ -f "./backup.sh" ]; then
                ./backup.sh
            else
                echo "❌ Script backup.sh não encontrado"
            fi
            ;;
        "restore")
            if [ -f "./restore.sh" ]; then
                ./restore.sh $2
            else
                echo "❌ Script restore.sh não encontrado"
            fi
            ;;
        "clean")
            echo "🧹 Limpando dados antigos..."
            docker system prune -f
            docker volume prune -f
            echo "✅ Limpeza concluída!"
            ;;
    esac
}

maintenance() {
    case $1 in
        "health")
            if [ -f "./diagnostics.sh" ]; then
                ./diagnostics.sh
            else
                echo "❌ Script diagnostics.sh não encontrado"
            fi
            ;;
        "fix-perms")
            echo "🔧 Corrigindo permissões..."
            sudo chown -R $USER:$USER data/ 2>/dev/null || true
            sudo chown -R 977:977 searxng/ 2>/dev/null || true
            chmod +x *.sh 2>/dev/null || true
            echo "✅ Permissões corrigidas!"
            ;;
        "reset")
            echo "⚠️  ATENÇÃO: Esta ação irá remover TODOS os dados!"
            read -p "Tem certeza? Digite 'RESET' para confirmar: " confirm
            if [ "$confirm" = "RESET" ]; then
                echo "🔄 Fazendo reset completo..."
                docker-compose down -v
                sudo rm -rf data/
                mkdir -p data/{ollama,webui,redis}
                echo "✅ Reset concluído! Execute: $0 start"
            else
                echo "❌ Reset cancelado"
            fi
            ;;
    esac
}

monitoring() {
    case $1 in
        "monitor")
            echo "📊 Monitor de Recursos (Ctrl+C para sair)"
            watch -n 2 'docker stats --no-stream'
            ;;
        "disk")
            echo "💾 Uso de Disco:"
            echo "================"
            df -h .
            echo ""
            echo "Dados dos containers:"
            du -sh data/* 2>/dev/null || echo "Dados não encontrados"
            echo ""
            echo "Imagens Docker:"
            docker system df
            ;;
        "mem")
            echo "🧠 Uso de Memória:"
            echo "=================="
            free -h
            echo ""
            echo "Por container:"
            docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}\t{{.MemPerc}}"
            ;;
    esac
}

# Função principal
main() {
    if [ $# -eq 0 ]; then
        show_help
        exit 0
    fi
    
    check_requirements
    
    case $1 in
        "help"|"-h"|"--help")
            show_help
            ;;
        "status")
            show_status
            ;;
        "ps")
            docker-compose ps
            ;;
        "logs")
            docker-compose logs -f
            ;;
        "info")
            echo "ℹ️  Informações do Sistema:"
            echo "=========================="
            echo "OS: $(lsb_release -d 2>/dev/null | cut -f2 || uname -s)"
            echo "Docker: $(docker --version)"
            echo "Compose: $(docker-compose --version)"
            echo "RAM: $(free -h | grep Mem | awk '{print $2}')"
            echo "Espaço: $(df -h . | tail -1 | awk '{print $4}')"
            ;;
        "urls")
            show_urls
            ;;
        "start"|"stop"|"restart"|"update")
            manage_services $1
            ;;
        "models"|"install")
            manage_models $1
            ;;
        "pull")
            manage_models $1 $2
            ;;
        "search-test"|"search-stats"|"search-config")
            searxng_commands $1
            ;;
        "backup"|"restore"|"clean")
            backup_restore $1 $2
            ;;
        "health"|"fix-perms"|"reset")
            maintenance $1
            ;;
        "monitor"|"disk"|"mem")
            monitoring $1
            ;;
        *)
            echo "❌ Comando não reconhecido: $1"
            echo "Execute '$0 help' para ver comandos disponíveis"
            exit 1
            ;;
    esac
}

main "$@"