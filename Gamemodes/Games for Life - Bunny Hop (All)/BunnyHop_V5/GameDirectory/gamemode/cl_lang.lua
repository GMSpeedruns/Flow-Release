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


Lang.Finish = "You finished in 1;!"
Lang.FinishJumps = "You finished in 1; with 2; jumps!"
Lang.PointDisplay = "For completing the map you have obtained 1; rank points!"
Lang.PBFirst = "You have got a new personal record of 1;! (2;)"
Lang.PBImprove = "You have got a new personal record of 1;! [-2;] (3;)"
Lang.WRFirst = "You have obtained the 1; rank in the top 10 with a new personal record of 2;! (3;)"
Lang.WRImprove = "You have obtained the 1; rank in the top 10 with a new personal record of 2;! [-3;] (4;)"
Lang.WRDefend = "You have defended the 1; rank in the top 10 with a new personal record of 2;! [-3;] (4;)"

Lang.PlayerFinish = "[1;] 2; has finished the map with a time of 3;! (4;)"
Lang.PlayerImprove = "[1;] 2; has finished the map with a time of 3;! [-4;] (5;)"
Lang.PlayerWR = "[1;] 2; has obtained the 3; rank in the top 10 with a time of 4;! (5;)"
Lang.PlayerWRImprove = "[1;] 2; has obtained the 3; rank in the top 10 with a time of 4;! [-5;] (6;)"
Lang.PlayerWRDefend = "[1;] 2; has defended the 3; rank in the top 10 with a time of 4;! [-5;] (6;)"
Lang.PlayerWRRecord = "1;'s run has been recorded and is now displayed by the WR Bot!"

Lang.GunReceive = "You have received 1;"
Lang.GunHave = "You already have 1;"
Lang.GunStrip = "You have been stripped of your weapons!"
Lang.GunGet = "You can't get any new guns because your weapons have been stripped permanently!"
Lang.GunSpec = "You cannot receive guns while in spectator."

Lang.Mode = "Your mode has been switched to 1;!"
Lang.ModeSame = "Your mode is already set to 1;."
Lang.MapPoints = "The map 1; is worth 2; points."
Lang.MapLack = "The map 1; does not exist on our server."
Lang.MapBonus = "There is no bonus timer set for this map."
Lang.FreestyleEnter = "You have entered a freestyle area. All keys are now allowed!"
Lang.FreestyleLeave = "You have left the freestyle area."

Lang.HUDSpecMode = " - Press R to change spectate mode"
Lang.HUDSpecCycle = "Cycle through players with left/right mouse"
Lang.HUDRankPrint = "Rank data has been printed into your console! Press ~ to open."
Lang.HUDRankPoints = "You currently have 1; rank points."
Lang.ScoreMute = "All players have been 1;!"
Lang.ChatHide = "Chat has been 1;!"
Lang.PlayerChatMute = "1; has been 2;."
Lang.PlayerToggle = "Player visibility has been set to 1;"

Lang.Nominate = "1; has nominated 2;"
Lang.NominateChange = "1; has changed his nomination from 2; to 3;"
Lang.AlreadyNominate = "You have already nominated this map!"
Lang.Vote = "1; has voted to Rock the Vote! (2; more needed)"
Lang.Revoke = "1; has revoked his Rock the Vote! (2; more needed)"
Lang.RevokeFail = "You can not revoke your vote because you have not voted."
Lang.VoteWait = "You have to wait 1; minutes before you can Rock the Vote."
Lang.Voted = "You have already voted to Rock the Vote."
Lang.VoteStart = "A vote to change maps has started!"
Lang.MapChange = "Changing the map to 1; in 5 seconds!"
Lang.MapExtend = "The map has been extended by a time of 1; minutes!"
Lang.RecentlyPlayed = "This map was recently played and therefore not nominatable."
Lang.VoteLimit = "Please wait 1; seconds before voting again."
Lang.VotePeriod = "You can not vote right now."
Lang.VoteWho = "List of players (1; required):\nPlayers who voted (2;): 3;\nPlayers who haven't voted (4;): 5;"
Lang.VoteCheck = "There are 1; votes left until map change."

Lang.Teleported = "You have been teleported to 1;"
Lang.TeleportLimit = "You have to be in Practice mode to use this command."
Lang.SpectateRestart = "You have to be alive to use the restart command."
Lang.SpectatorInvalid = "This player is not a valid target to be spectated at this moment."

Lang.BotJoin = "The 1; bot has been spawned!"
Lang.BotSpawn = "You can only start recording when you're inside of the spawn."
Lang.BotMode = "You can not be recorded on this mode."
Lang.BotRecord = "You are now being recorded by the WR Bot!"
Lang.BotRecordStop = "You are no longer being recorded by the WR Bot."
Lang.BotRecordSlow = "Your time was not good enough to be displayed by the WR Bot."
Lang.BotRecordSet = "You are 1; being recorded by the WR Bot."
Lang.BotDisplay = "1;'s 2; run has been recorded and is now set to be displayed by the 3; WR Bot!"
Lang.BotIncomplete = "Your run was not fully recorded from the start."
Lang.BotDisabled = "Bot recording has been disabled for this map."
Lang.BotForce = "Bot recording has been forced to true for this map."
Lang.BotStatus = "Your bot status: 1;"
Lang.BotLimit = "All 1; bot recording slots are already in use."

Lang.LJToggle = "Stats: 1;"
Lang.LJUnits = "1; units"

Lang.Connect = "1; has connected to the server."
Lang.Disconnect = "1; has disconnected from the server."
Lang.StartPlay = "Press F2 or type !spec to start playing!"
Lang.TimeLeft = "There is 1; left on this map."

