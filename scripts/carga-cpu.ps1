param(
    [ValidateSet("arch01","arch02","arch03")]
    [string]$HostLab = "arch03",
    [int]$Segundos = 180
)

$cmd = @"
for i in `$(seq 1 `$(nproc)); do
    yes > /dev/null &
done
sleep $Segundos
pkill yes || true
"@

docker exec -d "lab-$HostLab" bash -lc $cmd
Write-Host "Carga de CPU iniciada em $HostLab por aproximadamente $Segundos segundos."
