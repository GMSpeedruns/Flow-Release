-- This file is server-sided so not every client has to receive this massive amount of text even when they barely ever see it

Lang = {}

Lang.Default = "The message identifier '1;' does not exist! Please report to an admin!"
Lang.Generic = "1;"

function Lang:Get( szIdentifier, varArgs )
	if not Lang[ szIdentifier ] then
		varArgs = { szIdentifier }
		szIdentifier = "Default"
	end
	
	if not varArgs or not type( varArgs ) == "table" then
		varArgs = {}
	end
	
	local szText = Lang[ szIdentifier ]
	for nParamID, szArg in pairs( varArgs ) do
		szText = string.gsub( szText, nParamID .. ";", szArg )
	end
	
	return szText
end

Lang.TimerFinish = "You completed the map in 1;!2;3;"
Lang.TimerPBFirst = "1;2; got a new personal best of 3; [Rank 4;]"
Lang.TimerPBNext = "1;2; got a new personal best of 3; (Improved by 4;) [Rank 5;]"
Lang.TimerWRFirst = "1;2; beat the 3; place in the top 10 with a new personal best of 4; [Rank 5;]"
Lang.TimerWRNext = "1;2; beat the 3; place in the top 10 with a new personal best of 4; (Improved by 5;) [Rank 6;]"
Lang.TimerWRBot = "1; run has been recorded and is now displayed by the WR bot!"

Lang.StyleEqual = "Your style is already set to 1;"
Lang.StyleChange = "Your style has been changed to 1;!"
Lang.StyleLimit = "You can't use those movements in your selected style."
Lang.StyleNoclip = "You can only use noclip in the practice style. Type !practice or !p to go into practice."
Lang.StyleBonusNone = "There are no available bonus to play."
Lang.StyleBonusFinish = "You finished the bonus in 1;!2;3;"
Lang.StyleFreestyle = "You have 1; freestyle zone.2;"
Lang.StyleLeftRight = "Your timer has been stopped for using +left or +right!"
Lang.StyleTeleport = "You can only teleport while in practice style. Type !practice or !p to go into practice."

Lang.BotEnter = "1;-style replay bot has been spawned."
Lang.BotSlow = "Your time was not good enough to be displayed by the WR bot (+1;)."
Lang.BotDisplay = "[1;] 2;'s 3; run (Time: 4;) has been recorded and is now set to be displayed by the WR bot!"
Lang.BotInstRecord = "You are now being recorded by the WR bot1;"
Lang.BotInstFull = "You couldn't be recorded by the bot because the list is already full!"
Lang.BotClear = "You are now no longer being recorded by the bot."
Lang.BotStatus = "You are currently 1; recorded by the bot."
Lang.BotAlready = "You are already being recorded by the WR bot."
Lang.BotStyleForce = "Your 1; run wasn't recorded because this map is forced to 2; style."
Lang.BotSaving = "The server will now save the bots, prepare for some lag!"
Lang.BotMultiWait = "The bot must have at least finished playback once before it can be changed."
Lang.BotMultiInvalid = "The entered style was invalid or there are no bots for this style."
Lang.BotMultiNone = "There are no bots of different styles to display."
Lang.BotMultiError = "An error occurred when trying to retrieve data to display. Please wait and try again."
Lang.BotMultiSame = "The bot is already playing this style."
Lang.BotMultiExclude = "The bot can not display the Normal style run. Check the main bot for that!"
Lang.BotDetails = "The bot run was done by 1; [2;] on the 3; style in a time of 4; at this date: 5;"

Lang.ZoneStart = "You are now placing a zone. Move around to see the box in real-time. Press \"Set Zone\" again to save."
Lang.ZoneFinish = "The zone has been placed."
Lang.ZoneCancel = "Zone setting has been cancelled."
Lang.ZoneNoEdit = "You are not setting any zones at the moment."
Lang.ZoneSpeed = "You can't leave this zone with that speed. (1;)"

Lang.VotePlayer = "1; has Rocked the Vote! (2; 3; left)"
Lang.VoteStart = "A vote to change map has begun. Make your choice!"
Lang.VoteExtend = "The vote has decided that the map is to be extended by 1; minutes!"
Lang.VoteChange = "The vote has decided that the map is to be changed to 1;!"
Lang.VoteMissing = "The map 1; is not available on the server so it can't be played right now."
Lang.VoteLimit = "Please wait for 1; seconds before voting again."
Lang.VoteAlready = "You have already Rocked the Vote."
Lang.VotePeriod = "A map vote has already started. You cannot vote right now."
Lang.VoteRevoke = "1; has revoked his Rock the Vote. (2; 3; left)"
Lang.VoteList = "1; vote(s) needed to change maps.\nVoted (2;): 3;\nHaven't voted (4;): 5;"
Lang.VoteCheck = "There are 1; 2; needed to change maps."
Lang.VoteCancelled = "The vote was cancelled by an admin, thus the map will not change."
Lang.VoteFailure = "Something went wrong while trying to change maps. Please !rtv again."
Lang.VoteVIPExtend = "We need help of the VIPs! The extend limit is 2, do you wish to start a vote to extend anyway? Type !extend or !vip extend."
Lang.RevokeFail = "You can not revoke your vote because you have not Rocked the Vote yet."
Lang.Nomination = "1; has nominated 2; to be played next."
Lang.NominationChange = "1; has changed his nomination from 2; to 3;"
Lang.NominationAlready = "You have already nominated this map!"
Lang.NominateOnMap = "You are currently playing this map so you can't nominate it."

