<?php
	if (!isset($_GET["s"]) || !isset($_GET["m"]) || !isset($_GET["t"]))
	{
		die("This page can only be visited from within Steam Browser!");
	}
	
	$_SERVERS = array(
		"ThisServerIdentifier" => array( 'Gamemode Name', 'IP ADDRESS', 27015 ),
		"AnotherServer" => array( 'Bunny Hop', 'IP ADDRESS', 27015 ),
	);
	
	$requestuser = $_GET["s"];
	$requesttype = $_GET["t"];
	$gamedata = $_SERVERS[$requesttype];
?>

<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
	<title>Server - Loading screen</title>
	
	<link rel="shortcut icon" href="img/favicon.ico">
	<link href='//fonts.googleapis.com/css?family=Open+Sans:300,400' rel='stylesheet' type='text/css'>
	<link rel="stylesheet" type="text/css" href="style.css">
	
	<script src="//ajax.googleapis.com/ajax/libs/jquery/1.11.0/jquery.min.js"></script>
	<script type="text/javascript" src="./script.js"></script>
</head>
<body>
	<div id="data_player" class="<?php echo $requestuser; ?>" style="display: none;"></div>
	<div id="data_server" class="<?php echo $gamedata[1] . ';' . $gamedata[2]; ?>" style="display: none;"></div>
	<center>
		<img class="logo" src="img/logo.png"><br />
		<h2 class="map">
			We're playing: <?php echo $gamedata[0]; ?>
		</h2>
		<table class="userdata">
			<tr>
				<td><img class="icon" src="img/icon_steam.png" /></td>
				<td><b>SteamID: </b><span class="js_steam">Awaiting user...</span></td>
			</tr>
			<tr>
				<td><img class="icon" src="img/icon_user.png" /></td>
				<td><b>User: </b><span class="js_user">Awaiting user...</span></td>
			</tr>
			<tr>
				<td><img class="icon" src="img/icon_map.png" /></td>
				<td><b>Map: </b><span class="js_map">Loading map...</span></td>
			</tr>
			<tr>
				<td><img class="icon" src="img/icon_server.png" /></td>
				<td>
					<b>Server: </b>My Server - <?php echo $gamedata[0]; ?><br />
					<b>Players: </b><span class="js_players">? / ?</span>
				</td>
			</tr>
		</table>
		<div class="data">
			<span class="status"></span><br />
			<span class="downloading"></span><br />
			<span class="progress"></span>
		</div>
	</center>
	<p class="credits">By Gravious</p>
</body>
</html>