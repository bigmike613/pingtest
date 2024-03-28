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
$sql = "SELECT setting_value FROM settings where setting='admin_hash'";
$result = $conn->query($sql);
if ($result->num_rows > 0) {
  // output data of each row
  while($row = $result->fetch_assoc()) {
    $hash=$row["setting_value"];
  }
} else {
  echo "DB is initializing, try again soon.";
}

$oldPass = $_POST['oldPassword'];
$newPass = $_POST['newPassword'];
$confirmPass = $_POST['confirmPassword'];

if (password_verify($oldPass, $hash)) {
//echo "old pass is good";
if ($newPass == $confirmPass){
$newhash = password_hash($newPass, PASSWORD_DEFAULT);

$sql = "UPDATE settings SET setting_value='$newhash' WHERE setting='admin_hash'";
//echo $sql;

if ($conn->query($sql) === TRUE) {
  echo "Password updated successfully";
} else {
  echo "Error!";
}



}
else{
echo "The new passwords do not match";
}
}
else{
echo "Old password is not correct";
}

//echo $hash;
//echo $oldPass;
//echo $newPass;
//echo $confirmPass;

$conn->close();

?>