docker compose up -d arch01 arch02 arch03
foreach ($h in @("arch01","arch02","arch03")) {
  docker exec "lab-$h" bash -lc "pkill yes 2>/dev/null || true; tc qdisc del dev eth0 root 2>/dev/null || true" 2>$null
}
Write-Host "Laboratorio restaurado."
