param(
  [ValidateSet("arch01","arch02","arch03")][string]$HostLab="arch01",
  [string]$Atraso="150ms",
  [string]$Variacao="30ms"
)
docker exec "lab-$HostLab" bash -lc "tc qdisc replace dev eth0 root netem delay $Atraso $Variacao"
Write-Host "Latencia aplicada em $HostLab."
