param([ValidateSet("arch01","arch02","arch03")][string]$HostLab="arch02")
docker compose start $HostLab
Write-Host "$HostLab foi iniciado."
