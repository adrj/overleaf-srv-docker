# Changelog

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e este projeto adere ao [Versionamento Semântico](https://semver.org/lang/pt-BR/).

## [1.1.0] - 2024-09-14

### Adicionado
- Arquivo `.env.example` com todas as configurações disponíveis documentadas
- Script `setup.sh` para automação da configuração em sistemas Unix/Linux/Mac
- Script `setup.ps1` para automação da configuração no Windows PowerShell
- Documentação completa de variáveis de ambiente
- Verificação automática de dependências nos scripts
- Verificação automática de portas em uso
- Inicialização automática do replica set do MongoDB

### Melhorado
- README.md com instruções mais detalhadas de segurança
- `.gitignore` mais abrangente incluindo certificados e chaves
- Documentação de troubleshooting expandida

## [1.0.0] - 2024-09-14

### Adicionado
- Configuração inicial do Docker Compose com Overleaf Community Edition
- Serviços MongoDB 6.0 e Redis 6.2
- Persistência de dados para todos os serviços
- Configurações de ambiente para desenvolvimento e produção
- Documentação completa no README.md
- Configurações de segurança básicas
- Suporte para configuração de SMTP/e-mail
- Arquivo `.gitignore` configurado para excluir dados sensíveis

### Configurações
- Overleaf rodando na porta 80
- MongoDB com replica set configurado
- Redis para cache
- Volumes persistentes para dados
- Variáveis de ambiente configuráveis
- Usuário admin padrão configurável

## [Não Lançado]

### Em Desenvolvimento
- Suporte para HTTPS/SSL
- Configuração de backup automático
- Scripts de migração de dados
- Documentação de deploy em produção
- Integração com proxy reverso (nginx)

---

## Tipos de Mudanças
- `Adicionado` para novas funcionalidades
- `Melhorado` para melhorias em funcionalidades existentes
- `Depreciado` para funcionalidades que serão removidas
- `Removido` para funcionalidades removidas
- `Corrigido` para correções de bugs
- `Segurança` para correções de vulnerabilidades
