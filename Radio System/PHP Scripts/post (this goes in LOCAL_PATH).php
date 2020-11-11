<?php
function youtube_id_from_url($url)
{
	$pattern = 
		'%^# Match any youtube URL
		(?:https?://)?  # Optional scheme. Either http or https
		(?:www\.)?      # Optional www subdomain
		(?:             # Group host alternatives
			youtu\.be/    # Either youtu.be,
			| youtube\.com  # or youtube.com
		(?:           # Group path alternatives
			/embed/     # Either /embed/
			| /v/         # or /v/
			| /watch\?v=  # or /watch\?v=
		)             # End path alternatives.
		)               # End host alternatives.
		([\w-]{10,12})  # Allow 10-12 for 11 char youtube id.
		$%x';
	
    $result = preg_match($pattern, $url, $matches);
    if (false !== $result)
	{
		if (count($matches) > 0)
			return $matches[1];
	}
	
    return false;
}

function grooveshark_valid($url)
{
	if (strpos($url, 'grooveshark.com') !== false)
		return true;
	else
		return false;
}

function song_exist($service, $id)
{
	// This path will be to the php file from the "MySQL Accessor from PHP" folder
	$url = 'http://www.google.com/on_mysql_server_radio.php?type=exist&params=' . $service . ';' . $id;
	$content = @file_get_contents($url);
	return $content;
}

function tickets_scan($service, $id)
{
	foreach (glob("ticket_*.txt") as $filename)
	{
		$content = @file_get_contents($filename);
		if ($content && $content != "")
		{
			$split = explode(";",$content);
			if ($split[0] == $service && $split[1] == $id)
				return true;
		}
	}
	
	return false;
}

function write_ticket($type, $id)
{
	$has = tickets_scan($type, $id);
	if ($has)
		die("S002: Ticket already active");
	else
	{
		$ticket = rand(100000, 999999);
		// This path will be to the php file from the "MySQL Accessor from PHP" folder
		$url = 'http://www.google.com/on_mysql_server_radio.php?type=create&params=' . $ticket;
		$content = @file_get_contents($url);
		
		if ($content == "YES")
		{
			$file = 'ticket_' . $ticket . '.txt';
			$content = $type . ';' . $id;
			$put = @file_put_contents($file, $content);
			
			if ($put)
				echo "S000: Ticket created - " . $ticket;
			else
				die("E004: Couldn't create file of ticket");
		}
		else
			die("E003: Couldn't create ticket - " . $content);
	}
}

$Type = @$_GET["Type"];
$URL = @$_GET["URL"];

if (isset($Type) && is_numeric($Type))
{
	if (!isset($URL))
		die("E000: No URL given");
	
	if ($Type == 1)
	{
		$Parse = youtube_id_from_url($URL);
		if ($Parse)
		{
			$exist = song_exist($Type, $Parse);
			if ($exist == "FREE")
				write_ticket($Type, $Parse);
			else
				die("S001: " . $exist);
		}
		else
			die("E002: Invalid YouTube URL provided");
	}
	elseif ($Type == 3)
	{
		if (is_numeric($URL))
		{
			$Song = @$_GET["Song"];
			$Artist = @$_GET["Artist"];
			
			if (isset($Song) && isset($Artist))
			{
				$exist = song_exist($Type, $URL);
				if ($exist == "FREE")
					write_ticket($Type, $URL . ';' . $Song . ';' . $Artist);
				else
					die("S001: " . $exist);
			}
			else
				die("E002: No provided data found");
		}
		else
		{
			// To-Do: Remove this old revision
			// This was still for when searching went through the web server. Now it's fully within the gamemode, but you can restore it if you want.
			$request = "http://tinysong.com/b/$URL?format=json&key=YOURTINYSONGKEYHERE";
			$content = @file_get_contents($request);
			$json = json_decode($content, true);
			
			if ($json["SongID"] && $json["SongName"])
			{
				$id = $json["SongID"];
				$title = $json["SongName"];
				$artist = "";
				if ($json["ArtistName"])
					$artist = $json["ArtistName"];
				
				$exist = song_exist($Type, $id);
				if ($exist == "FREE")
					write_ticket($Type, $id . ';' . $title . ';' . $artist);
				else
					die("S001: " . $exist);
			}
			else
				die("E002: No results found for " . $URL);
		}
	}
	else
		die("E001: Invalid host type");
}
?>