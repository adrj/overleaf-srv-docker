# Overleaf Community Edition - Docker

Este projeto configura uma instância local do Overleaf Community Edition usando Docker Compose.

## 📋 Pré-requisitos

- Docker Desktop instalado
- Docker Compose
- Pelo menos 4GB de RAM disponível
- Porta 80 livre no sistema

## 🚀 Como subir o serviço

### 1. Clone o repositório
```bash
git clone https://github.com/adrj/overleaf-srv-docker.git
cd overleaf-srv-docker
```

### 2. Configure as variáveis sensíveis (IMPORTANTE)
Antes de iniciar o serviço, **altere as configurações padrão** no arquivo `docker-compose.yml`:

#### Credenciais do Administrador
Localize e altere as seguintes linhas:
```yaml
OVERLEAF_ADMIN_EMAIL: admin@overleaf.local    # Altere para seu e-mail
OVERLEAF_ADMIN_PASSWORD: password123          # Altere para uma senha segura
```

#### URL do Site
Se não for usar localhost, altere:
```yaml
OVERLEAF_SITE_URL: "http://localhost"         # Altere para sua URL
```

### 3. Configuração de E-mail (Opcional)
Para habilitar envio de e-mails, descomente e configure as seguintes variáveis:

```yaml
# Exemplo para Gmail
OVERLEAF_EMAIL_FROM_ADDRESS: "noreply@seudominio.com"
OVERLEAF_EMAIL_SMTP_HOST: smtp.gmail.com
OVERLEAF_EMAIL_SMTP_PORT: 587
OVERLEAF_EMAIL_SMTP_SECURE: "false"
OVERLEAF_EMAIL_SMTP_USER: seu-email@gmail.com
OVERLEAF_EMAIL_SMTP_PASS: sua-senha-de-app    # Use senha de app, não a senha normal
OVERLEAF_EMAIL_SMTP_TLS_REJECT_UNAUTH: "true"
OVERLEAF_EMAIL_SMTP_IGNORE_TLS: "false"
```

#### Como gerar senha de app do Gmail:
1. Acesse sua conta Google
2. Vá em "Segurança" > "Verificação em duas etapas"
3. Role até "Senhas de app"
4. Gere uma nova senha de app para "E-mail"
5. Use essa senha no campo `OVERLEAF_EMAIL_SMTP_PASS`

### 4. Inicie os serviços
```bash
docker-compose up -d
```

### 5. Inicialize o MongoDB Replica Set
Após os containers subirem, execute:
```bash
docker exec mongo mongosh --eval "rs.initiate({_id: 'rs0', members: [{_id: 0, host: 'mongo:27017'}]})"
```

### 6. Acesse o Overleaf
Abra seu navegador e acesse: http://localhost

## 🔧 Comandos úteis

### Verificar status dos containers
```bash
docker-compose ps
```

### Ver logs
```bash
# Todos os serviços
docker-compose logs -f

# Apenas o Overleaf
docker-compose logs -f sharelatex

# Apenas o MongoDB
docker-compose logs -f mongo
```

### Parar os serviços
```bash
docker-compose down
```

### Parar e remover volumes (CUIDADO: apaga todos os dados)
```bash
docker-compose down -v
```

### Reiniciar apenas um serviço
```bash
docker-compose restart sharelatex
```

## 📁 Estrutura de Dados

Os dados são persistidos nas seguintes pastas:

- `./sharelatex_data/` - Dados do Overleaf (projetos, usuários, etc.)
- `./mongo_data/` - Banco de dados MongoDB
- `./redis_data/` - Cache Redis
- `./tmp/` - Arquivos temporários

## 🔒 Configurações de Segurança

### Senhas e Credenciais
- **NUNCA** use as credenciais padrão em produção
- Use senhas fortes com pelo menos 12 caracteres
- Para produção, considere usar variáveis de ambiente ou secrets

### Portas
- Por padrão, o serviço roda na porta 80
- Para produção, considere usar HTTPS na porta 443
- Configure um proxy reverso (nginx) se necessário

### Backup
Faça backup regular das pastas de dados:
```bash
# Backup completo
tar -czf backup-overleaf-$(date +%Y%m%d).tar.gz sharelatex_data mongo_data redis_data

# Apenas dados do Overleaf
tar -czf backup-sharelatex-$(date +%Y%m%d).tar.gz sharelatex_data
```

## 🐛 Solução de Problemas

### Container não inicia
```bash
# Verificar logs
docker-compose logs [nome-do-servico]

# Verificar recursos do sistema
docker system df
```

### Erro de permissão
No Linux/Mac:
```bash
sudo chown -R $USER:$USER sharelatex_data mongo_data redis_data tmp
```

### MongoDB não inicializa
```bash
# Remover dados corrompidos e reiniciar
docker-compose down
sudo rm -rf mongo_data/*
docker-compose up -d mongo
# Aguardar e executar rs.initiate novamente
```

### Reset completo
```bash
docker-compose down -v
sudo rm -rf sharelatex_data mongo_data redis_data tmp
docker-compose up -d
```

## 📖 Recursos Adicionais

- [Documentação oficial Overleaf](https://github.com/overleaf/overleaf)
- [Docker Compose reference](https://docs.docker.com/compose/)
- [MongoDB Replica Sets](https://docs.mongodb.com/manual/replication/)

## 👤 Autor

**Adalto dos Reis Junior**
- GitHub: [@adrj](https://github.com/adrj)
- Email: adalto.junior@gmail.com

## 📄 Licença

Este projeto segue a mesma licença do Overleaf Community Edition.
