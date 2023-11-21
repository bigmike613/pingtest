#!/bin/bash
if [ "$EUID" -ne 0 ]
  then echo "Please run this script as root!!"
exit
fi
while getopts "d" flag;
do
case "$flag" in
    d)
    for n in $(podman ps -a --format {{.Names}})
    do
    systemctl disable $n".service"
    rm -f $n".service"
    rm -f /etc/systemd/system/$n".service"
    #podman generate systemd --name $n >$n".service"
    #cp $n".service" /etc/systemd/system
    #systemctl enable $n".service"
    done
    exit
esac
done

for n in $(podman ps -a --format {{.Names}})
do
systemctl disable $n".service"
rm -f $n".service"
rm -f /etc/systemd/system/$n".service"
podman generate systemd --name $n >$n".service"
cp $n".service" /etc/systemd/system
systemctl enable $n".service"
rm -f $n".service"
done