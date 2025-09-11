# Overleaf Docker Setup

Este projeto configura uma instância local do Overleaf Community Edition usando Docker Compose com persistência de dados.

##  Início Rápido

### Pré-requisitos
- Docker Desktop instalado e em execução
- Docker Compose
- Pelo menos 4GB de RAM livres

### 1. Subir os serviços

```bash
docker-compose up -d
```

Aguarde alguns minutos para que todos os serviços inicializem completamente.

### 2. Verificar status dos serviços

```bash
docker-compose ps
```

Todos os serviços devem estar com status "Up" e o MongoDB deve estar "healthy".

### 3. Acessar o Overleaf

Abra seu navegador e acesse: [http://localhost:8080](http://localhost:8080)

##  Criando o Primeiro Usuário Admin

Como o registro público está desabilitado por padrão, você precisa criar o primeiro usuário admin manualmente:

### Opção 1: Usuário Admin Pré-configurado

Um usuário admin já foi criado durante a configuração:

- **Email:** `admin@overleaf.local`
- **Senha:** `admin123`

### Opção 2: Criar Novo Usuário Admin

Se precisar criar um novo usuário admin, execute:

```bash
# Conectar ao container do Overleaf
docker exec -it sharelatex node -e "
const { MongoClient } = require('/overleaf/node_modules/mongodb');
const bcrypt = require('/overleaf/node_modules/bcryptjs');

async function createUser() {
  const client = new MongoClient('mongodb://mongo:27017/sharelatex?replicaSet=rs0');
  await client.connect();
  
  const db = client.db('sharelatex');
  const users = db.collection('users');
  
  // Substitua pelos dados desejados
  const email = 'seu-email@exemplo.com';
  const password = 'sua-senha-segura';
  const firstName = 'Seu Nome';
  const lastName = 'Sobrenome';
  
  // Deletar usuário se já existir
  await users.deleteMany({ email: email });
  
  // Criar hash da senha
  const hashedPassword = bcrypt.hashSync(password, 12);
  
  // Inserir usuário
  const result = await users.insertOne({
    email: email,
    hashedPassword: hashedPassword,
    isAdmin: true,
    emails: [{
      email: email,
      createdAt: new Date(),
      confirmedAt: new Date()
    }],
    emailConfirmedAt: new Date(),
    first_name: firstName,
    last_name: lastName,
    createdAt: new Date(),
    updatedAt: new Date()
  });
  
  console.log('Usuário criado com sucesso!');
  console.log('Email:', email);
  console.log('ID:', result.insertedId);
  
  await client.close();
}

createUser().catch(console.error);
"
```

##  Estrutura do Projeto

```
overleaf-docker/
 docker-compose.yml          # Configuração dos serviços
 sharelatex_data/            # Dados persistentes do Overleaf
 mongo_data/                 # Dados persistentes do MongoDB
 redis_data/                 # Dados persistentes do Redis
 README.md                   # Este arquivo
```

##  Configuração

### Serviços incluídos:

- **Overleaf (ShareLaTeX):** Editor LaTeX online na porta 8080
- **MongoDB 6.0:** Banco de dados com replica set habilitado
- **Redis 6.2:** Cache para melhor performance

### Variáveis de ambiente principais:

- `OVERLEAF_MONGO_URL`: URL de conexão com MongoDB
- `OVERLEAF_REDIS_HOST`: Host do Redis
- `OVERLEAF_ALLOW_PUBLIC_ACCESS`: Permite acesso público (desabilitado)
- `OVERLEAF_SITE_URL`: URL base do site

##  Comandos Úteis

### Parar todos os serviços
```bash
docker-compose down
```

### Ver logs dos serviços
```bash
# Todos os serviços
docker-compose logs -f

# Serviço específico
docker-compose logs -f sharelatex
docker-compose logs -f mongo
docker-compose logs -f redis
```

### Reiniciar um serviço específico
```bash
docker-compose restart sharelatex
```

### Backup dos dados
```bash
# Parar os serviços
docker-compose down

# Fazer backup das pastas de dados
cp -r sharelatex_data sharelatex_data_backup
cp -r mongo_data mongo_data_backup
cp -r redis_data redis_data_backup
```

### Limpar tudo e recomeçar
```bash
docker-compose down -v
rm -rf sharelatex_data mongo_data redis_data
docker-compose up -d
```

##  Troubleshooting

### Problema: Serviços não inicializam
- Verifique se o Docker está rodando
- Verifique se as portas 8080, 27017 e 6379 não estão em uso
- Execute: `docker-compose down && docker-compose up -d`

### Problema: Não consegue fazer login
- Verifique se o usuário foi criado corretamente
- Verifique os logs: `docker-compose logs -f sharelatex`
- Recrie o usuário usando o script fornecido

### Problema: MongoDB não fica healthy
- Aguarde mais tempo (pode levar 2-3 minutos)
- Verifique os logs: `docker-compose logs -f mongo`
- Reinicie o serviço: `docker-compose restart mongo`

##  Notas Importantes

1. **Dados persistentes:** Todos os dados são salvos nas pastas locais e persistem entre reinicializações
2. **Primeira inicialização:** Pode levar alguns minutos para todos os serviços ficarem prontos
3. **Registro público:** Desabilitado por segurança - novos usuários devem ser criados manualmente
4. **Backup regular:** Recomenda-se fazer backup das pastas de dados regularmente

##  Segurança

- Altere a senha padrão do usuário admin imediatamente
- Mantenha os serviços atrás de um firewall/proxy em produção
- Configure certificados SSL se expor na internet
- Faça backups regulares dos dados

##  Recursos Adicionais

- [Documentação oficial do Overleaf](https://github.com/overleaf/overleaf)
- [Overleaf Community Edition](https://github.com/overleaf/overleaf/wiki/Quick-Start-Guide)
- [Docker Compose Reference](https://docs.docker.com/compose/)

---

**Versão:** 1.0
**Data:** Setembro 2025
**Autor:** Configuração automatizada via GitHub Copilot
