# Ambiente de Experimentação em Gerenciamento de Redes

Ambiente local com Zabbix, PostgreSQL e três hosts Arch Linux em containers.

O projeto foi preparado para trabalhar com NMS, FCAPS, Zabbix Agent, SNMP, disponibilidade, carga de CPU, latência e perda de pacotes.

## Arquitetura

```text
Docker Desktop
|
+-- PostgreSQL
+-- Zabbix Server
+-- Zabbix Web
|
+-- arch01 172.28.0.21  Servidor Web
+-- arch02 172.28.0.22  Servidor de Dados
+-- arch03 172.28.0.23  Servidor de Arquivos
```

## Pré-requisitos

```powershell
docker version
docker compose version
```

## Inicialização

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\setup.ps1
```

O script:

1. localiza uma porta disponível para o Zabbix Web, começando em 8090;
2. sobe os containers;
3. aguarda a API do Zabbix;
4. desabilita o host padrão `Zabbix server`, que não representa um host monitorado neste laboratório;
5. cria ou atualiza ARCH01, ARCH02 e ARCH03;
6. remove templates antigos vinculados pelos scripts anteriores;
7. cria somente os itens necessários ao laboratório;
8. cria triggers de indisponibilidade do agente, CPU elevada e serviço HTTP indisponível;
9. cria a conta de leitura `operador`.

Ao final, a URL efetiva do Zabbix é exibida no terminal.

## Credenciais

Administração:

```text
Admin
zabbix
```

Consulta:

```text
operador
Operador@2026!Lab
```

## Dados Monitorados

Cada host possui os seguintes itens:

- disponibilidade do Zabbix Agent;
- tempo de funcionamento;
- utilização de CPU por processos;
- utilização de memória;
- utilização do sistema de arquivos raiz;
- disponibilidade do serviço HTTP;
- identificação do sistema operacional.

Não é utilizado o template completo `Linux by Zabbix agent`. Isso evita centenas de itens, descobertas e gráficos que não são necessários para o laboratório.

## Verificação

```powershell
.\scripts\status.ps1
```

Depois de aproximadamente um minuto:

```text
Monitoring -> Latest data
```

Selecione ARCH01, ARCH02 ou ARCH03.

## Simulação de Falha

```powershell
.\scripts\parar-host.ps1 arch02
```

Restaurar:

```powershell
.\scripts\iniciar-host.ps1 arch02
```

## Carga de CPU

```powershell
.\scripts\carga-cpu.ps1 arch03 180
```

## Serviço HTTP

```powershell
.\scripts\parar-web.ps1 arch01
```

Restaurar:

```powershell
.\scripts\iniciar-web.ps1 arch01
```

## Latência

```powershell
.\scripts\adicionar-latencia.ps1 arch01 150ms 30ms
```

## Perda

```powershell
.\scripts\adicionar-perda.ps1 arch01 10%
```

Remover alteração:

```powershell
.\scripts\limpar-rede.ps1 arch01
```

## SNMP

```powershell
.\scripts\snmp-teste.ps1 arch01
```

## Reinicialização do Estado Experimental

```powershell
.\scripts\reset-lab.ps1
```

## Remoção Completa

```powershell
docker compose down -v
```

Esse comando também remove o banco PostgreSQL. Na próxima execução o Zabbix será configurado novamente.
