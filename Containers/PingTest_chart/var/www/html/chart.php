<?php // content="text/plain; charset=utf-8"
require_once ('jpgraph/jpgraph.php');
require_once ('jpgraph/jpgraph_line.php');
 // Width and height of the graph
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

$device=mysqli_real_escape_string($conn, $_POST['device']);
$tf=mysqli_real_escape_string($conn, $_POST['timeframe']);


if ($tf == "1 day"){
 
$sql = "SELECT status,time FROM results where devicename='$device' AND time > DATE_SUB(now(), INTERVAL 1 day)";
$ticks=30;
}
elseif ($tf == "2 day"){
$sql = "SELECT status,time FROM results where devicename='$device' AND time > DATE_SUB(now(), INTERVAL 2 day)";
$ticks=60;
}
elseif ($tf == "3 day"){
$sql = "SELECT status,time FROM results where devicename='$device' AND time > DATE_SUB(now(), INTERVAL 3 day)";
$ticks=60;
}
elseif ($tf == "4 day"){
$sql = "SELECT status,time FROM results where devicename='$device' AND time > DATE_SUB(now(), INTERVAL 4 day)";
$ticks=90;
}
elseif ($tf == "5 day"){
$sql = "SELECT status,time FROM results where devicename='$device' AND time > DATE_SUB(now(), INTERVAL 5 day)";
$ticks=240;
}
elseif ($tf == "6 day"){
$sql = "SELECT status,time FROM results where devicename='$device' AND time > DATE_SUB(now(), INTERVAL 6 day)";
$ticks=240;
}
elseif ($tf == "7 day"){
$sql = "SELECT status,time FROM results where devicename='$device' AND time > DATE_SUB(now(), INTERVAL 7 day)";
$ticks=240;
}






















$result = $conn->query($sql);
$time=array();
$status=array();
if ($result->num_rows > 0) {
  // output data of each row
  while($row = $result->fetch_assoc()) {
    $time[]=$row['time'];
    //echo $row['time'];
    //echo "-";
    $status[]=$row['status'];
    //echo $row['status'];
    //echo "<br>";
  }
}

 $width = 1200; $height = 400;

// Create a graph instance
$graph = new Graph($width,$height);
 
// Specify what scale we want to use,
// int = integer scale for the X-axis
// int = integer scale for the Y-axis
$graph->SetScale('datint',0,2);


// Setup a title for the graph
$graph->title->Set($device);
 
// Setup titles and X-axis labels
//$graph->xaxis->title->Set('(time)');
 
// Setup Y-axis title
$graph->yaxis->title->Set('(0=down, 1=up)');
$graph->img->SetMargin(100,50,35,150);
$graph->xaxis->scale->ticks->Set($ticks);
$graph->xaxis->SetLabelAngle(50);
 
// Create the linear plot
$lineplot=new LinePlot($status);
$lineplot->SetStepStyle();
$lineplot->SetFillColor("green");
$graph->xaxis->SetTickLabels($time);
//$graph->SetTickDensity(TICKD_SPARSE);

// Add the plot to the graph
$graph->Add($lineplot);
 
// Display the graph
$graph->Stroke();
 

?>
