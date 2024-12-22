<?php
header("Content-Type:application/json");
$apikey= getenv('apikey');
//$myfile = fopen("/test/test.log", "w") or die("Unable to open file!");
//fwrite($myfile, $apikey);
$jsonraw = file_get_contents('php://input');
//fwrite($myfile, $jsonraw);
$json = json_decode($jsonraw);
$apikeyfromrequest = $json->apikey;
//fwrite($myfile, $apikeyfromrequest);

if ($apikey==$apikeyfromrequest){

//$txt = "if ran";
//fwrite($myfile, $txt);
$servername = "mysql";
$username = "mike";
$password = getenv('PT_PASS');
$dbname="ALERTING";
// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);
// Check connection
$response=array();
if ($conn->connect_error) {
  http_response_code(500);
  die("Connection failed: " . $conn->connect_error);

} 


$data = $json->data;

foreach ($data as $item){
    //fwrite($myfile, "for each running");
    //$writetxt = $item->devicename;
    //fwrite($myfile, $writetxt);
    $dn=mysqli_real_escape_string($conn, $item->devicename);
    $status=mysqli_real_escape_string($conn, $item->status);
    $ip=mysqli_real_escape_string($conn, $item->ip);

    // insert into results no matter what
    mysqli_query($conn, "insert into results (devicename,status,ip) values ('$dn','$status','$ip')");
    //check if in lasthour
    $result = mysqli_query($conn, "select * from lasthour where ip = '$ip' limit 1");
    if(mysqli_num_rows($result)==1){
      // is in last hour
      if ($status == 0){
        //is down now and in last hour, update lasthour
        mysqli_query($conn, "update lasthour set currentstatus='$status', lastdowntime=now() where ip='$ip'");
    }elseif($status == 1){
      // is up and is in last hour, update last hour
      mysqli_query($conn, "update lasthour set currentstatus='$status' where ip='$ip'");
    }
  }elseif(mysqli_num_rows($result)==0){
      // is not in  last hour
      if ($status==0){
        //is down, add to last hour
        mysqli_query($conn, "insert into lasthour (devicename,currentstatus,ip) values ('$dn','$status','$ip')");
    }
  }

}
mysqli_close($conn);
}else{
  http_response_code(403);
  echo "UNATHORIZED - incorrect API Key";
}

//fclose($myfile);

?>