To use this loading screen, you'll need to edit your server.cfg:
sv_loadingurl "http://www.google.com/?s=%s&m=%m&t=ThisServerIdentifier"

Set the URL to wherever the index.php script will be located.
Set the &t parameter to something that will identify the server the user is connecting to.

Now open index.php and look at $_SERVERS:
	array(
		"ThisServerIdentifier" => array( 'Gamemode Name', 'IP ADDRESS', 27015 ),
		"AnotherServer" => array( 'Bunny Hop', 'IP ADDRESS', 27015 ),
	);
	
Change this accordingly.
This script makes use of jQuery and AJAX to retrieve the data dynamically and not wait for the SteamAPI to return something before we can display anything on the screen.

The "Loading Screen - GFL.zip" file contains the old loading screen (NOT DYNAMIC) for GFL.
They look very alike, but I prefer the latest one.

Gravious