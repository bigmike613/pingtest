<?php

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
$sql = "SELECT DISTINCT devicename FROM results";
$result = $conn->query($sql);
$devicename=array();
if ($result->num_rows > 0) {
  // output data of each row
  while($row = $result->fetch_assoc()) {
    $devicename[]=$row['devicename'];
    //echo $row['devicename'];
    //echo "<br>";
  }
}

echo "<html><body align=center><H1>Select a device and a timeframe, then click submit to view history</H1><br><form action='history/chart.php' method='post'>";

echo "<H2>Timeframe:</H2><select name='timeframe' id='timeframe'><option value='1 day'>1 day</option><option value='2 day'>2 day</option><option value='3 day'>3 day</option><option value='4 day'>4 day</option><option value='5 day'>5 day</option><option value='6 day'>6 day</option><option value='7 day'>7 day</option></select><br><br>";

$i=0;
while ($i < count($devicename))
{
$device=$devicename[$i];

echo "<input type='radio' id='".$device."' name='device' value='".$device."'><label for='".$device."'>".$device."</label><br>";

$i++;
}


echo "<input type='submit' value='Submit'></form></body></html>";
?>
