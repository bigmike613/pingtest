# pingtest
A docker based web app that shows the ICMP ping status of devices.

It pulls devices from a mysql database, pings them once per minute and returns the result on a webpage.
It also shows any devices that were down at least once in the last hour. You can view a history of device status by going to http://dockerurl/history.
Lastly, you can setup a remote docker container (or any device that runs powershell) to ping devices behind a firewall. only port 80 or 443 needs to be open between the remote poller and the main docker setup.

Setup:
1. create docker containers from compose.yaml
2. add devices - go to http://dockerurl/admin , login with the default password of admin/PingTest!!
3. adjust settings as needed

<img src="https://github.com/bigmike613/pingtest/blob/d921cc28ead6c0c543d2d0ca70bd8838843100a7/pingtest.png">
