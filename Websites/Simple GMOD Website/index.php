<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
	<title>Flow Network - GMOD</title>
	
	<link rel="shortcut icon" href="assets/img/favicon.ico">
	<link href='//fonts.googleapis.com/css?family=Open+Sans:300,400' rel='stylesheet' type='text/css'>
	<link rel="stylesheet" type="text/css" href="assets/style.css">
	
	<script src="//ajax.googleapis.com/ajax/libs/jquery/1.11.0/jquery.min.js"></script>
</head>
<body>
	<center>
		<a href="/"><img class="logo" src="assets/img/logo.png"></a><br />
		
		<?php
		if( !isset( $_GET["action"] ) )
		{
		?>
		
		<h2 class="map">Welcome to our website!</h2>
		<h3>What are you looking for?</h3>
		
		<br /><br /><br />
		<p>
			Site contents:
			<ul>
				<li><a href="http://www.google.com/">Community Forums</a></li>
				<li><a href="?action=servers">Our Servers</a></li>
				<li><a href="http://steamcommunity.com/groups/SurflineP">Public Steam Group</a></li>
				<li><a href="http://www.google.com/">Change Logs</a></li>
				<li><a href="?action=donate">Donate</a></li>
				<li><a href="?action=gametracker">GameTracker Pages</a></li>
				<li><a href="?action=teamspeak">TeamSpeak Server</a></li>
			</ul>
		</p>
		
		<?php
		}
		else
		{
			$Action = $_GET["action"];
			
			if( $Action == "teamspeak" )
			{
				echo '<br />Download TeamSpeak 3: <a class="high" href="http://www.teamspeak.com/?page=downloads">here</a><br />';
				echo 'TeamSpeak 3 Server Address: <a class="high" href="ts3server://google.ts.com/?port=9987&nickname=Guest">ts.google.com:9987</a>';
			}
			elseif( $Action == "servers" )
			{
				echo '<br />Available Flow Network Servers:<br />';
				echo 'Bunny Hop (US): <a class="high" href="steam://connect/IPADDR:27015">IPADDR:27015</a><br />';
				echo 'Bunny Hop (EU): <a class="high" href="steam://connect/IPADDR:27015">IPADDR:27015</a><br />';
				echo 'Bunny Hop (Straya): <a class="high" href="steam://connect/IPADDR:27015">IPADDR:27015</a>';
			}
			elseif( $Action == "gametracker" )
			{
				echo '<br />GameTracker pages for all our servers:<br />';
				echo 'Bunny Hop (US): <a class="high" href="http://www.gametracker.com/server_info/IPADDR:27015/">here</a><br />';
				echo 'Bunny Hop (US): <a class="high" href="http://www.gametracker.com/server_info/IPADDR:27015/">here</a><br />';
				echo 'Bunny Hop (Straya): <a class="high" href="http://www.gametracker.com/server_info/IPADDR:27015/">here</a><br />';
			}
			elseif( $Action == "donate" )
			{
				$Steam = "";
				if (isset($_GET["steam"]))
					$Steam = $_GET["steam"];
				
				require_once( "login.php" );
				
				echo '<h4 style="font-size: 24px;">Important Notice</h4>';
				echo '<p>First of all, we want to thank you very much for considering donating to Flow Network.<br />
				With the donation process there a few things we want you to take notice of before continuing:</p>
				<ul>
					<li>- For your donation we give you a reward, you do not pay for this service</li>
					<li>- Donations will not be refunded unless rewards are not received on the entered Steam ID</li>
					<li>- If you have entered an incorrect Steam ID, we can only transfer the VIP status over to the correct ID</li>
					<li>- Your VIP will be global and available on all Flow Network servers</li>
					<li>- Your timer will run regardless of if you are signed in or not</li>
					<li>- If you misbehave, you will be banned regardless of your VIP status</li>
				</ul><br />
				<p>If you agree with all of the above, you may continue with donating. If you wish to know more about donating,<br />
				either visit our <a href="/forum">forums</a> or ask administrators in-game.<br /><br />
				The Flow Network Team</p><br />';
				
				echo '<h4>VIP Specifications</h4><br />' . SteamSignIn::getRewardsTable();
				
				if ($Steam != "" || isset($_GET["openid_signed"]))
				{
					if (isset($_GET["openid_signed"]))
					{
						$validate = SteamSignIn::validate();
						if (is_numeric($validate))
							$Steam = SteamSignIn::convertCommunityIdToSteamId($validate);
						else
							die("<h2>Something went wrong while signing in! (Session probably expired)</h2><br /><br />");
					}
					
					// Change line 103
					echo '<h4>Donate using <a href="http://www.paypal.com/">PayPal</a></h4><br />
					<form name="_xclick" action="https://www.paypal.com/cgi-bin/webscr" method="post">
					<input type="hidden" style="display: none;" name="cmd" value="_xclick" style="display: none;">
					<input type="hidden" style="display: none;" name="business" value="BUSINESSIDHASTOGOHERE">
					<input type="hidden" style="display: none;" name="lc" value="US">
					<input type="hidden" style="display: none;" name="item_name" value="Flow Network GMOD Donation">
					Type: <select name="amount">
					<option value="5">1 month VIP ($5)</option>
					<option value="9">2 months VIP ($9 - 10% Discount)</option>
					<option value="14">3 months VIP ($14 - 10% Discount)</option>
					<option value="18">4 months VIP ($18 - 10% Discount)</option>
					<option value="24">6 months VIP ($24 - 20% Discount)</option>
					<option value="32">8 months VIP ($32 - 20% Discount)</option>
					<option value="35">10 months VIP ($35 - 30% Discount)</option>
					<option value="42">1 year VIP ($42 - 30% Discount)</option>
					<option value="10">1 month Elevated VIP ($10)</option>
					<option value="19">2 months Elevated VIP ($20 - 5% Discount)</option>
					<option value="27">3 months Elevated VIP ($27 - 10% Discount)</option>
					<option value="36">4 months Elevated VIP ($36 - 10% Discount)</option>
					<option value="48">6 months Elevated VIP ($48 - 20% Discount)</option>
					<option value="64">8 months Elevated VIP ($64 - 20% Discount)</option>
					<option value="70">10 months Elevated VIP ($70 - 30% Discount)</option>
					<option value="84">1 year Elevated VIP ($84 - 30% Discount)</option>
					<option value="100">Large donation ($100 - Permanent Elevated VIP + More?)</option>
					<option value="150">Bigger donation ($150 - Permanent Elevated VIP + even More??)</option>
					<option value="200">Gigantic donation ($200 - Permanent Elevated VIP + More?!)</option>
					</select>
					<input type="hidden"  style="display: none;"name="currency_code" value="USD">
					<input type="hidden" style="display: none;" name="no_note" value="1">
					<input type="hidden" style="display: none;" name="no_shipping" value="1">
					<input type="hidden" style="display: none;" name="return" value="http://slsurf.site.nfoservers.com/?action=donate_succeed">
					<input type="hidden" style="display: none;" name="cancel_return" value="http://slsurf.site.nfoservers.com/?action=donate_failure">
					<input type="hidden" name="bn" style="display: none;" value="PP-DonationsBF:btn_donateCC_LG.gif:NonHosted"><br /><br />
					<label for="custom">Steam ID:</label>&nbsp;&nbsp;<input type="text" name="custom" value="' . $Steam . '" /><br /><br />
					<input type="image" name="submit" value="Donate using PayPal" alt="Donate using PayPal" src="assets/img/pp_checkout.png"></form>';
				}
				else
				{
					$url = SteamSignIn::genUrl("http://gmod.flownetwork.co.uk/?action=donate");
					echo '<p>We must first make sure you will receive your rewards on the correct account.<br />To validate this, you must log in through Steam.<br /><br />
					<a href="' . $url . '"><img src="http://steamcommunity-a.akamaihd.net/public/images/signinthroughsteam/sits_large_border.png" alt="Sign in through Steam" /></a>';
				}
				
				echo '<br /><br />';
			}
			elseif( $Action == "get_steam" )
			{
				require_once( "login.php" );
				if (isset($_GET["openid_signed"]))
				{
					$validate = SteamSignIn::validate();
					if (is_numeric($validate))
					{
						$Steam = SteamSignIn::convertCommunityIdToSteamId($validate);
						echo '<br /><br /><h2>Your Steam ID: <a href="http://steamcommunity.com/profiles/' . $validate . '" target="_blank">' . $Steam . '</a></h2><br /><br /><p>Click <a href="/" class="high">here</a> to go back.</p>';
					}
					else
						die("<br /><br /><h2>Something went wrong while signing in!</h2><br /><p>Your session probably expired or you refreshed the page.<br /><br />Click <a href=\"?action=get_steam\" class=\"high\">here</a> to try again!</p>");
				}
				else
				{
					$url = SteamSignIn::genUrl("http://gmod.flownetwork.co.uk/?action=get_steam");
					echo '<p><br /><br />If you want to find your Steam ID, please sign in through Steam by clicking on the button below.<br /><br />
					<a href="' . $url . '"><img src="http://steamcommunity-a.akamaihd.net/public/images/signinthroughsteam/sits_large_border.png" alt="Sign in through Steam" /></a></p>
					<br /><p>If you want to find someone else\'s Steam ID, please go to <a href="http://www.steamidfinder.com" class="high" target="_blank">this page</a> and enter their community URL or ID.</p>';
				}
			}
			elseif( $Action == "donate_succeed" )
			{
				echo 'Thank you for your donation! You will receive your goodies very soon.<br />If something isn\'t right, contact us on the forums.';
			}
			elseif( $Action == "donate_failure" )
			{
				echo 'Something went wrong while donating! :(<br />Contact an administrator via the forums as soon as possible.';
			}
			else
			{
				echo "Invalid action specified.<br /><br />Click <a href=\"/\">here</a> to go back!";
			}
		}
		?>
	</center>
</body>
</html>