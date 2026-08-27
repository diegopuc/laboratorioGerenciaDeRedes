param([ValidateSet("arch01","arch02","arch03")][string]$HostLab="arch01")
docker exec "lab-$HostLab" nginx -s stop
Write-Host "Nginx parado em $HostLab."
