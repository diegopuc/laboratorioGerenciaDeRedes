$ErrorActionPreference = "Stop"

Write-Host "=== Laboratorio de Gerenciamento de Redes ===" -ForegroundColor Cyan

function Test-PortInUse {
    param([int]$Port)
    try {
        $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $Port)
        $listener.Start()
        $listener.Stop()
        return $false
    }
    catch {
        return $true
    }
}

function Get-ExistingLabPort {
    try {
        $running = docker ps --filter "name=^lab-zabbix-web$" --format "{{.Names}}" 2>$null
        if ($running -contains "lab-zabbix-web") {
            $mapping = docker port lab-zabbix-web 8080/tcp 2>$null | Select-Object -First 1
            if ($mapping -match ":(\d+)$") {
                return [int]$Matches[1]
            }
        }
    }
    catch {}
    return $null
}

$existingPort = Get-ExistingLabPort

if ($existingPort) {
    $ZabbixPort = $existingPort
}
else {
    $ZabbixPort = 8090
    while (Test-PortInUse $ZabbixPort) {
        $ZabbixPort++
    }
}

$env:ZABBIX_WEB_PORT = "$ZabbixPort"
$ZabbixUrl = "http://localhost:$ZabbixPort"
$ApiUrl = "$ZabbixUrl/api_jsonrpc.php"

Write-Host "Porta do Zabbix Web: $ZabbixPort" -ForegroundColor Yellow
Write-Host "Subindo os containers..." -ForegroundColor Yellow

docker compose up -d --build