Lang.SpawnSpeed = "You can't have a high speed in the starting area."
Lang.KeyLimit = "This key is not allowed in 1; play style."
Lang.BindLimit = "This movement is not allowed in 1; play style."
Lang.LeftBlock = "Your timer has been stopped for using 1;"
Lang.ACZoneEnter = "Your timer has been stopped for being in an anti-cheat zone!"
Lang.NoclipLimit = "You can only use noclip in Practice mode."
Lang.TeleportAccess = "You can only teleport in Practice mode."
Lang.TeleportTarget = "No valid teleport target specified."
Lang.TeleportSpec = "You can't teleport to someone while in spectator mode. Use !spectp instead."
Lang.TeleportInSpec = "Your teleport target is currently spectating and thus no valid target."
Lang.TeleportSelf = "You can't teleport to yourself."
Lang.TeleportSuccess = "You have been teleported to 1;!"
Lang.SpecGotoLimit = "You have to be spectating someone to use this command."
Lang.SpecTeleport = "You have been teleported to your spectated target: 1;."

Lang.CommandTimer = "Please wait 1; seconds before trying another command."
Lang.InvalidCommand = "The command '1;' is not a registered command."
Lang.Navigation = { "Previous", "Next", "Close" }

Lang.Commands = {
	{ { "help", "commands", "allcmd" }, "- Lists all commands in console" },
	{ { "mode", "style", "modes", "styles" }, "<mode> - Changes your mode" },
	{ { "nominate" }, "<map> - Nominates a map for voting" },
	{ { "wr", "records" }, "<mode> - Shows the WR Window" },
	{ { "bot" }, "- View your bot status" },
	{ { "bot record" }, "- Record yourself" },
	{ { "bot stop" }, "- Stop recording yourself" },
	{ { "bot who" }, "- View who's being recorded" },
	{ { "timeleft" }, "- View the time left" },
	{ { "rtv", "vote", "votechange" }, "- Rock the Vote!" },
	{ { "rtv check" }, "- Check how many votes are left" },
	{ { "rtv who" }, "- Check who voted and who didn't" },
	{ { "revoke" }, "- Revoke your vote" },
	{ { "pnoclip", "noclip", "clip", "roam" }, "- Go into noclip" },
	{ { "auto", "autohop" }, "- Change mode to Auto" },
	{ { "sideways", "sw", "s" }, "- Change mode to Sideways" },
	{ { "wonly", "w-only", "w" }, "- Change mode to W-Only" },
	{ { "normal", "legit", "scroll", "n" }, "- Change mode to Scroll" },
	{ { "practice", "p" }, "- Change mode to Practice" },
	{ { "bonus", "b" }, "- Change mode to Bonus" },
	{ { "help", "commands" }, "<identifier> - View help" },
	{ { "muteall", "unmuteall" }, "- (Un)mute all players" },
	{ { "spec", "watch" }, "<player> - Spectate a player" },
	{ { "restart", "r" }, "- Restart the map" },
	{ { "remove", "stripweapons" }, "- Remove your weapons" },
	{ { "ranks", "rank" }, "- Prints all ranks to your console" },
	{ { "points", "mappoints" }, "<map> - Shows map points" },
	{ { "chat", "togglechat" }, "- Toggles the chat" },
	{ { "glock", "usp", "knife", "p90", "mp5", "crowbar" }, "- Gives you the weapon" },
	{ { "lj", "ljstats" }, "- Shows LJ Stats" },
	{ { "show", "hide" }, "- Change player visibility" },
	{ { "fixwater", "water" }, "- Disable water reflections" },
	{ { "crosshair", "togglecross" }, "- Toggles weapon crosshair" },
	{ { "decal", "decals", "removedecals" }, "- Cleans up bloody mess" },
	{ { "gotoplayer", "tpto", "teleto", "practicetp" }, "- Teleport to someone" },
	{ { "specgo", "spectele", "spectp" }, "- Teleport to someone from spectator" },
	{ { "top", "toplist", "best" }, "- Shows the top 50 players" },
	{ { "end", "toend", "goend" }, "- Teleports to end" },
	{ { "playtime", "onlinetime", "doihavealife" }, "- Shows your play time" },
	{ { "radio" }, "- Opens the radio" },	
}

Config.SpectatorModes = { "First Person", "Chase Cam", "Free Roam" }

Config.GFLRanks = {
	["founder"] = {Color(85,0,150), "[GFL Founder] "},
	["council"] = {Color(202,228,33), "[GFL Council] "},
	["superadmin"] = {Color(180,50,100), "[GFL S-Admin] "},
	["manager"] = { {r=180,g=50,b=100,a=255, Glow=true, GlowTarget=Color(255,255,0)}, "[Server Manager] "},
	["admin"] = {Color(255,150,50), "[GFL Admin] "},
	["mod"] = {Color(100,200,255), "[GFL Mod] "},
	["moderator"] = {Color(100,200,255), "[GFL Moderator] "},
	["developer"] = {Color(100,200,255), "[GFL Developer] "},
	["trial admin"] = {Color(50,200,180), "[GFL Trial Admin] "},
	["vip"] = { {r=51,g=0,b=230,a=255, Glow=true, GlowTarget=Color(0,255,230)}, "[GFL VIP] "},
	["pedro's bitch"] = { {r=180,g=50,b=100,a=255, Glow=true, GlowTarget=Color(255,255,0)}, "[Pedro's Proud Bitch] "},
	["supporter"] = { {r=100,g=200,b=50,a=255, Glow=true, GlowTarget=Color(255,255,0)}, "[GFL Supporter] "},
	["member"] = {Color(0,117,121), "[GFL Proud Member] "}
}