#!/bin/bash
if [ "$EUID" -ne 0 ]
  then echo "Please run this script as root!!"
exit
fi
alias docker=podman
while getopts "bri:" flag;
do
case "$flag" in
    i)
    certfile=$OPTARG
    echo "Installing $certfile ......"
    docker cp "$certfile" PingTest_nginx:/etc/ssl/certs/webcertder.crt
    docker exec -it PingTest_nginx openssl x509 -inform DER -in /etc/ssl/certs/webcertder.crt -out /etc/ssl/certs/webcert.crt
    docker exec -it PingTest_nginx mkdir /etc/nginx/snippets
    docker exec -it PingTest_nginx openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048
    docker cp ssl-params.conf PingTest_nginx:/etc/nginx/snippets/ssl-params.conf
    docker cp certs.conf PingTest_nginx:/etc/nginx/snippets/certs.conf
    docker exec -it PingTest_nginx openssl rsa -in /etc/pingtest/webkey.key -out /etc/ssl/private/webkey.key
    docker exec -it PingTest_nginx mv /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/nossl.conf
    docker cp default.conf PingTest_nginx:/etc/nginx/conf.d/default.conf
    docker restart PingTest_nginx
    exit
    ;;
    r)
    docker exec -it PingTest_nginx  mkdir /etc/pingtest
    docker exec -it PingTest_nginx  openssl req -newkey rsa:2048 -keyout /etc/pingtest/webkey.key -out /etc/pingtest/webcert.csr
    docker cp PingTest_nginx:/etc/pingtest/webcert.csr webcert.csr
    echo "Generate a certificate from this CSR then run this script with -i and the filename of the certificate."
    exit
    ;;
	b)
	docker stop PingTest_nginx
	docker cp nossl.conf PingTest_nginx:/etc/nginx/conf.d/default.conf
	docker start PingTest_nginx
	exit
	;;
esac
done
echo "run this script with -r to generate a signing request, then run it with -i and the certificate file to install. To roll back to no ssl run it with -b"