function Invoke-ZabbixApi {
    param(
        [Parameter(Mandatory=$true)][string]$Method,
        [Parameter(Mandatory=$true)][hashtable]$Params,
        [string]$Auth = $null
    )

    $body = @{
        jsonrpc = "2.0"
        method  = $Method
        params  = $Params
        id      = 1
    }

    $headers = @{}
    if ($Auth) {
        $headers["Authorization"] = "Bearer $Auth"
    }

    $response = Invoke-RestMethod `
        -Uri $ApiUrl `
        -Method Post `
        -ContentType "application/json-rpc" `
        -Headers $headers `
        -Body ($body | ConvertTo-Json -Depth 30)

    if ($response.error) {
        throw "Erro API Zabbix [$Method]: $($response.error.data)"
    }

    return $response.result
}

Write-Host "Aguardando o Zabbix..." -ForegroundColor Yellow

$auth = $null
for ($i = 1; $i -le 90; $i++) {
    try {
        $auth = Invoke-ZabbixApi -Method "user.login" -Params @{
            username = "Admin"
            password = "zabbix"
        }
        if ($auth) { break }
    }
    catch {
        Start-Sleep -Seconds 4
    }
}

if (-not $auth) {
    throw "Zabbix nao ficou pronto. Verifique: docker compose logs zabbix-web zabbix-server"
}

Write-Host "API do Zabbix disponivel." -ForegroundColor Green

# Desabilita o host padrao para evitar o alerta 127.0.0.1:10050 neste ambiente em containers.
$defaultHost = Invoke-ZabbixApi -Method "host.get" -Params @{
    output = @("hostid","host","status")
    filter = @{ host = @("Zabbix server") }
} -Auth $auth

if ($defaultHost.Count -gt 0 -and $defaultHost[0].status -ne "1") {
    Invoke-ZabbixApi -Method "host.update" -Params @{
        hostid = $defaultHost[0].hostid
        status = 1
    } -Auth $auth | Out-Null
    Write-Host "Host padrao 'Zabbix server' desabilitado para este laboratorio." -ForegroundColor Green
}

# Grupo do laboratorio.
$groupName = "LAB - Gerencia de Redes"
$group = Invoke-ZabbixApi -Method "hostgroup.get" -Params @{
    output = @("groupid","name")
    filter = @{ name = @($groupName) }
} -Auth $auth

if ($group.Count -eq 0) {
    $created = Invoke-ZabbixApi -Method "hostgroup.create" -Params @{ name = $groupName } -Auth $auth
    $groupId = $created.groupids[0]
    Write-Host "Grupo criado: $groupName" -ForegroundColor Green
}
else {
    $groupId = $group[0].groupid
}

$hosts = @(
    @{host="arch01"; name="ARCH01 - Servidor Web";        ip="172.28.0.21"; role="Servidor Web"},
    @{host="arch02"; name="ARCH02 - Servidor de Dados";   ip="172.28.0.22"; role="Servidor de Dados"},
    @{host="arch03"; name="ARCH03 - Servidor de Arquivos";ip="172.28.0.23"; role="Servidor de Arquivos"}
)

foreach ($h in $hosts) {

    $existing = Invoke-ZabbixApi -Method "host.get" -Params @{
        output = @("hostid","host","name","status")
        selectInterfaces = @("interfaceid","ip","port")
        selectParentTemplates = @("templateid","name")
        filter = @{ host = @($h.host) }
    } -Auth $auth

    if ($existing.Count -eq 0) {
        $createdHost = Invoke-ZabbixApi -Method "host.create" -Params @{
            host = $h.host
            name = $h.name
            groups = @(@{groupid=$groupId})
            interfaces = @(
                @{
                    type  = 1
                    main  = 1
                    useip = 1
                    ip    = $h.ip
                    dns   = ""
                    port  = "10050"
                }
            )
            tags = @(
                @{tag="laboratorio"; value="gerencia-redes"},
                @{tag="funcao"; value=$h.role}
            )
        } -Auth $auth

        $hostId = $createdHost.hostids[0]
        $hostData = Invoke-ZabbixApi -Method "host.get" -Params @{
            output = @("hostid","host")
            selectInterfaces = @("interfaceid","ip","port")
            hostids = @($hostId)
        } -Auth $auth
        Write-Host "Host criado: $($h.name)" -ForegroundColor Green
    }
    else {
        $hostId = $existing[0].hostid
        $hostData = $existing

        # Remove templates antigos que podem ter sido associados por versoes anteriores do laboratorio.
        $oldTemplates = @($existing[0].parentTemplates)
        if ($oldTemplates.Count -gt 0) {
            $templatesClear = @()
            foreach ($tpl in $oldTemplates) {
                $templatesClear += @{templateid=$tpl.templateid}
            }
            Invoke-ZabbixApi -Method "host.update" -Params @{
                hostid = $hostId
                templates_clear = $templatesClear
                status = 0
            } -Auth $auth | Out-Null
            Write-Host "Templates antigos removidos de $($h.host)." -ForegroundColor Yellow
        }
        elseif ($existing[0].status -ne "0") {
            Invoke-ZabbixApi -Method "host.update" -Params @{
                hostid = $hostId
                status = 0
            } -Auth $auth | Out-Null
        }

        Write-Host "Host existente: $($h.name)"
    }

    $interfaceId = $hostData[0].interfaces[0].interfaceid

    # Itens simples e previsiveis para o laboratorio.
    $items = @(
        @{name="Disponibilidade do agente"; key_="agent.ping";                    value_type=3; units="";       delay="15s"},
        @{name="Tempo de funcionamento";    key_="system.uptime";                 value_type=3; units="uptime"; delay="30s"},
        @{name="CPU - uso por processos";   key_="system.cpu.util[,user]";        value_type=0; units="%";      delay="15s"},
        @{name="Memoria utilizada";         key_="vm.memory.size[pused]";         value_type=0; units="%";      delay="30s"},
        @{name="Disco raiz utilizado";      key_="vfs.fs.size[/,pused]";          value_type=0; units="%";      delay="30s"},
        @{name="Servico HTTP";              key_="net.tcp.service[http,,80]";     value_type=3; units="";       delay="15s"},
        @{name="Sistema operacional";       key_="system.uname";                  value_type=1; units="";       delay="1h"}
    )

    foreach ($item in $items) {
        $foundItem = Invoke-ZabbixApi -Method "item.get" -Params @{
            output = @("itemid","key_")
            hostids = @($hostId)
            filter = @{ key_ = @($item.key_) }
        } -Auth $auth

        if ($foundItem.Count -eq 0) {
            $params = @{
                name = $item.name
                key_ = $item.key_
                hostid = $hostId
                type = 0
                value_type = $item.value_type
                interfaceid = $interfaceId
                delay = $item.delay
            }
            if ($item.units) { $params.units = $item.units }

            Invoke-ZabbixApi -Method "item.create" -Params $params -Auth $auth | Out-Null
            Write-Host "  Item criado: $($item.name)" -ForegroundColor Green
        }
    }

    # Triggers do laboratorio.
    $triggerDefs = @(
        @{
            name = "$($h.name): agente sem resposta"
            expression = "nodata(/$($h.host)/agent.ping,90s)=1"
            priority = 3
        },
        @{
            name = "$($h.name): CPU elevada"
            expression = "avg(/$($h.host)/system.cpu.util[,user],2m)>80"
            priority = 2
        },
        @{
            name = "$($h.name): servico HTTP indisponivel"
            expression = "last(/$($h.host)/net.tcp.service[http,,80])=0"
            priority = 3
        }
    )

    foreach ($tr in $triggerDefs) {
        $foundTrigger = Invoke-ZabbixApi -Method "trigger.get" -Params @{
            output = @("triggerid","description")
            hostids = @($hostId)
            filter = @{ description = @($tr.name) }
        } -Auth $auth

        if ($foundTrigger.Count -eq 0) {
            Invoke-ZabbixApi -Method "trigger.create" -Params @{
                description = $tr.name
                expression = $tr.expression
                priority = $tr.priority
                manual_close = 1
            } -Auth $auth | Out-Null
            Write-Host "  Trigger criada: $($tr.name)" -ForegroundColor Green
        }
    }
}

# Grupo e usuario de leitura.
$operatorGroupName = "LAB - Operadores"
$operatorGroup = Invoke-ZabbixApi -Method "usergroup.get" -Params @{
    output = @("usrgrpid","name")
    filter = @{name=@($operatorGroupName)}
} -Auth $auth

if ($operatorGroup.Count -eq 0) {
    $createdOperatorGroup = Invoke-ZabbixApi -Method "usergroup.create" -Params @{
        name = $operatorGroupName
        hostgroup_rights = @(@{id=$groupId; permission=2})
    } -Auth $auth
    $operatorGroupId = $createdOperatorGroup.usrgrpids[0]
}
else {
    $operatorGroupId = $operatorGroup[0].usrgrpid
    Invoke-ZabbixApi -Method "usergroup.update" -Params @{
        usrgrpid = $operatorGroupId
        hostgroup_rights = @(@{id=$groupId; permission=2})
    } -Auth $auth | Out-Null
}

$role = Invoke-ZabbixApi -Method "role.get" -Params @{
    output = @("roleid","name")
    filter = @{name=@("User role")}
} -Auth $auth

if ($role.Count -gt 0) {
    $operatorUser = Invoke-ZabbixApi -Method "user.get" -Params @{
        output = @("userid","username")
        filter = @{username=@("operador")}
    } -Auth $auth

    if ($operatorUser.Count -eq 0) {
        Invoke-ZabbixApi -Method "user.create" -Params @{
            username = "operador"
            name = "Operador"
            surname = "NMS"
            passwd = "Operador@2026!Lab"
            roleid = $role[0].roleid
            usrgrps = @(@{usrgrpid=$operatorGroupId})
        } -Auth $auth | Out-Null
    }
}

Write-Host ""
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "LABORATORIO CONFIGURADO" -ForegroundColor Green
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Zabbix: $ZabbixUrl"
Write-Host "Admin: Admin / zabbix"
Write-Host "Operador: operador / Operador@2026!Lab"
Write-Host ""
Write-Host "Aguarde aproximadamente 1 minuto para os primeiros valores."
Write-Host "Depois consulte: Monitoring -> Latest data."
Write-Host ""
