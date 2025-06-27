# 🚀 Open Web UI + Ollama - Stack de IA Local

Este projeto fornece uma stack completa de IA local rodando no Docker, incluindo:

- **Open Web UI**: Interface web moderna para interagir com modelos de IA
- **Ollama**: Servidor local para executar modelos de linguagem (LLMs)

## 📋 Pré-requisitos

- Linux Mint / Ubuntu (ou distribuição compatível)
- 8GB+ de RAM recomendado
- 20GB+ de espaço livre em disco
- Conexão com internet para download inicial

## 🛠️ Instalação Rápida

1. **Clone ou baixe todos os arquivos do projeto:**
   ```bash
   mkdir AutomaLLama
   cd AutomaLLama
   # Coloque todos os arquivos aqui
   ```

2. **Execute o script de configuração:**
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

3. **Inicie os serviços:**
   ```bash
   docker-compose up -d
   ```

4. **Baixe alguns modelos do Ollama:**
   ```bash
   # Modelo pequeno e rápido (1.3GB)
   docker exec -it ollama ollama pull llama3.2:1b
   
   # Modelo médio e balanceado (2GB)
   docker exec -it ollama ollama pull llama3.2:3b
   
   # Modelo português otimizado (4GB)
   docker exec -it ollama ollama pull sabia-2:7b
   ```

## 🌐 URLs de Acesso

- **Open Web UI**: http://localhost:3000 
- **API Ollama**: http://localhost:11434

## 🎯 Primeiro Uso

1. Acesse http://localhost:3000
2. Crie sua conta (primeira vez)
3. O Ollama será detectado automaticamente
4. Comece a conversar com a IA!

## 📁 Estrutura do Projeto

```
AutomaLLama/
├── docker-compose.yml      # Configuração principal dos serviços
├── setup.sh               # Script de instalação automática
├── README.md              # Esta documentação
├── .env                   # Variáveis de ambiente (gerado automaticamente)
```

## 🔧 Comandos Úteis

### Gerenciar Serviços
```bash
# Iniciar todos os serviços
docker-compose up -d

# Parar todos os serviços
docker-compose down

# Reiniciar um serviço específico
docker-compose restart open-webui

# Ver status dos serviços
docker-compose ps
```

### Logs e Troubleshooting
```bash
# Ver logs de todos os serviços
docker-compose logs -f

# Ver logs de um serviço específico
docker-compose logs -f ollama

# Ver logs das últimas 50 linhas
docker-compose logs --tail=50
```

### Gerenciar Modelos Ollama
```bash
# Listar modelos instalados
docker exec -it ollama ollama list

# Baixar um modelo
docker exec -it ollama ollama pull nome-do-modelo

# Remover um modelo
docker exec -it ollama ollama rm nome-do-modelo

# Testar um modelo via CLI
docker exec -it ollama ollama run llama3.2:3b
```

## 🧠 Modelos Recomendados

### Para Início (baixo consumo de RAM):
- `llama3.2:1b` - 1.3GB, muito rápido
- `llama3.2:3b` - 2GB, balanceado

### Para Uso Geral (RAM moderada):
- `llama3.1:8b` - 4.7GB, muito bom
- `mistral:7b` - 4.1GB, eficiente

### Para Hardware Potente:
- `llama3.1:70b` - 40GB, excelente qualidade
- `codellama:13b` - 7.4GB, focado em código

### Modelos em Português:
- `sabia-2:7b` - Otimizado para português
- `llama3.2:3b` - Funciona bem em português

## ⚙️ Configurações Avançadas

### Personalizar Open Web UI

Edite as variáveis de ambiente no `docker-compose.yml`:

```yaml
environment:
  - WEBUI_NAME=Minha IA Local
  - DEFAULT_LOCALE=pt-BR
  - ENABLE_SIGNUP=false  # Desabilitar cadastros
```

### Usar GPU (NVIDIA)

Para usar GPU com Ollama, modifique o docker-compose.yml:

```yaml
ollama:
  image: ollama/ollama:latest
  deploy:
    resources:
      reservations:
        devices:
          - driver: nvidia
            count: 1
            capabilities: [gpu]
```

## 🔒 Segurança

- Altere as chaves secretas em `.env` antes do uso em produção
- Configure firewall para limitar acesso às portas
- Use proxy reverso (nginx) para exposição externa
- Configure autenticação forte no Open Web UI

## 🐛 Solução de Problemas

### Ollama não carrega modelos
```bash
# Verificar logs
docker-compose logs ollama

# Verificar espaço em disco
df -h

# Reiniciar serviço
docker-compose restart ollama
```

### Problemas de memória
```bash
# Verificar uso de RAM
docker stats

# Usar modelos menores
docker exec -it ollama ollama pull llama3.2:1b
```

## 📊 Monitoramento

### Verificar uso de recursos:
```bash
# Ver uso de CPU/RAM por container
docker stats

# Ver uso de disco
docker system df

# Limpar cache
docker system prune
```

## 🔄 Backup e Restauração

### Fazer backup dos dados:
```bash
# Backup dos volumes
docker run --rm -v ai-local-stack_ollama_data:/data -v $(pwd):/backup alpine tar czf /backup/ollama-backup.tar.gz -C /data .
docker run --rm -v ai-local-stack_open_webui_data:/data -v $(pwd):/backup alpine tar czf /backup/webui-backup.tar.gz -C /data .
```

### Restaurar backup:
```bash
# Restaurar volumes
docker run --rm -v ai-local-stack_ollama_data:/data -v $(pwd):/backup alpine tar xzf /backup/ollama-backup.tar.gz -C /data
docker run --rm -v ai-local-stack_open_webui_data:/data -v $(pwd):/backup alpine tar xzf /backup/webui-backup.tar.gz -C /data
```

## 🆘 Suporte

Se encontrar problemas:

1. Verifique os logs: `docker-compose logs -f`
2. Consulte a documentação oficial:
   - [Open Web UI](https://github.com/open-webui/open-webui)
   - [Ollama](https://ollama.ai/)
3. Verifique issues no GitHub dos projetos

## 📜 Licença

Este projeto é fornecido como está, para uso educacional e pessoal. Respeite as licenças dos componentes individuais.

---

**Aproveite sua IA local! 🎉**