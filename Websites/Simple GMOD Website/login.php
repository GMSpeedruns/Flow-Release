<?php
class SteamSignIn
{
	const STEAM_LOGIN = 'https://steamcommunity.com/openid/login';

	public static function genUrl($returnTo = false, $useAmp = true)
	{
		$returnTo = (!$returnTo) ? (!empty($_SERVER['HTTPS']) ? 'https' : 'http') . '://' . $_SERVER['HTTP_HOST'] . $_SERVER['SCRIPT_NAME'] : $returnTo;
		
		$params = array(
			'openid.ns'			=> 'http://specs.openid.net/auth/2.0',
			'openid.mode'		=> 'checkid_setup',
			'openid.return_to'	=> $returnTo,
			'openid.realm'		=> (!empty($_SERVER['HTTPS']) ? 'https' : 'http') . '://' . $_SERVER['HTTP_HOST'],
			'openid.identity'	=> 'http://specs.openid.net/auth/2.0/identifier_select',
			'openid.claimed_id'	=> 'http://specs.openid.net/auth/2.0/identifier_select',
		);
		
		$sep = ($useAmp) ? '&amp;' : '&';
		return self::STEAM_LOGIN . '?' . http_build_query($params, '', $sep);
	}
	
	public static function validate()
	{
		$params = array(
			'openid.assoc_handle'	=> $_GET['openid_assoc_handle'],
			'openid.signed'			=> $_GET['openid_signed'],
			'openid.sig'			=> $_GET['openid_sig'],
			'openid.ns'				=> 'http://specs.openid.net/auth/2.0',
		);
		
		$signed = explode(',', $_GET['openid_signed']);
		foreach($signed as $item)
		{
			$val = $_GET['openid_' . str_replace('.', '_', $item)];
			$params['openid.' . $item] = get_magic_quotes_gpc() ? stripslashes($val) : $val; 
		}
		
		$params['openid.mode'] = 'check_authentication';
		
		$data =  http_build_query($params);
		$context = stream_context_create(array(
			'http' => array(
				'method'  => 'POST',
				'header'  => 
					"Accept-language: en\r\n".
					"Content-type: application/x-www-form-urlencoded\r\n" .
					"Content-Length: " . strlen($data) . "\r\n",
				'content' => $data,
			),
			'ssl' => array(
				'verify_peer' => false,
				'verify_peer_name' => false,
			),
		));
		
		$result = file_get_contents(self::STEAM_LOGIN, false, $context);
		
		preg_match("#^http://steamcommunity.com/openid/id/([0-9]{17,25})#", $_GET['openid_claimed_id'], $matches);
		$steamID64 = is_numeric($matches[1]) ? $matches[1] : 0;
		
		return preg_match("#is_valid\s*:\s*true#i", $result) == 1 ? $steamID64 : '';
	}
	
    public static function convertCommunityIdToSteamId($communityId)
	{
        $steamId1  = substr($communityId, -1) % 2;
        $steamId2a = intval(substr($communityId, 0, 4)) - 7656;
        $steamId2b = substr($communityId, 4) - 1197960265728;
        $steamId2b = $steamId2b - $steamId1;

        if($steamId2a <= 0 && $steamId2b <= 0) {
            return '';
        }

        return "STEAM_0:$steamId1:" . (($steamId2a + $steamId2b) / 2);
    }
	
	public static function getRewardsTable()
	{
		$Check = '<img src="assets/img/icon_check.png">';
		$Uncheck = '<img src="assets/img/icon_uncheck.png">';
		
		return "<table class=\"rewards\">
				<tr><td>Reward</td><td>Player</td><td>Normal VIP</td><td>Elevated VIP</td></tr>
				<tr><td>Our eternal gratitude</td><td>$Uncheck</td><td>$Check</td><td>$Check</td></tr>
				<tr><td>Awesome VIP Panel</td><td>$Uncheck</td><td>$Check</td><td>$Check</td></tr>
				<tr><td>Colored chat tags</td><td>$Uncheck</td><td>$Check</td><td>$Check</td></tr>
				<tr><td>Colored custom name</td><td>$Uncheck</td><td>$Check</td><td>$Check</td></tr>
				<tr><td>Colored chat text</td><td>$Uncheck</td><td>$Uncheck</td><td>$Check</td></tr>
				<tr><td>Double AFK timer</td><td>$Uncheck</td><td>$Check</td><td>$Check</td></tr>
				<tr><td>Can gag or mute</td><td>$Uncheck</td><td>$Uncheck</td><td>$Check</td></tr>
				<tr><td>Votes count double</td><td>$Uncheck</td><td>$Uncheck</td><td>$Check</td></tr>
				<tr><td>/me command</td><td>$Uncheck</td><td>$Uncheck</td><td>$Check</td></tr>
				<tr><td>/vip extend command</td><td>$Uncheck</td><td>$Check</td><td>$Check</td></tr>
				<tr><td>Rainbow name</td><td>$Uncheck</td><td>$Uncheck</td><td>$Check</td></tr>
				<tr><td>Gradient name</td><td>$Uncheck</td><td>$Uncheck</td><td>$Check</td></tr>
				<tr><td>Free pizza delivery</td><td>$Uncheck</td><td>$Uncheck</td><td>$Uncheck</td></tr>
				</table><br /><br />";
	}
}
?>