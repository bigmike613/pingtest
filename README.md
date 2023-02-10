# pingtest
A lightweight dashboard to show ping results.

A lightweight dashboard of ping results. It pulls devices from a mysql database, pings them once per minute and returns the result on a webpage.
It also shows any devices that were down at least once in the last hour. note that only devices that are down are shown. 
setup:
1. create docker containers from compose.yaml
2. add devices - go to http://dockerurl:8080 using Microsoft Edge browser, login with the default password of admin/PingTest!!

<img src="https://github.com/bigmike613/pingtest/blob/d921cc28ead6c0c543d2d0ca70bd8838843100a7/pingtest.png">
