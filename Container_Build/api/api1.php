<?php
header("Content-Type:application/json");
$apikey= getenv('apikey');
if (isset($_POST['poll_id']) && $_POST['poll_id']!="" && isset($_POST['apikey']) && $_POST['apikey']!="" ) {
if ($apikey==$_POST['apikey']){
$servername = "mysql";
$username = "mike";
$password = getenv('PT_PASS');
$dbname="ALERTING";
// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);
// Check connection
$response=array();
if ($conn->connect_error) {
  die("Connection failed: " . $conn->connect_error);
} 

        $poll_id = mysqli_real_escape_string($conn, $_POST['poll_id']);
        $result = mysqli_query($conn,"SELECT * FROM `devices` WHERE poll_id='$poll_id'");
        if(mysqli_num_rows($result)>0){
    $i=0;
    while($row = $result->fetch_assoc()) {
        $response['data'][$i]['devicename'] = $row['devicename'];
        $response['data'][$i]['ip'] = $row['ip'];
        $response['data'][$i]['poll_id'] = $row['poll_id'];
    $i++;
    }
    mysqli_close($conn);

  


        }else{
                echo "no records found";
                }
        }
        }else{
        echo 'invalid request';
        }

    $json_response = json_encode($response);
        echo $json_response;

?>