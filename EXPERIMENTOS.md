# Roteiro de Experimentos

## Objetivo

Observar o funcionamento de um NMS e relacionar eventos de uma infraestrutura monitorada às áreas funcionais do FCAPS.

## Ambiente

| Host | Função | IP interno |
|---|---|---|
| ARCH01 | Servidor Web | 172.28.0.21 |
| ARCH02 | Servidor de Dados | 172.28.0.22 |
| ARCH03 | Servidor de Arquivos | 172.28.0.23 |

O monitoramento é realizado pelo Zabbix.

## Experimento 1 — Reconhecimento do Ambiente

1. Acesse a interface do Zabbix.
2. Localize os três hosts.
3. Observe CPU, memória, interfaces e disponibilidade.
4. Identifique no ambiente o NMS, o gerente, os agentes e os dispositivos gerenciados.
5. Verifique quais informações são mantidas no histórico.

## Experimento 2 — Falha de Host

Interrompa o ARCH02:

```powershell
.\scripts\parar-host.ps1 arch02
```

Observe a alteração no Zabbix e registre:

1. Host afetado;
2. Horário aproximado da detecção;
3. Informação utilizada para indicar a indisponibilidade;
4. Área do FCAPS principalmente relacionada;
5. Ação de gerenciamento adequada.

Restaure o host:

```powershell
.\scripts\iniciar-host.ps1 arch02
```

## Experimento 3 — Utilização de CPU

Gere carga no ARCH03:

```powershell
.\scripts\carga-cpu.ps1 arch03 180
```

Observe:

1. Comportamento da CPU antes do evento;
2. Comportamento durante o evento;
3. Histórico dos valores;
4. Área do FCAPS principalmente relacionada;
5. Diferença entre disponibilidade e desempenho.

## Experimento 4 — Indisponibilidade de Serviço

Interrompa o serviço Web no ARCH01:

```powershell
.\scripts\parar-web.ps1 arch01
```

Compare a indisponibilidade de um serviço com a indisponibilidade completa de um host.

Restaure o serviço:

```powershell
.\scripts\iniciar-web.ps1 arch01
```

## Experimento 5 — Relação com FCAPS

Classifique as situações observadas:

| Situação | Área FCAPS |
|---|---|
| Host indisponível | |
| Serviço Web indisponível | |
| CPU com utilização elevada | |
| Alteração de configuração de um recurso | |
| Tentativa de acesso administrativo não autorizado | |
| Histórico de utilização de recursos | |

Considere que uma ocorrência pode envolver mais de uma área, embora normalmente exista uma finalidade principal de gerenciamento.

## Questões de Análise

1. Qual é a função do Zabbix no ambiente?
2. Qual é a diferença entre dispositivo gerenciado e agente?
3. Qual é a utilidade do armazenamento histórico?
4. Uma situação pode envolver mais de uma área do FCAPS? Apresente um exemplo.
5. Quais informações seriam necessárias para investigar uma degradação de desempenho?
