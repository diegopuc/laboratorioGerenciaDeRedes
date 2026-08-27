param([ValidateSet("arch01","arch02","arch03")][string]$HostLab="arch02")
docker compose stop $HostLab
Write-Host "$HostLab foi parado. Aguarde a deteccao pelo Zabbix."
