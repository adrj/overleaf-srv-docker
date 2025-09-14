#!/bin/bash

# Script de inicialização do Overleaf Docker
# Este script automatiza o processo de configuração inicial

set -e

echo "🚀 Inicializando Overleaf Docker Setup..."

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para imprimir mensagens coloridas
print_message() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Verificar se Docker está rodando
print_message "Verificando se Docker está rodando..."
if ! docker info >/dev/null 2>&1; then
    print_error "Docker não está rodando! Por favor, inicie o Docker Desktop."
    exit 1
fi
print_success "Docker está rodando!"

# Verificar se docker-compose está disponível
print_message "Verificando docker-compose..."
if ! command -v docker-compose >/dev/null 2>&1; then
    print_error "docker-compose não encontrado! Por favor, instale o Docker Compose."
    exit 1
fi
print_success "docker-compose encontrado!"

# Verificar se já existe arquivo .env
if [ ! -f .env ]; then
    print_warning "Arquivo .env não encontrado. Criando a partir do .env.example..."
    if [ -f .env.example ]; then
        cp .env.example .env
        print_success "Arquivo .env criado! IMPORTANTE: Edite o arquivo .env antes de continuar."
        print_warning "Pressione Enter depois de editar o arquivo .env..."
        read -r
    else
        print_warning "Arquivo .env.example não encontrado. Continuando com configurações do docker-compose.yml..."
    fi
fi

# Verificar se as portas estão livres
print_message "Verificando se as portas necessárias estão livres..."
PORTS=(80 27017 6379)
for port in "${PORTS[@]}"; do
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        print_error "Porta $port está em uso! Por favor, libere a porta antes de continuar."
        exit 1
    fi
done
print_success "Todas as portas necessárias estão livres!"

# Parar containers existentes (se houver)
print_message "Parando containers existentes (se houver)..."
docker-compose down >/dev/null 2>&1 || true

# Subir os serviços
print_message "Iniciando os serviços Docker..."
docker-compose up -d

# Aguardar os serviços ficarem prontos
print_message "Aguardando os serviços ficarem prontos..."
sleep 10

# Verificar se os containers estão rodando
print_message "Verificando status dos containers..."
if ! docker-compose ps | grep -q "Up"; then
    print_error "Nem todos os containers estão rodando. Verificando logs..."
    docker-compose logs
    exit 1
fi

# Aguardar MongoDB ficar healthy
print_message "Aguardando MongoDB ficar healthy..."
for i in {1..30}; do
    if docker-compose ps mongo | grep -q "healthy"; then
        break
    fi
    print_message "Aguardando MongoDB... ($i/30)"
    sleep 5
done

# Verificar se MongoDB está healthy
if ! docker-compose ps mongo | grep -q "healthy"; then
    print_warning "MongoDB não ficou healthy. Tentando inicializar replica set..."
fi

# Inicializar replica set do MongoDB
print_message "Inicializando replica set do MongoDB..."
docker exec mongo mongosh --eval "
try {
    rs.status();
    print('Replica set já está inicializado.');
} catch (e) {
    print('Inicializando replica set...');
    rs.initiate({_id: 'rs0', members: [{_id: 0, host: 'mongo:27017'}]});
    print('Replica set inicializado com sucesso!');
}
" || print_warning "Erro ao inicializar replica set. Pode já estar configurado."

# Aguardar um pouco mais para tudo ficar pronto
print_message "Aguardando serviços finalizarem inicialização..."
sleep 15

# Verificar se Overleaf está respondendo
print_message "Verificando se Overleaf está respondendo..."
for i in {1..12}; do
    if curl -s -f http://localhost >/dev/null 2>&1; then
        print_success "Overleaf está respondendo!"
        break
    fi
    print_message "Aguardando Overleaf responder... ($i/12)"
    sleep 10
done

# Status final
print_message "Verificando status final dos serviços..."
docker-compose ps

echo ""
print_success "🎉 Setup concluído com sucesso!"
echo ""
print_message "📋 Próximos passos:"
echo "   1. Acesse: http://localhost"
echo "   2. Faça login com as credenciais configuradas no .env ou docker-compose.yml"
echo "   3. Altere a senha padrão imediatamente"
echo ""
print_message "🔧 Comandos úteis:"
echo "   - Ver logs: docker-compose logs -f"
echo "   - Parar serviços: docker-compose down"
echo "   - Reiniciar: docker-compose restart"
echo ""
print_warning "⚠️  IMPORTANTE: Altere as credenciais padrão antes de usar em produção!"
