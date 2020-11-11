<?php
error_reporting(0); // This is for SteamCondenser
require_once("lib/steam-condenser.php");

if($_POST['action'])
{
	switch($_POST['action'])
	{
		case "obtainPlayerDetails":
		{
			$comid = $_POST['client'];
			if (isset($comid) && is_numeric($comid))
			{
				$steamUser = new SteamId($comid);
				
				$reflectionObject = new ReflectionObject($steamUser);
				$cacheMethod = $reflectionObject->getMethod('cache');
				$cacheMethod->setAccessible(true);
				$cacheMethod->invoke($steamUser);
				
				$steamId = SteamId::convertCommunityIdToSteamId($comid);
				$username = $steamUser->getNickname();
				echo $steamId . ';' . $username;
			}
			else
				echo "STEAM_0:0:00000000;Invalid user received";
			
			break;
		}
		
		case "obtainServerDetails":
		{
			$details = $_POST['server'];
			if (isset($details) && $details != "")
			{
				$array = explode(';', $details, 2);
				if (count($array) != 2)
				{
					echo "Unknown;? / ?";
					return;
				}
				
				try
				{
					$server = new SourceServer($array[0], $array[1]);
					$server->initialize();
					$data = $server->getServerInfo();
					
					if (isset($data) && $data != null)
						echo $data["mapName"] . ';' . ($data["numberOfPlayers"] - $data["botNumber"]) . " (" . $data["numberOfPlayers"] . ") / " . $data["maxPlayers"];
					else
						echo "Unknown;? / ?";
				}
				catch (Exception $e)
				{
					echo "Unknown;? / ?";
				}
			}
			else
				echo "Unknown;? / ?";
			
			break;
		}
	}
}
else
	header("Location: http://www.google.com/");
?>	