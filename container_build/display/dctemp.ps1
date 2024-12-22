function get-temphtml([array]$devlist) {
    if($devlist.length -gt 0){
    $tempdevices=$devlist
    $url = "/api/dev"
    $htmloutput="<div id='temp' align='center'>Current DC Temps.:</br>"
    foreach ($monitor in $tempdevices) {
        try {
            $response = Invoke-WebRequest -uri "http://$monitor$url"  | convertfrom-json
        }
        catch {
            $htmloutput += "<span style='background-color:red;'>unable to connect to $monitor </span>"
            continue
        }
        
        $htmloutput +=$monitor +", "
        $response.data.PSObject.Properties | ForEach-Object {
            $sensordata = [pscustomobject]@{
                label = $_[0].value.label
                value = $_[0].value.entity.'0'.measurement.'0'.value
                unit = $_[0].value.entity.'0'.measurement.'0'.units
                alarm = $_[0].value.entity.'0'.measurement.'0'.alarm[0].state
                }
            
                foreach ($item in $sensordata){
                    if ( $sensordata.alarm -eq "clear"){
                            $htmloutput += $item.label + ": " + $item.value + " " + $item.unit + ", "
                    }
                    else{
                            $htmloutput += "<span style='background-color:red;'>" +$item.label + ": " + $item.value  + " " + $item.unit + ", </span>"
                    }
               }
            }
            $htmloutput += "</br>"
             }
         $htmloutput +="</div>"
    #write-host $htmloutput
    #$htmloutput | out-File test.html
return $htmloutput
            }
            else{
                return ""
            }
}
