$pt_ver="10.3.24"
write-host "ping engine ver: $pt_ver"
write-host "RUN FILE START"
import-module simplysql
$PT_PASS=$env:PT_PASS
$username = "mike"
$password = ConvertTo-SecureString $PT_PASS -AsPlainText -Force
$psCred = New-Object System.Management.Automation.PSCredential -ArgumentList ($username, $password)
$usernamer = "root"
$passwordr = ConvertTo-SecureString "StartupPassDoNotChange" -AsPlainText -Force
$psCredr = New-Object System.Management.Automation.PSCredential -ArgumentList ($usernamer, $passwordr)

#$logfile = /root/log.txt
try{
open-mysqlconnection -server mysql -cred $psCred -database ALERTING -erroraction stop
close-sqlconnection
}
catch {
write-host "sql db not configured, configuring."
Copy-Item /etc/pingtest/bad.ico -Destination /etc/pingtest_web/bad.ico
Copy-Item /etc/pingtest/good.ico -Destination /etc/pingtest_web/good.ico
start-sleep 30
open-mysqlconnection -server mysql -cred $pscredr
$pwhash='$2y$10$84Sg1IyEvWg9sVeb.VCf1u2RNUJt.CoQSdtro8LknMlkBn/iJCWoW'
$query="create user 'mike'@'%' identified by '$PT_PASS';alter user 'root'@'localhost' identified by '$PT_PASS';create database ALERTING;
use ALERTING;
grant all privileges on ALERTING.* to 'mike'@'%';
create table ALERTING.devices ( devicename varchar(255), ip varchar(255), poll_id varchar(10), enabled tinyint(1) DEFAULT 1, UNIQUE (ip));
ALTER TABLE ALERTING.devices COMMENT='Devices';
create table ALERTING.results (devicename varchar(255), status tinyint(1), time timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP, ip varchar(255), FOREIGN KEY (ip) REFERENCES ALERTING.devices (ip) ON DELETE CASCADE );
create table ALERTING.lasthour (devicename varchar(255), currentstatus tinyint(1), lastdowntime timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP, ip varchar(255), FOREIGN KEY (ip) REFERENCES ALERTING.devices (ip) ON DELETE CASCADE );
create table ALERTING.settings (setting varchar(255), setting_value varchar(255));
insert into ALERTING.settings (setting,setting_value) value ('title','Ping Test Title');
insert into ALERTING.settings (setting,setting_value) value ('admin_hash','$pwhash');
insert into ALERTING.settings (setting,setting_value) value ('bg_color','#1c87c9');
insert into ALERTING.settings (setting,setting_value) value ('show_up_devices','0');
ALTER TABLE ALERTING.settings COMMENT='Settings';
CREATE EVENT AutoDeleteOldResults
ON SCHEDULE every  1 day 
ON COMPLETION PRESERVE
DO
delete from ALERTING.results where time < DATE_SUB(NOW(), interval 7 day);
CREATE EVENT AutoDeletelasthour
ON SCHEDULE every 5 minute
ON COMPLETION PRESERVE
DO
delete from ALERTING.lasthour where lastdowntime < DATE_SUB(NOW(), interval 1 hour);"
invoke-Sqlupdate -Query $query
close-sqlconnection
}

$i=0
while ($i -lt 5){
  write-host "RUN LOOP START"
  $starttime=get-date
open-mysqlconnection -server mysql -cred $psCred  -database ALERTING 
$sqlresult = invoke-sqlquery -query "select * from devices where enabled=1 and poll_id='' or poll_id='1' or poll_id is null;"
close-sqlconnection
$devices=@()
foreach ($device in $sqlresult){
$item = [pscustomobject]@{
devicename = $device.devicename
ip = $device.ip
}
$devices += $item
}
#$devices | out-file $logfile
$devices | % -parallel {
#---------first ping test
$device=$_
$pingable=$false
$result = Test-Connection -ComputerName $device.ip -quiet -Count 2 -timeout 1 -ErrorAction SilentlyContinue
if ($result)
{
#-----------first ping passes
$pingable=$true
}else{
# first ping fails, second attempt
$result2 = Test-Connection -ComputerName $device.ip -quiet -Count 2 -timeout 1 -ErrorAction SilentlyContinue
if ($result2){
# second ping passes
$pingable=$true
}else{
# both pings failed
$pingable=$false
}
}
$_ | Add-Member -MemberType NoteProperty -Name "result" -Value $pingable
} -ThrottleLimit 2000

open-mysqlconnection -server mysql -cred $psCred  -database ALERTING
foreach ($device in $devices){
if ($device.result -eq 0){
$lastq = "select * from lasthour where ip='" + $device.ip + "';"
$sqlresult = invoke-sqlquery -query $lastq
if ($sqlresult){
      $sqltime = invoke-SqlQuery -Query "select CURRENT_TIMESTAMP();"
      $curtime = [DateTime]$sqltime[0]
      $sqltimestr = $curtime.tostring("yyyy-MM-dd HH:mm:ss")
      $query = "insert into results (devicename,ip,status) values ('" + $device.devicename + "','" + $device.ip + "'," + $device.result + ");update lasthour set currentstatus=0, lastdowntime='"+$sqltimestr+"' where ip='"+$device.ip+"';"
}
    else{
      $query = "insert into results (devicename,ip,status) values ('" + $device.devicename + "','" + $device.ip + "'," + $device.result + ");insert into lasthour (devicename,ip,currentstatus) values ('" + $device.devicename + "','" + $device.ip + "'," + $device.result + ");"
    }
}
else{
$query = "insert into results (devicename,ip,status) values ('" + $device.devicename + "','" + $device.ip + "'," + $device.result + ");update lasthour set currentstatus="+$device.result+" where ip='"+$device.ip+"';"
}
#write-host $query
$qresult = invoke-Sqlupdate -query $query
write-host "$qresult - $device"
}
close-sqlconnection
$endtime=get-date
$runtime=$endtime-$starttime
write-host "loop ran in $runtime"
$60sec = New-TimeSpan -Seconds 60
$waittime = $60sec - $runtime
$waittimes=$waittime.Seconds
if ($waittime -gt 0){
write-host "sleep $waittimes seconds"
start-sleep $waittime
}
else{
$waittime = new-timespan -seconds 1
$waittimes=$waittime.Seconds
write-host "sleep $waittimes seconds (negative wait time)"
start-sleep $waittime
}
write-host "RUN LOOP END"

}
