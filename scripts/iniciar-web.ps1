param([ValidateSet("arch01","arch02","arch03")][string]$HostLab="arch01")
docker exec "lab-$HostLab" nginx
Write-Host "Nginx iniciado em $HostLab."
