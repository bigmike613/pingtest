docker run -dit --name PT_Remote -e srv="HostanmeOfMainDockerHost" -e apikey=test12345 -e poll_id=613 miketomasulo/ptremote:latest /bin/pwsh /etc/pingtest/runremote.ps1
