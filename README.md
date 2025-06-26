# Projeto WebUI + n8n + Ollama

Este repositório organiza sua stack de automações e AI em um só lugar: **Open Web UI**, **n8n** e **Ollama**. Sem mimimi, só o essencial para você orquestrar suas rotinas.

## 🚀 Visão Geral

* **Open Web UI**: Interface web para interagir com modelos de IA.
* **n8n**: Automação de workflows via NodeJS.
* **Ollama**: Servidor local para inferência de LLMs.

## 📋 Pré-requisitos

* Docker & Docker Compose
* Acesso root/sudo no servidor
* Domínio apontando para sua VPS (opcional, mas recomendado)

## 🛠️ Configuração

1. Clone este repositório:

   ```bash
   git clone https://github.com/rafaelamiranda/AutomaLLama.git && cd AutomaLLama
   ```
2. Copie o arquivo de exemplo de ambiente e preencha os valores:

   ```bash
   cp .env.example .env
   # Preencha .env com suas credenciais
   ```
3. Ajuste `nginx.local.conf` se necessário (hostnames, paths).

## 📁 Estrutura de Arquivos

```
├── .env.example       # Exemplo de variáveis de ambiente
├── docker-compose.yml # Orquestra serviços: Open Web UI, n8n, Ollama
├── nginx.local.conf   # Configuração do Nginx pra SSL/Proxy
├── start.sh           # Script: limpa, rebuild e up
└── shared/            # Backups e dados persistentes
    └── n8n/backup     # Backups automáticos do n8n
```

## 📝 Variáveis de Ambiente

Preencha **.env** (veja `.env.example`):

```dotenv
# Postgres
e.g. POSTGRES_USER=postgres
# n8n
N8N_BASIC_AUTH_USER=usuario
# Ollama
OLLAMA_API_BASE_URL=http://ollama:11434
```

## ⚡ Uso Rápido

* **Build & up**:

  ```bash
  chmod +x start.sh && ./start.sh
  ```
* **Acesso**:

  * Open Web UI: `http://localhost:3000`
  * n8n: `http://localhost:5678`
  * Ollama API: `http://localhost:11434`

## 🔄 Rotinas de Backup

* Os backups do n8n ficam em `shared/n8n/backup`.
* Ajuste volume em `docker-compose.yml` para persistência.

## 🤝 Contribuição

Bug reports e PRs são bem-vindos. Mantenha o foco no objetivo: automações sem complicação.

## 📜 Licença

MIT. Pode usar, modificar e destroçar do jeito que quiser.
