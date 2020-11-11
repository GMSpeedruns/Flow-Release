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

Lang.PlayerMissing = "Not enough players in-game to start the round!"
Lang.RoundChange = "The map will change after 1; round2;."
Lang.AFKKill = "1; has been killed for being AFK2;."
Lang.StartRound = "The round has been started!"
Lang.EndTime = "The time is up! Preparing next round."
Lang.TeamVictory = "The 1; team has won this round!"
Lang.SingleRunner = "Since you're the only player online, you will be able to run around the map."
Lang.DeathRequired = "Someone disconnected so we needed more deaths, sorry!"

Lang.SuicideFailed = "Sorry, that isn't possible at this moment."
Lang.UndeadFailed = "You must be an Undead Runner to use this command."
Lang.MapChange = "The map will now change to 1;!"
Lang.VoteStart = "A vote to change the map has begun. Make your choice!"
Lang.UndeadSpawn = "You have spawned as an Undead Runner. You can only see your fellow Undead Runners."
Lang.MapInavailable = "The map '1;' is not available on the server."
Lang.CurrentMapInfo = "The map you're currently playing on is called 1; (2;)"
Lang.RemoteMapInfo = "We found a map on our server matching '1;': 2; (3;)"
Lang.MapPlayed = "This map has been played 1; times."
Lang.UndeadEndBegin = "You are being teleported to the end. Don't move for 3 seconds."
Lang.UndeadEndAbort = "Teleport was aborted because you moved 1; units."
Lang.UndeadEndNone = "There is no end zone set on this map."
Lang.UndeadRestart = "You have to wait another 1; seconds before you can restart."
Lang.PlayerTeleport = "You have been teleported to 1;"
Lang.RecordMissing = "There are no records available for this map."

Lang.SpectateTargetInvalid = "You are unable to spectate this player right now."
Lang.SpectateAsDeath = "You can't spectate as a death."
Lang.SpectateAsLast = "You're the last one standing of your team, you can't quit now!"

Lang.ZoneStart = "You are now placing a zone. Move around to see the box in real-time. Press \"Set Zone\" again to save."
Lang.ZoneFinish = "The zone has been placed."
Lang.ZoneCancel = "Zone setting has been cancelled."
Lang.ZoneNoEdit = "You are not setting any zones at the moment."

Lang.TimerRecord = "1; has obtained the #2; time record for this map with a time of 3;!"
Lang.TimerComplete = "You finished the map in 1;"
Lang.TimerSlower = "You finished the map in 1;. You were 2; slower on completing the map."

Lang.Nomination = "1; has nominated 2; to be played next."
Lang.NominationChange = "1; has changed his nomination from 2; to 3;"
Lang.NominationAlready = "You have already nominated this map!"
Lang.NominateOnMap = "You are currently playing this map so you can't nominate it."
Lang.VoteExtend = "The vote has decided that the map is to be extended by 1; rounds!"
Lang.VoteChange = "The vote has decided that the map is to be changed to 1;!"
Lang.VoteCancelled = "The vote was cancelled by an admin, thus the map will not change."
Lang.VoteNotPossible = "Voting is not possible in this period (Please wait 1;)"
Lang.VotePlayer = "1; has Rocked the Vote! (2; 3; left)"
Lang.VoteLimit = "Please wait for 1; seconds before voting again."
Lang.VoteAlready = "You have already Rocked the Vote."
Lang.VotePeriod = "A map vote has already started. You cannot vote right now."
Lang.VoteRevoke = "1; has revoked his Rock the Vote. (2; 3; left)"
Lang.VoteList = "1; vote(s) needed to change maps.\nVoted (2;): 3;\nHaven't voted (4;): 5;"
Lang.VoteCheck = "There are 1; 2; needed to change maps."
Lang.VoteVIPExtend = "We need help of the VIPs! The extend limit is 2, do you wish to start a vote to extend anyway? Type !extend or !vip extend."
Lang.RevokeFail = "You can not revoke your vote because you have not Rocked the Vote yet."

Lang.AdminInvalidFormat = "The supplied value '1;' is not of the requested type (2;)"
Lang.AdminMisinterpret = "The supplied string '1;' could not be interpreted. Make sure the format is correct."
Lang.AdminSetValue = "The 1; setting has succesfully been changed to 2;"
Lang.AdminOperationComplete = "The operation has completed succesfully."
Lang.AdminHierarchy = "The target's permission is greater than or equal to your permission level, thus you cannot perform this action."
Lang.AdminDataFailure = "The server can't load essential data! Please wait until this problem is fixed"
Lang.AdminMissingArgument = "The 1; argument was missing. It must be of type 2; and have a format of 3;"
Lang.AdminErrorCode = "An error occurred while executing statement: 1;"
Lang.AdminFNACReport = "[FNAC] 1;"

Lang.AdminPlayerKick = "1; has been kicked. (Reason: 2;)"
Lang.AdminPlayerSlay = "1; was slain by an admin. (Reason: 2;)"
Lang.AdminPlayerBan = "1; has been banned for 2; minutes. (Reason: 3;)"
Lang.AdminChat = "[1;] 2; says: 3;"

Lang.Connect = "1; (2;) has joined the game."
Lang.Disconnect = "1; (2;) has disconnected from the server. (Reason: 3;)"
Lang.ConnectFirst = "1; has joined the server for the first time. Everyone say welcome!"

