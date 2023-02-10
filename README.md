# pingtest
A lightweight dashboard to show ping results.

A lightweight dashboard of ping results. It pulls devices from a mysql database, pings them once per minute and returns the result on a webpage.
It also shows any devices that were down at least once in the last hour. note that only devices that are down are shown. 
To add devices (using the default docker compose configuration) go to http://dockerurl:8080 login with the default password of admin/PingTest!! and add devices.
