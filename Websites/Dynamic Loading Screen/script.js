var nTotal = 0;
var szProgress = "0%";
var downloadCache = [];

function SetStatusChanged( status )
{
	$('.status').html( "Connection status: " + status );
}

function DownloadingFile( fileName )
{
	downloadCache.push(fileName);
	
	var downloadText = "";
	var downloadLength = downloadCache.length;
	var downloadMin = downloadLength - 5;
	if (downloadMin < 0)
		downloadMin = 0;
	
	var opacity = 1;
	for (var i = downloadLength - 1; i >= downloadMin; i--)
	{
		downloadText = downloadText + "<span style=\"opacity: " + opacity + "\">> " + downloadCache[ i ] + "</span><br />";
		opacity -= 0.15;
	}
	
	$('.downloading').html( "Downloading (" + szProgress + "):<br /><br />" + downloadText );
}

function SetFilesTotal( total )
{
	nTotal = total;
}

function SetFilesNeeded( needed )
{
	if (nTotal == 0) { return; }
	percent = needed / nTotal;
	percent = 1 - percent;
	percent = percent * 100;
	
	szProgress = Math.round( percent )  + "%";
}

function loadPageDetails(client, server)
{
	$.ajax({
		type: "POST", url: "backend.php", data: "action=obtainPlayerDetails&client=" + client,
		complete: function(data){
			var ar = data.responseText.split(/;(.+)?/)
			$('.js_steam').html( ar[ 0 ] );
			$('.js_user').html( ar[ 1 ] );
		}
	});
	
	$.ajax({
		type: "POST", url: "backend.php", data: "action=obtainServerDetails&server=" + server,
		complete: function(data){
			var ar = data.responseText.split(/;(.+)?/)
			$('.js_map').html( ar[ 0 ] );
			$('.js_players').html( ar[ 1 ] );
		}
	});
}

$(document).ready(function(){
	var clientUser = document.getElementById("data_player").className;
	var serverPath = document.getElementById("data_server").className;
	loadPageDetails(clientUser, serverPath);
});