Lang.MissingArgument = "You have to add 1; argument to the command."
Lang.CommandLimiter = "1; Wait a bit before trying again (2;s)."
Lang.InvalidCommand = "The command '1;' is not a valid command."

Lang.MiscVIPRequired = "This command is exclusively for vips. Type !donate to find out more!"
Lang.MiscVIPGradient = "To efficiently use space on the VIP panel we are making use of the two existing color pickers already on the panel.\nThe tag color will be the start point of your gradient\nand the name color will be the end point of your gradient.\nYou can also pick a custom name if you wish.\nTo set your gradient, press this button again when done selecting (this will close the panel)"
Lang.MiscAbout = "This gamemode, " .. GM.Name .. " v" .. tostring( _C.Version ) .. ", was developed by " .. GM.Author .. " for Flow Network.\nIt is licensed and only to be used on their servers.\nI want to give out special thanks to the people who have helped me a lot: Dentnt for being a boss.\nI hope you will enjoy it!"
Lang.MiscHelp = "Welcome to Flow Network Deathrun!\n\nThe basic principle of Deathrun is:\n- For a runner: to make it to the end of the map. In the map you face obstacles and traps.\n       You'll have to survive every single one of those.\n- For a death: to kill all the runners by activating the traps in the map.\n\nTo get help for all commands available on the server, type !commands\nTo get help for a specific command, type !help [command]\n\nWe hope you'll enjoy it!\nThe Flow Network Team"

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
	["bheu"] = { "", "Flow Network - EU Bunny Hop" },
	["bhus"] = { "", "Flow Network - US Bunny Hop" },
	["jb"] = { "", "Flow Network - Jailbreak" },
	["surf"] = { "", "Flow Network - Skill Surf" },
	["dr"] = { "", "Flow Network - Deathrun" },
}

Lang.Commands = {
	["restart"] = "Resets the player to the start of the map",
	["spectate"] = "Brings the player to spectator mode. Also possible via F2",
	["kill"] = "Kills the player if possible",
	["thirdperson"] = "Toggles third person mode on the player",
	["shop"] = "Opens the Pointshop",
	
	["rtv"] = "Calls a Rock the Vote. Subcommands: !rtv [who/list/check/revoke/extend]",
	["revoke"] = "Allows the player to revoke their RTV",
	["checkvotes"] = "Prints the requirements for a map vote to happen",
	["votelist"] = "Prints a list of all players and their vote status",
	["timeleft"] = "Displays for how long the map will still be on",
	
	["edithud"] = "Allows the user to move the HUD around on the screen",
	["restorehud"] = "Restores the HUD to its initial position",
	["opacity"] = "Allows the user to change the opacity of the HUD",
	["showgui"] = "Allows the user to change the visibility of the GUI",
	
	["nominate"] = "Opens a window for the player to nominate a map for a vote",
	["wr"] = "Opens a window that shows all top run times for this map",
	["rank"] = "Opens a window that shows all ranks available on the server",
	
	["crosshair"] = "Toggles the crosshair for the player OR changes settings; type !crosshair help",
	["remove"] = "Strips yourself of all weapons",
	["flip"] = "Switches your weapons to the other hand",
	
	["show"] = "Sets or toggles the visibililty of the players. Output depends on given command",
	["chat"] = "Sets or toggles the visibility of the chat. Output depends on given command",
	["muteall"] = "Sets mute status of players. Output depends on given command",
	["playernames"] = "Toggles targetted player labels visibility.",
	["water"] = "Toggles the state of water reflection and water refraction.",
	["decals"] = "Clears the map of all bulletholes and blood",
	["vipnames"] = "Shows the name of the VIP behind their custom name",
	["space"] = "Allows you to toggle holding space",
	
	["help"] = "Shows a list of commands and their functions",
	["map"] = "Prints the details about the map that is currently on",
	["plays"] = "Shows how often the map has been played",
	["playtime"] = "Shows your playtime on the server",
	["end"] = "Teleports you to the end zone of the normal timer",
	["hop"] = "Allows you to change server within our network",
	["about"] = "Shows information about the gamemode you're playing",
	["tutorial"] = "Opens a YouTube Video Tutorial in the Steam Browser",
	["website"] = "Opens Flow Network's website in the Steam Browser",
	["youtube"] = "Opens a YouTube Channel where a lot of our runs are uploaded",
	["forum"] = "Opens the Flow Network Forum in the Steam Browser",
	["donate"] = "Opens the Flow Network Site with the donate page opened",
	["version"] = "Opens the latest change log in the Steam Browser",

	["extend"] = "For VIPs only: enables the extend option",
	["emote"] = "For VIPs only: sends a status message",
	["vip"] = "For VIPs only: opens up the VIP panel",
	
	["radio"] = "Opens up our radio",
}

Lang.TutorialLink = "http://www.youtube.com/watch?v=GSyOoWjO40g"
Lang.WebsiteLink = "http://gmod.flownetwork.co.uk/"
Lang.ChannelLink = "http://www.youtube.com/user/GMSpeedruns/videos"
Lang.ForumLink = "http://forum.flownetwork.co.uk/"
Lang.DonateLink = "http://gmod.flownetwork.co.uk/?action=donate"
Lang.ChangeLink = "http://forum.flownetwork.co.uk/index.php?/forum/30-update-logs/"