# set the name fo the poller that will be referenced when adding devices
$poll_id='rtpoll'

#edit these variables to point to the main pingtest server
$server = "localhost"
$apikey = "putYourPasswordHere"
$protocol = "http"




get-date | write-host
function get-devicesfromsrv([string]$poll_id, [string]$srv, [string]$apikey, [string]$protocol) {
    $srv1="$protocol"+"://$srv/api/api1.php"
    $request=@{poll_id=$poll_id;apikey=$apikey}
    $dataj = invoke-webrequest -uri $srv1 -method post -body $request -skipcertificatecheck
    if ($dataj -like "*no records found*"){
        write-host "No records found."
        return $null
    }
    $data = $dataj | convertfrom-json

    #uncomment to debug
    #$data.data | ft
    $devices=$data.data
    return $devices
}
function ping-devices ([array]$devices){
    $results=@()
    foreach ($device in $devices){
        #---------first ping test
        $result = Test-Connection -ComputerName $device.ip -quiet -Count 1 -timeout 1
        if ($result)
        {
        #-----------first ping passes
        write-host $device.devicename " pings"
        $device | add-member -NotePropertyname status -NotePropertyValue 1
        $results+=$device
        #write-host $device.devicename
        #$query = "insert into results (devicename,status) values ('" + $device.devicename + "',true);"
        #write-host "true update"
        #invoke-Sqlupdate -Query $query
        
        }
        else
        {
        #-----------first ping fails // second ping test
        $result2 = Test-Connection -ComputerName $device.ip -quiet -Count 1 -timeout 1
        if($result2){
        #-----------second ping passes
        #$query = "insert into results (devicename,status) values ('" + $device.devicename + "',true);"
        #invoke-Sqlupdate -Query $query
        }
        else{
        #----------second ping fails
        write-host $device.devicename " Does not ping"
        $device | add-member -NotePropertyname status -NotePropertyValue 0
        $results+=$device
        #$query = "insert into results (devicename,status) values ('" + $device.devicename + "',false);"
        #write-host "false update"
        #invoke-Sqlupdate -Query $query
        }
        }
        }
        return $results
}
function send-resultstosrv ([array]$results, [string]$srv, [string]$apikey, [string]$protocol){
    $srv2="$protocol"+"://$srv/api/api2.php"
    $request = @{apikey=$apikey;data=$results}
    $body = convertto-json $request
    #uncomment to debug
    #write-host $body
    $response = invoke-webrequest -uri $srv2 -method POST -body $body -skipcertificatecheck
    $output = [string]$response.statuscode + " - " + [string]$response.statusdescription
    return $output
}

#main program

write-host "---- $server ----"
$devices = get-devicesfromsrv -poll_id $poll_id -srv $server -apikey $apikey -protocol $protocol
$results = ping-devices -devices $devices
send-resultstosrv -results $results -srv $server -apikey $apikey -protocol $protocol | write-host


