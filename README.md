# pingtest
A container based web app that shows the ICMP ping status of devices.

It pulls devices from a mysql database, pings them once per minute and returns the result on a webpage.
It also shows any devices that were down at least once in the last hour. You can view a history of device status by going to http://server/history.
Lastly, you can setup a remote docker container (or any device that runs powershell) to ping devices behind a firewall. only port 80 or 443 needs to be open between the remote poller and the main docker setup.

Setup:
1. git clone https://github.com/bigmike613/pingtest.git
2. docker compose up -d
3. verify 8 containers are running
4. add devices - go to http://<serverurl>/admin , login with the default password of admin/PingTest!!
5. Change admin password click "change password" on admin page.
6. Adjust settings as needed
7. (optional) setup SSL. run Config_Scripts/ssl.sh.

#Config_Scripts:

    SSL:
        
        ssl.sh
        
            this configures SSL for the first time after applicadtion setup.
            run with -r to get a CSR, use CSR to generate a certificate then run with -i and the cert file to install (ie. ssl.sh -i /home/dog/cert.crt)
            run with -b to restore non-ssl config (note the browser will still try to conect via https and will need to have its cache cleared)
        
        sslbu.sh
        
            this backups and restores SSL configuration. run with -b to backup and -r to restore

