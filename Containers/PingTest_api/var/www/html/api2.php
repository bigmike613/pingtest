<?php
header("Content-Type:application/json");

$json = file_get_contents('php://input');

$servername = "mysql";
$username = "mike";
$password = getenv('PT_PASS');
$dbname="ALERTING";
// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);
// Check connection

if ($conn->connect_error) {
  die("Connection failed: " . $conn->connect_error);
} 


  
$data = json_decode($json);


$data = $data->data;

foreach ($data as $item){
  $dn=mysqli_real_escape_string($conn, $item->devicename);
  $status=mysqli_real_escape_string($conn, $item->status);
$sql= "insert into results (devicename,status) values ('$dn','$status')";
if ($conn->query($sql) === TRUE) {
  echo "1";
} else {
  echo "Error: " . $sql . "<br>" . $conn->error;
}
}
mysqli_close($conn);


?>