Lang.MapInfo = "The map '1;' has a weight of 2; points (3;)4;"
Lang.MapInavailable = "The map '1;' is not available on the server."
Lang.MapPlayed = "This map has been played 1; times."
Lang.TimeLeft = "There is 1; left on this map."

Lang.PlayerGunObtain = "You have obtained a 1;"
Lang.PlayerGunFound = "You already have a 1;"
Lang.PlayerSyncStatus = "Your sync is 1; being displayed."
Lang.PlayerTeleport = "You have been teleported to 1;"

Lang.SpectateRestart = "You have to be alive in order to reset yourself to the start."
Lang.SpectateTargetInvalid = "You are unable to spectate this player right now."
Lang.SpectateWeapon = "You can't obtain a weapon whilst in spectator mode."

Lang.AdminInvalidFormat = "The supplied value '1;' is not of the requested type (2;)"
Lang.AdminMisinterpret = "The supplied string '1;' could not be interpreted. Make sure the format is correct."
Lang.AdminSetValue = "The 1; setting has succesfully been changed to 2;"
Lang.AdminOperationComplete = "The operation has completed succesfully."
Lang.AdminHierarchy = "The target's permission is greater than or equal to your permission level, thus you cannot perform this action."
Lang.AdminDataFailure = "The server can't load essential data! If you can, contact an admin to make him identify the issue: 1;"
Lang.AdminMissingArgument = "The 1; argument was missing. It must be of type 2; and have a format of 3;"
Lang.AdminErrorCode = "An error occurred while executing statement: 1;"
Lang.AdminFNACReport = "[FNAC] 1;"

Lang.AdminPlayerKick = "1; has been kicked. (Reason: 2;)"
Lang.AdminPlayerBan = "1; has been banned for 2; minutes. (Reason: 3;)"
Lang.AdminChat = "[1;] 2; says: 3;"

Lang.Connect = "1; (2;) has joined the game."
Lang.Disconnect = "1; (2;) has disconnected from the server. (Reason: 3;)"

Lang.MissingArgument = "You have to add 1; argument to the command."
Lang.CommandLimiter = "1; Wait a bit before trying again (2;s)."
Lang.InvalidCommand = "The command '1;' is not a valid command."

Lang.MiscZoneNotFound = "The 1; zone couldn't be found."
Lang.MiscVIPRequired = "This command is exclusively for vips. Type !donate to find out more!"
Lang.MiscVIPGradient = "To efficiently use space on the VIP panel we are making use of the two existing color pickers already on the panel.\nThe tag color will be the start point of your gradient\nand the name color will be the end point of your gradient.\nYou can also pick a custom name if you wish.\nTo set your gradient, press this button again when done selecting (this will close the panel)"
Lang.MiscAbout = "This gamemode, " .. GM.Name .. " v" .. tostring( _C.Version ) .. ", was developed by " .. GM.Author .. " for public usage.\nI want to give out special thanks to the people who have helped me a lot: George and 1337 Designs.\nI hope you will enjoy it!"

Lang.MiscCommandLimit = {
	"Please be gentle on the commands.",
	"Commands have feelings, too!",
	"If you do that one more time...",
	"Stop it, now!",
	"Ouch, my processing power!",
	"That was too soon.",
	"Too soon, man.",
	"Whoa, that was fast.",
	"Are you practicing your typing?",
}

Lang.Servers = {
	-- Add your servers like this:
	-- ["bhop"] = { "IP.ADDRESS.GOES.HERE:27015", "Our Bunny Hop Server" },
	-- ["deathrun"] = { "IP.ADDRESS.GOES.HERE:27015", "Our Deathrun Server" },
}


