#!/bin/bash
if [ "$EUID" -ne 0 ]
  then echo "Please run this script as root!!"
exit
fi
while getopts "bri:" flag;
do
case "$flag" in
    i)
    certfile=$OPTARG
    echo "Installing $certfile ......"
    podman cp "$certfile" PingTest_nginx:/etc/ssl/certs/webcertder.crt
    podman exec -it PingTest_nginx openssl x509 -inform DER -in /etc/ssl/certs/webcertder.crt -out /etc/ssl/certs/webcert.crt
    podman exec -it PingTest_nginx mkdir /etc/nginx/snippets
    podman exec -it PingTest_nginx openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048
    podman cp ssl-params.conf PingTest_nginx:/etc/nginx/snippets/ssl-params.conf
    podman cp certs.conf PingTest_nginx:/etc/nginx/snippets/certs.conf
    podman exec -it PingTest_nginx openssl rsa -in /etc/pingtest/webkey.key -out /etc/ssl/private/webkey.key
    podman exec -it PingTest_nginx mv /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/nossl.conf
    podman cp default.conf PingTest_nginx:/etc/nginx/conf.d/default.conf
    podman restart PingTest_nginx
    exit
    ;;
    r)
    podman exec -it PingTest_nginx  mkdir /etc/pingtest
    podman exec -it PingTest_nginx  openssl req -newkey rsa:2048 -keyout /etc/pingtest/webkey.key -out /etc/pingtest/webcert.csr
    podman cp PingTest_nginx:/etc/pingtest/webkey.key webkey.key
    podman cp PingTest_nginx:/etc/pingtest/webcert.csr webcert.csr
    echo "Generate a certificate (in DER format) from this CSR then run this script with -i and the filename of the certificate."
    exit
    ;;
	b)
	podman stop PingTest_nginx
	podman cp nossl.conf PingTest_nginx:/etc/nginx/conf.d/default.conf
	podman start PingTest_nginx
	exit
	;;
esac
done
echo "run this script with -r to generate a signing request, then run it with -i and the certificate file to install. To roll back to no ssl run it with -b"