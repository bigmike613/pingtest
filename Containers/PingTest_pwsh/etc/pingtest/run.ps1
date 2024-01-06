write-host "RUN FILE START"
import-module simplysql
$PT_PASS=$env:PT_PASS
$username = "mike"
$password = ConvertTo-SecureString $PT_PASS -AsPlainText -Force
$psCred = New-Object System.Management.Automation.PSCredential -ArgumentList ($username, $password)

#$logfile = /root/log.txt
try{
open-mysqlconnection -server mysql -cred $psCred -sslmode required -database ALERTING 

}
catch {
write-host "sql db not configured, configuring."
Copy-Item /etc/pingtest/bad.ico -Destination /etc/pingtest_web/bad.ico
Copy-Item /etc/pingtest/good.ico -Destination /etc/pingtest_web/good.ico
start-sleep 30
open-mysqlconnection -server mysql -user root -pass 'StartupPassDoNotChange' -sslmode required
$query="create user 'mike'@'%' identified by '$PT_PASS';alter user 'root'@'localhost' identified by '$PT_PASS';create database ALERTING;
use ALERTING;
grant all privileges on ALERTING.* to 'mike'@'%';
create table ALERTING.devices ( devicename varchar(255), ip varchar(255), poll_id varchar(10));
ALTER TABLE ALERTING.devices COMMENT='Devices';
create table ALERTING.results (devicename varchar(255), status tinyint(1), time timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP);
create table ALERTING.settings (setting varchar(255), setting_value varchar(255));
insert into ALERTING.settings (setting,setting_value) value ('title','Ping Test Title');
insert into ALERTING.settings (setting,setting_value) value ('admin_pass','PingTest!!');
insert into ALERTING.settings (setting,setting_value) value ('bg_color','#1c87c9');
insert into ALERTING.settings (setting,setting_value) value ('show_up_devices','0');
ALTER TABLE ALERTING.settings COMMENT='Settings';
CREATE EVENT AutoDeleteOldResults
ON SCHEDULE every  1 day 
ON COMPLETION PRESERVE
DO
delete from ALERTING.results where time < DATE_SUB(NOW(), interval 7 day);
CREATE EVENT delete_results_not_in_devices
ON SCHEDULE EVERY 1 hour
DO
  DELETE FROM results
  WHERE devicename NOT IN (SELECT devicename FROM devices);"
invoke-Sqlupdate -Query $query
close-sqlconnection
}
close-sqlconnection
$i=0
while ($i -lt 5){
  write-host "RUN LOOP START"

open-mysqlconnection -server mysql -cred $psCred -sslmode required -database ALERTING 

$devices = invoke-sqlquery -query "select * from devices where poll_id='' or poll_id='1' or poll_id is null;"
#$devices | out-file $logfile
$devices | % -parallel {
#---------first ping test
$device=$_
import-module simplysql
$PT_PASS=$env:PT_PASS
$username = "mike"
$password = ConvertTo-SecureString $PT_PASS -AsPlainText -Force
$psCred = New-Object System.Management.Automation.PSCredential -ArgumentList ($username, $password)


open-mysqlconnection -server mysql -cred $psCred -sslmode required -database ALERTING
$result = Test-Connection -ComputerName $device.ip -quiet -Count 1 -timeout 1
if ($result)
{
#-----------first ping passes
#write-host $device.devicename " pings"

#write-host $device.devicename
$query = "insert into results (devicename,status) values ('" + $device.devicename + "',true);"
#write-host "true update"
invoke-Sqlupdate -Query $query

}
else
{
#-----------first ping fails // second ping test
$result2 = Test-Connection -ComputerName $device.ip -quiet -Count 1 -timeout 1
if($result2){
#-----------second ping passes
$query = "insert into results (devicename,status) values ('" + $device.devicename + "',true);"
invoke-Sqlupdate -Query $query
}
else{
#----------second ping fails
#write-host $device.devicename " Does not ping"

$query = "insert into results (devicename,status) values ('" + $device.devicename + "',false);"
#write-host "false update"
invoke-Sqlupdate -Query $query
}
}
close-sqlconnection
} -ThrottleLimit 255
open-mysqlconnection -server mysql -cred $psCred -sslmode required -database ALERTING

$queryall="SELECT DISTINCT results.devicename, results.status, results.time
FROM
    (SELECT devicename, MAX(time) AS time
    FROM results
    GROUP BY devicename) max_time
JOIN results ON max_time.devicename = results.devicename AND max_time.time = results.time
WHERE results.time > DATE_SUB(NOW(), INTERVAL 2 minute) order by devicename asc;"

$queryalldown="SELECT DISTINCT results.devicename, results.status, results.time
FROM
    (SELECT devicename, MAX(time) AS time
    FROM results
    GROUP BY devicename) max_time
JOIN results ON max_time.devicename = results.devicename AND max_time.time = results.time
WHERE results.status = 0  AND results.time > DATE_SUB(NOW(), INTERVAL 2 minute) order by devicename asc;"

$querylasthourdown="SELECT results.status, results.devicename, results.time
FROM results
INNER JOIN (
  SELECT devicename
  FROM results
  WHERE status = 0 AND time >= DATE_SUB(NOW(), INTERVAL 1 HOUR)
  GROUP BY devicename
) devices ON results.devicename = devices.devicename
WHERE results.time = (SELECT MAX(time) FROM results WHERE devicename = devices.devicename) ORDER BY results.status asc, results.devicename asc;"

$querycountdown="SELECT COUNT(*) as down_devices
FROM
    (SELECT devicename, MAX(time) AS time
    FROM results
    GROUP BY devicename) max_time
JOIN results ON max_time.devicename = results.devicename AND max_time.time = results.time
WHERE results.status = 0 AND results.time > DATE_SUB(NOW(), INTERVAL 2 minute);"




$title=invoke-sqlquery -query "select setting_value from settings where setting='title';"
$title=$title[0].tostring()
$bgcolor=invoke-sqlquery -query "select setting_value from settings where setting='bg_color';"
$bgcolor=$bgcolor[0].tostring()
$goodicon="<link rel='icon' type='image/x-icon' href='good.ico'>"
$badicon="<link rel='icon' type='image/x-icon' href='bad.ico'>"

$countbad = invoke-sqlquery -query $querycountdown

if ($countbad[0] -gt 0){
$head = "<head>
<title>$title</title>
$badicon"
}
else{
$head = "<head>
<title>$title</title>
$goodicon"
}


$head = $head + "<style>
table, th, td {
  border: 1px solid black;
  border-collapse: collapse;
}
th,td{
padding: 10px;
}
table{
margin-left: auto;
margin-right: auto;
overflow-x:auto;
}
tr:hover{
background-color: #f2f2f2;
}
* {
  box-sizing: border-box;
}

.row {
  margin-left:-5px;
  margin-right:-5px;
}
  
.column {
  float: left;
  width: 50%;
  padding: 5px;
}

p{
font-size:20px;
}

/* Clearfix (clear floats) */
.row::after {
  content: `"`";
  clear: both;
  display: table;
}
@media screen and (max-width: 1000px) {
  .column {
    width: 100%;
  }
}
</style>
<h1 align=center>$title</h1>
<script>setTimeout(() => {
  document.location.reload();
}, 30000);
</script>
</head>"

$timenow=invoke-sqlquery -query "select now();"
$timenow=$timenow[0].tostring()
$body="
<body style=`"background-image: url('BG.jpg'); background-size: 100% 100%; background-color:$bgcolor;`">
<p align=center><b>Update Time:</b></p>
<script type=`"text/javascript`">
        var timeupdated=`"$timenow`";
        var currentdate = new Date();
        var month = String(currentdate.getMonth()+1).padStart(2, '0');
        var date = String(currentdate.getDate()).padStart(2, '0');
        var hour = String(currentdate.getHours()).padStart(2, '0');
        var minute = String(currentdate.getMinutes()).padStart(2, '0');
        var timenow= month +`"/`"+ date+`"/`"+ currentdate.getFullYear()+`" `"+ hour+`":`"+ minute+`":`"+currentdate.getSeconds();
        var timenowdate= new Date(timenow);
        var timeupdateddate= new Date(timeupdated);
        var timeupdatedadd10date = new Date(timeupdateddate.getTime() + 10*60000);
        if (timenowdate > timeupdatedadd10date){
                document.write(`"<p align=center style='background-color:red;'>`"+timeupdated+`"</p>`");
        }
        else{
                document.write(`"<p align=center>`"+timeupdated+`"</p>`");
        }
        //document.write(`"</br>`");
        //document.write(`"now: `"+timenowdate);
        //document.write(`"</br>`");
        //document.write(`"server: `"+timeupdateddate);
        //document.write(`"</br>`");
        //document.write(`"server plus10: `" + timeupdatedadd10date);
        //document.write(`"</br>`");
        //document.write(`"now: `"+timenow);
</script>

"

$end="
</body>
</html>"
$devices = invoke-sqlquery -query "select * from devices;"
if ($null -eq $Devices){
  write-host "no devices"
$head + $body + "<p align=center>There are currenlty no devices configured.<br> go to this site /admin to configure devices.<br><br>Default Username:admin<br>Default Password:PingTest!!</p>" + $end| Out-File /etc/pingtest_web/index.html
}
else
{
write-host "down query"
$showup = invoke-sqlquery -query "select setting_value from settings where setting='show_up_devices';"
if ($null -eq $showup){
$resultsdown=invoke-sqlquery -query $queryalldown
write-host "no sql settings for show up"
}
elseif ($showup[0] -eq 1) {
  write-host "sql settings for show up TRUE"
  $resultsdown=invoke-sqlquery -query $queryall
}
else{
  write-host "sql settings for show up FALSE"
  $resultsdown=invoke-sqlquery -query $queryalldown
}

write-host "hour query"
$resultshour=invoke-sqlquery -query $querylasthourdown
$tabledown= $resultsdown | sort-object -property status | ConvertTo-Html -As Table -Property status,devicename,time -fragment| foreach {
   $PSItem -replace "<tr><td>True</td>", "<tr style='background-color:#008000'><td>Up</td>"} | foreach{
   $PSItem -replace "<tr><td>False</td>", "<tr style='background-color:#ff0000'><td>Down</td>"
}
$tabledown =$tabledown -replace "<table>","<div class=`"row`"><div class=`"column`"><p align=center><b>Devices Down Now</b></p><table>"
$tabledown =$tabledown -replace "</table>","</table></div>"
$tabledown=$tabledown -replace "time","Latest Time"
$tabledown=$tabledown -replace "status","Latest Status"
$tabledown=$tabledown -replace "devicename","Device Name"

$tablehour= $resultshour | sort-object -property status | ConvertTo-Html -As Table -Property status,devicename,time -fragment| foreach {
   $PSItem -replace "<tr><td>True</td>", "<tr style='background-color:#008000'><td>Up</td>"} | foreach{
   $PSItem -replace "<tr><td>False</td>", "<tr style='background-color:#ff0000'><td>Down</td>"
}

$tablehour =$tablehour -replace "<table>","<div class=`"column`"><p align=center><b>Devices Down In The Last Hour</b></p><table>"
$tablehour =$tablehour -replace "</table>","</table></div>"
$tablehour=$tablehour -replace "time","Latest Time"
$tablehour=$tablehour -replace "status","Latest Status"
$tablehour=$tablehour -replace "devicename","Device Name"


$head + $body  + $tabledown + $tablehour + $end| Out-File /etc/pingtest_web/index.html
}
close-sqlconnection
write-host "sleep 1 minute"
start-sleep 60
write-host "RUN LOOP END"

}


