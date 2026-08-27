param(
  [ValidateSet("arch01","arch02","arch03")][string]$HostLab="arch01",
  [string]$Percentual="10%"
)
docker exec "lab-$HostLab" bash -lc "tc qdisc replace dev eth0 root netem loss $Percentual"
Write-Host "Perda aplicada em $HostLab."
