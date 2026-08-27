param([ValidateSet("arch01","arch02","arch03")][string]$HostLab="arch01")
docker exec "lab-$HostLab" bash -lc "tc qdisc del dev eth0 root 2>/dev/null || true"
Write-Host "Alteracoes artificiais removidas de $HostLab."
