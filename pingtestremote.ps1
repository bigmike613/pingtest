
$apikey=$env:apikey
$poll_id=$env:poll_id
$srv=$env:srv
$srv1="http://$srv/api/api1.php"
$srv2="http://$srv/api/api2.php"
$request=@{poll_id=$poll_id;apikey=$apikey}
write-host $request $srv1 $srv2
while(1 -eq 1){
$dataj = invoke-webrequest -uri $srv1 -method post -body $request 

$data = $dataj | convertfrom-json
$results=@()

$devices=$data.data
if($null -eq $devices){
    write-host "No Devices for this poller"
}
else{
foreach ($device in $devices){
#---------first ping test
$result = Test-Connection -ComputerName $device.ip -quiet -Count 1 #-timeout 1
if ($result)
{
#-----------first ping passes
#write-host $device.devicename " pings"
$device | add-member -NotePropertyname status -NotePropertyValue 1
$results+=$device
}
else
{
#-----------first ping fails // second ping test
$result2 = Test-Connection -ComputerName $device.ip -quiet -Count 1 #-timeout 1
if($result2){
#-----------second ping passes
}
else{
#----------second ping fails
#write-host $device.devicename " Does not ping"
$device | add-member -NotePropertyname status -NotePropertyValue 0
$results+=$device
}
}
}

$json = @{apikey=$apikey;data=$results}

$rjson = convertto-json -inputobject $json

invoke-webrequest -uri $srv2 -method POST -body $rjson 
}
start-sleep 60
}
