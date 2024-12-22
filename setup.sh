#!/bin/bash
docker compose pull
echo "please create a password for the new install (do not use single, double quotes or *) then press enter."
read -e usrpass
sed -i "s*putYourPasswordHere*$usrpass*" compose.yaml
echo "please type the IP of the local DNS server then press enter."
read -e usrdns
sed -i "s*8.8.8.8*$usrdns*" compose.yaml
echo "please type the unix timezone (ie. America/New_York)."
read -e usrtz
sed -i "s*America/New_York*$usrtz*" compose.yaml
docker-compose up -d --force-recreate
sed -i "s*$usrpass*putYourPasswordHere*" compose.yaml
sed -i "s*$usrdns*8.8.8.8*" compose.yaml
sed -i "s*$usrtz*America/New_York*" compose.yaml
docker compose up -d