#!/bin/bash
if [ "$EUID" -ne 0 ]
  then echo "Please run this script as root!!"
exit
fi
while getopts "br" flag;
do
case "$flag" in
    b)
    if [ -d /etc/pingtest_prod/Config_Scripts/SSL/bu ]; then
    now="$(date '+%m-%d-%Y')"
    mv /etc/pingtest_prod/Config_Scripts/SSL/bu /etc/pingtest_prod/Config_Scripts/SSL/bu$now
    mkdir /etc/pingtest_prod/Config_Scripts/SSL/bu
    else
    mkdir /etc/pingtest_prod/Config_Scripts/SSL/bu
    fi
    podman cp PingTest_nginx:/etc/nginx/snippets/ssl-params.conf /etc/pingtest_prod/Config_Scripts/SSL/bu/ssl-params.conf
    podman cp PingTest_nginx:/etc/ssl/certs/webcert.crt /etc/pingtest_prod/Config_Scripts/SSL/bu/webcert.crt
    podman cp PingTest_nginx:/etc/ssl/certs/dhparam.pem /etc/pingtest_prod/Config_Scripts/SSL/bu/dhparam.pem
    podman cp PingTest_nginx:/etc/nginx/snippets/certs.conf /etc/pingtest_prod/Config_Scripts/SSL/bu/certs.conf
    podman cp PingTest_nginx:/etc/ssl/private/webkey.key /etc/pingtest_prod/Config_Scripts/SSL/bu/webkey.key
    podman cp PingTest_nginx:/etc/nginx/conf.d/default.conf /etc/pingtest_prod/Config_Scripts/SSL/bu/default.conf
    podman cp PingTest_nginx:/etc/nginx/nginx.conf /etc/pingtest_prod/Config_Scripts/SSL/bu/nginx.conf
    exit
    ;;
    r)
    podman stop PingTest_nginx
    podman cp /etc/pingtest_prod/Config_Scripts/SSL/bu/ssl-params.conf PingTest_nginx:/etc/nginx/snippets/ssl-params.conf
    podman cp /etc/pingtest_prod/Config_Scripts/SSL/bu/webcert.crt PingTest_nginx:/etc/ssl/certs/webcert.crt
    podman cp /etc/pingtest_prod/Config_Scripts/SSL/bu/dhparam.pem PingTest_nginx:/etc/ssl/certs/dhparam.pem 
    podman cp /etc/pingtest_prod/Config_Scripts/SSL/bu/certs.conf PingTest_nginx:/etc/nginx/snippets/certs.conf 
    podman cp /etc/pingtest_prod/Config_Scripts/SSL/bu/webkey.key PingTest_nginx:/etc/ssl/private/webkey.key 
    podman cp /etc/pingtest_prod/Config_Scripts/SSL/bu/default.conf PingTest_nginx:/etc/nginx/conf.d/default.conf 
    podman cp /etc/pingtest_prod/Config_Scripts/SSL/bu/nginx.conf PingTest_nginx:/etc/nginx/nginx.conf 
    podman start PingTest_nginx
    exit
    ;;
esac
done
echo "run this script with -b to backup SSL configuration. run with -r to restore ssl config. (note, ssl files must be in folder named bu in the directory of this script.)"