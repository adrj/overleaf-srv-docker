# Script de inicialização do Overleaf Docker para Windows PowerShell
# Este script automatiza o processo de configuração inicial

param(
    [switch]$SkipPortCheck,
    [switch]$Force
)

# Configuração de cores
$ErrorActionPreference = 'Stop'

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Type = "Info"
    )
    
    switch ($Type) {
        "Info" { Write-Host "[INFO] $Message" -ForegroundColor Blue }
        "Success" { Write-Host "[SUCCESS] $Message" -ForegroundColor Green }
        "Warning" { Write-Host "[WARN] $Message" -ForegroundColor Yellow }
        "Error" { Write-Host "[ERROR] $Message" -ForegroundColor Red }
    }
}

function Test-Port {
    param([int]$Port)
    
    try {
        $connection = New-Object System.Net.Sockets.TcpClient
        $connection.Connect("localhost", $Port)
        $connection.Close()
        return $true
    }
    catch {
        return $false
    }
}

try {
    Write-ColorOutput "🚀 Inicializando Overleaf Docker Setup..." "Info"

    # Verificar se Docker está rodando
    Write-ColorOutput "Verificando se Docker está rodando..." "Info"
    try {
        $dockerInfo = docker info 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw "Docker não está respondendo"
        }
        Write-ColorOutput "Docker está rodando!" "Success"
    }
    catch {
        Write-ColorOutput "Docker não está rodando! Por favor, inicie o Docker Desktop." "Error"
        exit 1
    }

    # Verificar docker-compose
    Write-ColorOutput "Verificando docker-compose..." "Info"
    try {
        $composeVersion = docker-compose --version 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw "docker-compose não encontrado"
        }
        Write-ColorOutput "docker-compose encontrado!" "Success"
    }
    catch {
        Write-ColorOutput "docker-compose não encontrado! Por favor, instale o Docker Compose." "Error"
        exit 1
    }

    # Verificar arquivo .env
    if (!(Test-Path ".env")) {
        Write-ColorOutput "Arquivo .env não encontrado." "Warning"
        if (Test-Path ".env.example") {
            Copy-Item ".env.example" ".env"
            Write-ColorOutput "Arquivo .env criado a partir do .env.example!" "Success"
            Write-ColorOutput "IMPORTANTE: Edite o arquivo .env antes de continuar." "Warning"
            Write-ColorOutput "Pressione Enter depois de editar o arquivo .env..." "Warning"
            Read-Host
        }
        else {
            Write-ColorOutput "Arquivo .env.example não encontrado. Continuando com configurações do docker-compose.yml..." "Warning"
        }
    }

    # Verificar portas (opcional)
    if (!$SkipPortCheck) {
        Write-ColorOutput "Verificando se as portas necessárias estão livres..." "Info"
        $ports = @(80, 27017, 6379)
        foreach ($port in $ports) {
            if (Test-Port $port) {
                Write-ColorOutput "Porta $port está em uso! Use -SkipPortCheck para pular esta verificação." "Error"
                exit 1
            }
        }
        Write-ColorOutput "Todas as portas necessárias estão livres!" "Success"
    }

    # Parar containers existentes
    Write-ColorOutput "Parando containers existentes (se houver)..." "Info"
    docker-compose down 2>$null

    # Subir os serviços
    Write-ColorOutput "Iniciando os serviços Docker..." "Info"
    docker-compose up -d
    if ($LASTEXITCODE -ne 0) {
        throw "Erro ao iniciar os serviços"
    }

    # Aguardar serviços
    Write-ColorOutput "Aguardando os serviços ficarem prontos..." "Info"
    Start-Sleep 10

    # Verificar containers
    Write-ColorOutput "Verificando status dos containers..." "Info"
    $containerStatus = docker-compose ps
    if ($containerStatus -notmatch "Up") {
        Write-ColorOutput "Nem todos os containers estão rodando. Verificando logs..." "Error"
        docker-compose logs
        exit 1
    }

    # Aguardar MongoDB
    Write-ColorOutput "Aguardando MongoDB ficar healthy..." "Info"
    for ($i = 1; $i -le 30; $i++) {
        $mongoStatus = docker-compose ps mongo
        if ($mongoStatus -match "healthy") {
            break
        }
        Write-ColorOutput "Aguardando MongoDB... ($i/30)" "Info"
        Start-Sleep 5
    }

    # Inicializar replica set
    Write-ColorOutput "Inicializando replica set do MongoDB..." "Info"
    $replicaSetInit = @"
try {
    rs.status();
    print('Replica set já está inicializado.');
} catch (e) {
    print('Inicializando replica set...');
    rs.initiate({_id: 'rs0', members: [{_id: 0, host: 'mongo:27017'}]});
    print('Replica set inicializado com sucesso!');
}
"@

    docker exec mongo mongosh --eval $replicaSetInit

    # Aguardar finalização
    Write-ColorOutput "Aguardando serviços finalizarem inicialização..." "Info"
    Start-Sleep 15

    # Verificar Overleaf
    Write-ColorOutput "Verificando se Overleaf está respondendo..." "Info"
    for ($i = 1; $i -le 12; $i++) {
        try {
            $response = Invoke-WebRequest -Uri "http://localhost" -Method Head -TimeoutSec 5 -UseBasicParsing
            if ($response.StatusCode -eq 200) {
                Write-ColorOutput "Overleaf está respondendo!" "Success"
                break
            }
        }
        catch {
            Write-ColorOutput "Aguardando Overleaf responder... ($i/12)" "Info"
            Start-Sleep 10
        }
    }

    # Status final
    Write-ColorOutput "Verificando status final dos serviços..." "Info"
    docker-compose ps

    Write-Host ""
    Write-ColorOutput "🎉 Setup concluído com sucesso!" "Success"
    Write-Host ""
    Write-ColorOutput "📋 Próximos passos:" "Info"
    Write-Host "   1. Acesse: http://localhost"
    Write-Host "   2. Faça login com as credenciais configuradas no .env ou docker-compose.yml"
    Write-Host "   3. Altere a senha padrão imediatamente"
    Write-Host ""
    Write-ColorOutput "🔧 Comandos úteis:" "Info"
    Write-Host "   - Ver logs: docker-compose logs -f"
    Write-Host "   - Parar serviços: docker-compose down"
    Write-Host "   - Reiniciar: docker-compose restart"
    Write-Host ""
    Write-ColorOutput "⚠️  IMPORTANTE: Altere as credenciais padrão antes de usar em produção!" "Warning"
}
catch {
    Write-ColorOutput "Erro durante a execução: $($_.Exception.Message)" "Error"
    Write-ColorOutput "Execute 'docker-compose logs' para mais detalhes." "Info"
    exit 1
}
