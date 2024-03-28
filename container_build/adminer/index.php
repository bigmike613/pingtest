<?php
#phpinfo();
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
$sql = "SELECT setting_value FROM settings where setting='title'";
$result = $conn->query($sql);
if ($result->num_rows > 0) {
  // output data of each row
  while($row = $result->fetch_assoc()) {
    $title=$row["setting_value"];
  }
} else {
  echo "DB is initializing, try again soon.";
}
$conn->close();
function get_pass(){
	global $pass;
	return $pass;
}
function adminer_object(){
	class AdminerSoftware extends Adminer {
	 function tableName($tableStatus) {
		  // tables without comments would return empty string and will be ignored by Adminer
		  return h($tableStatus['Comment']);
		}
	 function credentials() {
		  // server, username and password for connecting to database
		  return array('mysql', 'mike', getenv('PT_PASS'));
		}
		function name() {
		  // custom name in title and heading
		  global $title;
		  return $title;
		}
			  function login($login, $password) {
		  // validate user submitted credentials
		  global $hash;
		  if (password_verify($password, $hash))
		  {
			return ($login == 'admin' && TRUE);
		  }
		  else {
			return ($login == 'admin' && FALSE);
		  }
		  
		}
		 function edithint($table, $field, $value) {
           if ($field['field']=='devicename'){
              return "  Enter the device's display name here. (only A-Z 0-9 and . _ - allowed)";
		   }
		   if ($field['field']=='ip'){
              return "  Enter the device's IP or hostname here. (only A-Z 0-9 and . _ - allowed)";
		   }
		   if ($field['field']=='poll_id'){
              return "  Enter the ID of the remote poller here. (only A-Z 0-9 and . _ - allowed, 10 char max.) default is blank";
		   }
		   if ($value=='show_up_devices'){
			$GLOBALS['setting_hint']=" 1=show both up and down devices, 0=show only down devices";
		   }
		   if ($value=='bg_color'){
			$GLOBALS['setting_hint']=" can be any color by name or HTML color code";
		   }
		   if ($value=='admin_pass'){
			$GLOBALS['setting_hint']=" admin password:(only A-Z 0-9 and . _ - ! allowed)";
		   }
		   if ($value=='title'){
			$GLOBALS['setting_hint']=" title for the website: (only A-Z 0-9 and . _ - ! allowed)";
		   }
		   if ($field['field']=='setting_value'){
				return $GLOBALS['setting_hint'];
		   }
		   if ($field['field']=='setting'){
			return " Do not edit this field!";
	   }

		
    }
	
	}
	return new AdminerSoftware;
	}
echo '<div align="right"><a href="admin/chpass.html">Change Password</a></div>';
include './editor.php'
?>