Lang.Commands = {
	["restart"] = "Resets the player to the start of the map",
	["spectate"] = "Brings the player to spectator mode. Also possible via F2",
	["noclip"] = "Toggles noclip on the player. Practice style required. Also possible via noclip bind.",
	["lj"] = "Toggles status of LJ Statistics",
	["tp"] = "Allows you to teleport to another player",
	
	["rtv"] = "Calls a Rock the Vote. Subcommands: !rtv [who/list/check/revoke/extend]",
	["revoke"] = "Allows the player to revoke their RTV",
	["checkvotes"] = "Prints the requirements for a map vote to happen",
	["votelist"] = "Prints a list of all players and their vote status",
	["timeleft"] = "Displays for how long the map will still be on",
	
	["edithud"] = "Allows the user to move the HUD around on the screen",
	["restorehud"] = "Restores the HUD to its initial position",
	["opacity"] = "Allows the user to change the opacity of the HUD",
	["showgui"] = "Allows the user to change the visibility of the GUI",
	["sync"] = "Toggles visibility of sync on their GUI",
	
	["style"] = "Opens a window for the player to select a style",
	["nominate"] = "Opens a window for the player to nominate a map for a vote",
	["wr"] = "Opens the WR list for the style you're currently playing on",
	["rank"] = "Opens a window that shows a list of ranks",
	["top"] = "Opens a window that shows the best players in the server",
	["mapsbeat"] = "Opens a window that shows the maps you have completed and your time on it",
	["mapsleft"] = "Opens a window that shows the maps you haven't completed and their difficulty",
	["mywr"] = "Opens a window that shows all your #1 WRs on your current style",
	
	["crosshair"] = "Toggles the crosshair for the player OR changes settings; type !crosshair help",
	["glock"] = "These commands allow you to spawn in certain weapons",
	["remove"] = "Strip yourself of all weapons",
	["flip"] = "Switches your weapons to the other hand",
	
	["show"] = "Sets or toggles the visibililty of the players. Output depends on given command",
	["showspec"] = "Allows you to change the visibility of the spectator list",
	["chat"] = "Sets or toggles the visibility of the chat. Output depends on given command",
	["muteall"] = "Sets mute status of players. Output depends on given command",
	["playernames"] = "Toggles targetted player labels visibility.",
	["water"] = "Toggles the state of water reflection and water refraction.",
	["decals"] = "Clears the map of all bulletholes and blood",
	["vipnames"] = "Shows the name of the VIP behind their custom name",
	["space"] = "Allows you to toggle holding space",
	
	["bot"] = "Show your bot status. Subcommands: !bot [add/remove]",
	["botsave"] = "A quick access function: Saves your own bot (Same as !bot save)",
	
	["help"] = "The command you just entered. Shows a list of commands and their functions",
	["map"] = "Prints the details about the map that is currently on",
	["plays"] = "Shows how often the map has been played",
	["end"] = "Go to the end zone of the normal timer",
	["endbonus"] = "Go to the end zone of the bonus",
	["hop"] = "Allows you to change server within our network",
	["about"] = "Shows information about the gamemode you're playing",
	["tutorial"] = "Opens a YouTube Video Tutorial in the Steam Browser",
	["website"] = "Opens our website in the Steam Browser",
	["youtube"] = "Opens a YouTube Channel where a lot of our runs are uploaded",
	["forum"] = "Opens our forum in the Steam Browser",
	["donate"] = "Opens our site with the donate page opened",
	["version"] = "Opens the latest change log in the Steam Browser",
	
	["normal"] = "A quick access function: Change style to Normal",
	["sideways"] = "A quick access function: Change style to Sideways",
	["halfsideways"] = "A quick access function: Change style to Half-Sideways",
	["wonly"] = "A quick access function: Change style to W-Only",
	["aonly"] = "A quick access function: Change style to A-Only",
	["legit"] = "A quick access function: Change style to Legit",
	["scroll"] = "A quick access function: Change style to Easy Scroll",
	["bonus"] = "A quick access function: Change style to Bonus",
	["practice"] = "A quick access function: Change style to Practice",
	["wrn"] = "A quick access function: Open Normal WR List",
	["wrsw"] = "A quick access function: Open Sideways WR List",
	["wrhsw"] = "A quick access function: Open Half-Sideways WR List",
	["wrb"] = "A quick access function: Open Bonus WR List",
	["wrl"] = "A quick access function: Open Legit WR List",
	["wra"] = "A quick access function: Open A-Only WR List",
	["wrs"] = "A quick access function: Open Easy Scroll WR List",
	["wrw"] = "A quick access function: Open W-Only WR List",
	["swtop"] = "A quick access function: Open Angled Top List",
	
	["emote"] = "For VIPs only: sends a status message",
	["extend"] = "For VIPs only: enables the extend option",
	["vip"] = "For VIPs only: opens up the VIP panel",
	
	["radio"] = "Opens up our radio",
}

Lang.TutorialLink = "http://www.youtube.com/watch?v=Q3j9ftTk4C8"
Lang.WebsiteLink = "http://www.google.com/" -- Change this
Lang.ChannelLink = "http://www.youtube.com/user/GMSpeedruns/videos" -- Preferably keep this in here, or change it to your YouTube channel
Lang.ForumLink = "http://www.google.com/" -- Change this
Lang.DonateLink = "http://www.google.com/" -- Change this
Lang.ChangeLink = "http://www.google.com/" -- Change this