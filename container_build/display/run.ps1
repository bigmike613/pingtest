$display_ver="10.21.24"
write-host "display version: $display_ver"
write-host "RUN FILE START"
import-module simplysql
$PT_PASS=$env:PT_PASS
$username = "mike"
$password = ConvertTo-SecureString $PT_PASS -AsPlainText -Force
$psCred = New-Object System.Management.Automation.PSCredential -ArgumentList ($username, $password)

Import-Module $PSScriptRoot\dctemp.ps1

#$logfile = /root/log.txt
try{
open-mysqlconnection -server mysql -cred $psCred -database ALERTING -erroraction stop
close-sqlconnection
}
catch {
write-host "sql db not configured, waitng for ping engine to configure"
Copy-Item /etc/pingtest/bad.ico -Destination /etc/pingtest_web/bad.ico
Copy-Item /etc/pingtest/good.ico -Destination /etc/pingtest_web/good.ico
start-sleep 30
}

$i=0
while ($i -lt 5){
  write-host "RUN LOOP START"
  $starttime=get-date
$queryall="SELECT DISTINCT results.devicename, results.status, results.time, results.ip
FROM
    (SELECT devicename, MAX(time) AS time
    FROM results
    GROUP BY devicename) max_time
JOIN results ON max_time.devicename = results.devicename AND max_time.time = results.time
WHERE results.time > DATE_SUB(NOW(), INTERVAL 2 minute) order by status,devicename;"


$queryalldown="SELECT DISTINCT results.devicename, results.status, results.time, results.ip FROM 
(SELECT devicename, MAX(time) AS time     FROM results     GROUP BY devicename) max_time JOIN results ON max_time.devicename = results.devicename 
AND max_time.time = results.time WHERE results.status = 0  AND results.time > DATE_SUB(NOW(), INTERVAL 2 minute)  order by 
status,devicename;"

$querynewlasthour="select * from lasthour where lasthour.ip in (select ip from devices where enabled = 1) order by currentstatus, devicename;"


open-mysqlconnection -server mysql -cred $psCred  -database ALERTING
$title=invoke-sqlquery -query "select setting_value from settings where setting='title';"
$title=$title[0].tostring()
$bgcolor=invoke-sqlquery -query "select setting_value from settings where setting='bg_color';"
$bgcolor=$bgcolor[0].tostring()
$goodicon="<link rel='icon' type='image/x-icon' href='good.ico'>"
$badicon="<link rel='icon' type='image/x-icon' href='bad.ico'>"

$devices = invoke-sqlquery -query "select * from devices;"
if ($null -eq $Devices){
  write-host "no devices"
$head + $body + "<p align=center>There are currenlty no devices configured.<br> go to this site /admin to configure devices.<br><br>Default Username:admin<br>Default Password:PingTest!!
</p>" + $end| Out-File /etc/pingtest_web/index.html
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


# checks if devices that are down are enabled, only adds devices that are enabled.
$newresultsdown=@()
foreach ($device in $resultsdown){
#write-host $device.devicename
$ip=""
$ip = $device.ip 
#write-host $ip
$enabled = invoke-sqlquery -query "select enabled from devices where ip='$ip';"
#write-host $enabled[0]
if ($enabled[0] -eq $TRUE){
$newresultsdown +=$device
}
}
$resultsdown = $newresultsdown
$countbad = $resultsdown | Measure-Object | select -ExpandProperty Count

write-host "hour query"
$resultshour=invoke-sqlquery -query $querynewlasthour
write-host "last update query"
$lastupdate=invoke-sqlquery -query "select time from results order by time desc limit 1;"

#temperature display
write-host "temperature query"
$tempdevices = invoke-sqlquery -query "select setting_value from settings where setting='temp';"
$tempdevices = $tempdevices.setting_value
$tempout = get-temphtml ($tempdevices)

$countbadhour = $resultshour | Measure-Object | select -ExpandProperty Count
close-sqlconnection

if ($countbad -gt 0){
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
h1{
text-shadow: 0 0 15px black;
color: white;
}
tr{
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
text-shadow: 0 0 15px black;
color: white;
}
#temp{
font-size:20px;
text-shadow: 0 0 15px black;
color: white;
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

$lastupdate=$lastupdate[0].tostring()
write-host "last update: $lastupdate"
$body="
<body style=`"background-image: url('BG.jpg'); background-size: 100% 100%; background-color:$bgcolor;`">
<p align=center><b>Update Time:</b></p>
<script type=`"text/javascript`">
        var timeupdated=`"$lastupdate`";
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
                const canWakeLock = () => 'wakeLock' in navigator;
        let wakelock;
        async function lockWakeState() {
          if(!canWakeLock()) return;
          try {
            wakelock = await navigator.wakeLock.request();
            wakelock.addEventListener('release', () => {
              console.log('Screen Wake State Locked:', !wakelock.released);
            });
            console.log('Screen Wake State Locked:', !wakelock.released);
          } catch(e) {
            console.error('Failed to lock wake state with reason:', e.message);
          }
        }
       lockWakeState();
</script>
"

$body += $tempout

$end="
</body>
</html>"

$tabledown= $resultsdown | ConvertTo-Html -As Table -Property status,devicename -fragment| foreach {
   $PSItem -replace "<tr><td>True</td>", "<tr style='background-color:#008000'><td>Up</td>"} | foreach{
   $PSItem -replace "<tr><td>False</td>", "<tr style='background-color:#ff0000'><td>Down</td>"
}
$tabledown =$tabledown -replace "<table>","<div class=`"row`"><div class=`"column`"><p align=center><b>Devices Down Now: $countbad</b></p><table>"
$tabledown =$tabledown -replace "</table>","</table></div>"
$tabledown=$tabledown -replace "status","Latest Status"
$tabledown=$tabledown -replace "devicename","Device Name"

$tablehour= $resultshour |  ConvertTo-Html -As Table -Property currentstatus,devicename,lastdowntime -fragment| foreach {
   $PSItem -replace "<tr><td>True</td>", "<tr style='background-color:#008000'><td>Up</td>"} | foreach{
   $PSItem -replace "<tr><td>False</td>", "<tr style='background-color:#ff0000'><td>Down</td>"
}


$tablehour =$tablehour -replace "<table>","<div class=`"column`"><p align=center><b>Devices Down In The Last Hour: $countbadhour</b></p><table>"
$tablehour =$tablehour -replace "</table>","</table></div>"
$tablehour=$tablehour -replace "lastdowntime","Last Down At"
$tablehour=$tablehour -replace "currentstatus","Latest Status"
$tablehour=$tablehour -replace "devicename","Device Name"


$head + $body  + $tabledown + $tablehour + $end| Out-File /etc/pingtest_web/index.html
}

$endtime=get-date
$runtime=$endtime-$starttime
write-host "loop ran in $runtime"
write-host "sleep 45 seconds"
start-sleep 45
write-host "RUN LOOP END"
write-host ""

}