<?php
session_start();
define( "__DEFAULT", "US" ); // Set your default download location here

function get_geo($ip)
{
	$ipdat = @json_decode(file_get_contents("http://www.geoplugin.net/json.gp?ip=" . $ip));
	if ($ipdat && @strlen(trim($ipdat->geoplugin_countryCode)) == 2) {
		return $ipdat->geoplugin_continentCode;
	}
	
    return "US";
}

$urls = array(
	"US" => "http://someid.site.nfoservers.com/fastdl", // This should be the direct link to the path, rather than to the PHP file, or you'll get an infinite loop
	"EU" => "http://files.google.com/garrysmod", // An example path on this file server would be /domains/files/garrysmod/maps/bhop_example.bsp.bz2
);

$base = $urls[__DEFAULT];
if (@isset($_SESSION["access"]))
{
	$base = $_SESSION["access"];
}
else
{
	$geo = get_geo($_SERVER["REMOTE_ADDR"]);
	$base = $geo == "EU" ? $urls["EU"] : $urls["US"];
	
	$_SESSION["access"] = $base;
}

$path = @$_GET["path"];
if (isset($path) && $path != "" && $base != "")
{
	$url = $base . $path;
	header("Location: $url");
	exit();
}
?>