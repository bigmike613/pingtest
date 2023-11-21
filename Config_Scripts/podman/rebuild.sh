#!/bin/bash
if [ "$EUID" -ne 0 ]
  then echo "Please run this script as root!!"
exit
fi
while getopts "d" flag;
do
case "$flag" in
    d)
    echo "running this script with -d will delete all container volumes, are you sure you want to do this? (reply y)"
    read doit
    if [ "$doit" = "y" ]
    then 
    ./startOnBoot.sh -d
    docker-compose down -v
    docker-compose up -d
    ./startOnBoot.sh
    exit
    else
    exit
    fi
esac
done
./startOnBoot.sh -d
docker-compose down
docker-compose up -d
./startOnBoot.sh
