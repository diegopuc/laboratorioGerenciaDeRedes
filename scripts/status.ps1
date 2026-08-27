docker compose ps

Write-Host ""
try {
    $mapping = docker port lab-zabbix-web 8080/tcp 2>$null | Select-Object -First 1
    if ($mapping -match ":(\d+)$") {
        Write-Host "Zabbix: http://localhost:$($Matches[1])"
    }
}
catch {}

Write-Host ""
Write-Host "Saude dos hosts:"
docker inspect --format "{{.Name}} -> {{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}" lab-arch01 lab-arch02 lab-arch03
