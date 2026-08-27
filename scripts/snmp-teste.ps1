param([ValidateSet("arch01","arch02","arch03")][string]$HostLab="arch01")
docker exec "lab-$HostLab" snmpget -v2c -c labpublic localhost 1.3.6.1.2.1.1.5.0
docker exec "lab-$HostLab" snmpget -v2c -c labpublic localhost 1.3.6.1.2.1.1.3.0
