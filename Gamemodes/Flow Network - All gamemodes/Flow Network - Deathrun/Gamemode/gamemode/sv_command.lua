local varFilter = {
	["bae"] = "nigga",
	["bronies"] = "bornies",
	["brony"] = "jabronis",
	["faggot"] = "candy-ass",
	["furries"] = "drama",
	["furry"] = "drama",
	["is a meme"] = "is fucking stupid",
	["jump pack"] = "certificate of infertility",
	["jumpack"] = "anal bead",
	["jumppack"] = "cancer",
	["meme"] = "cliche",
	["nigger"] = "roody-poo",
	["niggers and biscuits"] = "wiggers and triscuits",
	["over 9000"] = "under n (where n<9000)",
	["pointshop"] = "dildoshop",
	["ponies"] = "steve jobs",
	["word filter"] = "doesn't exist",
	["dentntnt"] = "dentnt (the coolest guy in the world)",
}

local _sub, _find, _low, _up, _gs = string.sub, string.find, string.lower, string.upper, string.gsub
local function _rep( s, pat, repl, n )
    pat = _gs( pat, '(%a)', function( v ) return '[' .. _up( v ) .. _low( v ) .. ']' end )
    if n then return _gs( s, pat, repl, n ) else return _gs( s, pat, repl ) end
end

local HelpData, HelpLength, HelpSetter

function GM:PlayerSay( ply, text, team )
	local Prefix = _sub( text, 0, 1 )
	local szCommand = "invalid"
	
	if Prefix != "!" and Prefix != "/" then
		local szFilter = self:FilterText( ply, text )
		if not team then
			return szFilter
		else
			return Admin:HandleTeamChat( ply, szFilter, text )
		end
	else
		szCommand = _low( _sub( text, 2 ) )
	end
	
	local szReply = Command:Trigger( ply, szCommand, text )
	if not szReply or not type( szReply ) == "string" then
		return ""
	else
		return szReply
	end
end

function GM:FilterText( ply, text )
	local low = _low( text )
	if _find( low, "jiggy", 1, true ) then
		Core:Send( ply, "Radio", { "Single", nil, Radio.Misc.jiggy } )
	elseif _find( low, "waitin' for a mate", 1, true ) then
		Core:Send( ply, "Radio", { "Single", nil, Radio.Misc.mate } )
	elseif _find( low, "i'm a rude boy", 1, true ) then
		Core:Send( ply, "Radio", { "Single", nil, Radio.Misc.rude } )
	elseif _find( low, "a problem", 1, true ) then
		HelpSetter = ply:Name()
	elseif HelpSetter and table.HasValue( Radio.Misc.target, ply:SteamID() ) then
		Core:Broadcast( "Radio", { "Single", nil, Radio.Misc.problem, ply:Name() .. ": " .. (string.len( text ) > 8 and text or "No, " .. HelpSetter .. ", not really..." ) } )
		HelpSetter = nil
		return ""
	elseif HelpSetter then
		HelpSetter = nil
	end

	for input,output in pairs( varFilter ) do
		text = _rep( text, input, output )
	end
	
	return text
end

function GM:ShowHelp( ply )
	if not Command:Possible( ply ) then return end
	
	Command:GetHelp()
	
	net.Start( Core.Protocol2 )
	net.WriteString( "Help2" )
	
	if ply.HelpReceived then
		net.WriteUInt( 0, 32 )
	else
		net.WriteUInt( HelpLength, 32 )
		net.WriteData( HelpData, HelpLength )
		ply.HelpReceived = true
	end
	
	net.WriteString( Lang.MiscHelp )
	net.Send( ply )
end

function GM:ShowTeam( ply )
	if not Command:Possible( ply ) then return end
	return Spectator:Command( ply, nil, true )
end

function GM:ShowSpare1( ply )
	if not Command:Possible( ply ) then return end
	return Core:Send( ply, "Client", { "Thirdperson" } )
end

function GM:ShowSpare2( ply )
	if not Command:Possible( ply ) then return end
	return Core:Send( ply, "Client", { "Pointshop" } )
end


Command = {}
Command.Functions = {}
Command.TimeLimit = 0.8
Command.Limiter = {}


function Command:Init()
	-- General commands
	self:Register( { "restart", "r", "redie", "undead", "replay", "start" }, function( ply )
		Command:RemoveLimit( ply )
		Command.Restart( ply )
	end )
	
	self:Register( { "spectate", "spec", "watch", "view" }, function( ply, args )
		if #args > 0 then
			Spectator:Command( ply, args[ 1 ] )
		else
			Spectator:Command( ply )
		end
	end )
	
	self:Register( { "kill", "suicide", "die", "rekt" }, function( ply )
		if GAMEMODE:CanPlayerSuicide( ply ) then
			ply:Kill()
		else
			Core:Send( ply, "Print", { "General", Lang:Get( "SuicideFailed" ) } )
		end
	end )
	
	self:Register( { "thirdperson", "third", "person", "view", "tp", "3rd" }, function( ply )
		Core:Send( ply, "Client", { "Thirdperson" } )
	end )
	
	
	-- RTV commands
	self:Register( { "rtv", "vote", "votemap" }, function( ply, args )
		if #args > 0 then
			if args[ 1 ] == "who" or args[ 1 ] == "list" then
				RTV:Who( ply )
			elseif args[ 1 ] == "check" or args[ 1 ] == "left" then
				RTV:Check( ply )
			elseif args[ 1 ] == "revoke" then
				RTV:Revoke( ply )
			elseif args[ 1 ] == "extend" then
				Admin.VIPProcess( ply, { "extend" } )
			else
				Core:Send( ply, "Print", { "Notification", args[ 1 ] .. " is an invalid subcommand of the rtv command. Valid: who, list, check, left, revoke, extend" } )
			end
		else
			RTV:Vote( ply )
		end
	end )
	
	self:Register( { "revoke", "retreat", "revokertv" }, function( ply )
		RTV:Revoke( ply )
	end )

	self:Register( { "checkvotes", "votecount" }, function( ply )
		RTV:Check( ply )
	end )
	
	self:Register( { "votelist", "listrtv" }, function( ply )
		RTV:Who( ply )
	end )
	
	self:Register( { "timeleft", "time", "rounds", "timeleft", "remaining" }, function( ply )
		RTV:CheckTime( ply )
	end )
	
	self:Register( { "shop", "pointshop", "items", "money", "points" }, function( ply )
		Core:Send( ply, "Client", { "Pointshop" } )
	end )

	
	-- GUI Functionality
	self:Register( { "edithud", "hudedit", "sethud", "movehud" }, function( ply )
		Core:Send( ply, "Client", { "HUDEditToggle" } )
	end )
	
	self:Register( { "restorehud", "hudrestore", "huddefault" }, function( ply )
		Core:Send( ply, "Client", { "HUDEditRestore", { 106, 5 } } )
	end )
	
	self:Register( { "opacity", "hudopacity", "visibility", "hudvisibility" }, function( ply, args )
		if not tonumber( args[ 1 ] ) then
			return Core:Send( ply, "Print", { "General", Lang:Get( "MissingArgument", { "an extra numeric" } ) } )
		end

		Core:Send( ply, "Client", { "HUDOpacity", math.Clamp( tonumber( args[ 1 ] ), 0, 255 ) } )
	end )
	
	self:Register( { "showgui", "showhud", "hidegui", "hidehud", "togglegui", "togglehud" }, function( ply, args )
		if string.sub( args.Key, 1, 4 ) == "show" or string.sub( args.Key, 1, 4 ) == "hide" then
			Core:Send( ply, "Client", { "GUIVisibility", string.sub( args.Key, 1, 4 ) == "hide" and 0 or 1 } )
		else
			Core:Send( ply, "Client", { "GUIVisibility", -1 } )
		end
	end )
	
	-- Windows
	self:Register( { "nominate", "rtvmap", "playmap", "addmap", "maps" }, function( ply, args )
		if #args > 0 then
			Command:RemoveLimit( ply )
			Command.Nominate( ply, nil, args )
		else
			Command:RemoveLimit( ply )
			Core:Send( ply, "GUI_Open", { "Nominate", { RTV.MapListVersion } } )
		end
	end )
	
	self:Register( { "wr", "wrlist", "record", "records", "times" }, function( ply )
		local rec = Timer:GetRecordList()
		if #rec > 0 then
			Core:Send( ply, "GUI_Open", { "WR", rec } )
		else
			Core:Send( ply, "Print", { "Deathrun", Lang:Get( "RecordMissing" ) } )
		end
	end )
	
	-- To-Do: Finish this to show your rank
	self:Register( { "rank", "ranks", "ranklist" }, function( ply )
		Core:Send( ply, "GUI_Open", { "Ranks" } )
	end )
	
	
	-- Weapon functionality
	self:Register( { "crosshair", "cross", "togglecrosshair", "togglecross", "setcross" }, function( ply, args )
		if #args > 0 then
			local szType = args[ 1 ]
			if szType == "color" then
				if not #args == 4 or not tonumber( args[ 2 ] ) or not tonumber( args[ 3 ] ) or not tonumber( args[ 4 ] ) then
					return Core:Send( ply, "Print", { "General", "You need to supply 4 parameters: !crosshair color r g b - Where r, g and b are numbers [0-255]" } )
				end
				
				Core:Send( ply, "Client", { "Crosshair", { ["sl_cross_color_r"] = args[ 2 ], ["sl_cross_color_g"] = args[ 3 ], ["sl_cross_color_b"] = args[ 4 ] } } )
			elseif szType == "length" then
				if not #args == 2 or not tonumber( args[ 2 ] ) then
					return Core:Send( ply, "Print", { "General", "You need to supply 2 parameters: !crosshair length number" } )
				end
				
				Core:Send( ply, "Client", { "Crosshair", { ["sl_cross_length"] = args[ 2 ] } } )
			elseif szType == "gap" then
				if not #args == 2 or not tonumber( args[ 2 ] ) then
					return Core:Send( ply, "Print", { "General", "You need to supply 2 parameters: !crosshair gap number" } )
				end
				
				Core:Send( ply, "Client", { "Crosshair", { ["sl_cross_gap"] = args[ 2 ] } } )
			elseif szType == "thick" then
				if not #args == 2 or not tonumber( args[ 2 ] ) then
					return Core:Send( ply, "Print", { "General", "You need to supply 2 parameters: !crosshair thick number" } )
				end
				
				Core:Send( ply, "Client", { "Crosshair", { ["sl_cross_thick"] = args[ 2 ] } } )
			elseif szType == "opacity" then
				if not #args == 2 or not tonumber( args[ 2 ] ) then
					return Core:Send( ply, "Print", { "General", "You need to supply 2 parameters: !crosshair opacity number - Where number is [0-255]" } )
				end
				
				Core:Send( ply, "Client", { "Crosshair", { ["sl_cross_opacity"] = args[ 2 ] } } )
			elseif szType == "default" then
				Core:Send( ply, "Client", { "Crosshair", { ["sl_cross_color_r"] = 0, ["sl_cross_color_g"] = 255, ["sl_cross_color_b"] = 0, ["sl_cross_length"] = 1, ["sl_cross_gap"] = 1, ["sl_cross_thick"] = 0, ["sl_cross_opacity"] = 255 } } )
			elseif szType == "random" then
				Core:Send( ply, "Client", { "Crosshair", { ["sl_cross_color_r"] = math.random( 0, 255 ), ["sl_cross_color_g"] = math.random( 0, 255 ), ["sl_cross_color_b"] = math.random( 0, 255 ), ["sl_cross_length"] = math.random( 1, 50 ), ["sl_cross_gap"] = math.random( 1, 35 ), ["sl_cross_thick"] = math.random( 0, 10 ), ["sl_cross_opacity"] = math.random( 70, 255 ) } } )
			else
				Core:Send( ply, "Print", { "General", "Available commands: color [red green blue], length [scalar], gap [scalar], thick [scalar], opacity [alpha], default, random" } )
			end
		else
			Core:Send( ply, "Client", { "Crosshair" } )
		end
	end )
	
	self:Register( { "remove", "strip", "stripweapons" }, function( ply )
		ply:StripWeapons()
	end )
	
	self:Register( { "flip", "leftweapon", "leftwep", "lefty", "flipwep", "flipweapon" }, function( ply )
		Core:Send( ply, "Client", { "WeaponFlip" } )
	end )
	
	-- Client functionality
	self:Register( { "show", "hide", "showplayers", "hideplayers", "toggleplayers", "seeplayers", "noplayers" }, function( ply, args )
		if string.sub( args.Key, 1, 4 ) == "show" or string.sub( args.Key, 1, 4 ) == "hide" then
			Core:Send( ply, "Client", { "PlayerVisibility", string.sub( args.Key, 1, 4 ) == "hide" and 0 or 1 } )
		else
			Core:Send( ply, "Client", { "PlayerVisibility", -1 } )
		end
	end )
	
	self:Register( { "chat", "togglechat", "hidechat", "showchat" }, function( ply )
		Core:Send( ply, "Client", { "Chat" } )
	end )
	
	self:Register( { "muteall", "muteplayers", "unmuteall", "unmuteplayers" }, function( ply, args )
		Core:Send( ply, "Client", { "Mute", string.sub( args.Key, 1, 2 ) == "mu" and true or nil } )
	end )
	
	self:Register( { "playernames", "playername", "player", "playertag", "targetids", "targetid", "labels" }, function( ply )
		Core:Send( ply, "Client", { "TargetIDs" } )
	end )
	
	self:Register( { "water", "fixwater", "reflection", "refraction" }, function( ply )
		Core:Send( ply, "Client", { "Water" } )
	end )
	
	self:Register( { "decals", "blood", "shots", "removedecals" }, function( ply )
		Core:Send( ply, "Client", { "Decals" } )
	end )
	
	self:Register( { "vipnames", "disguise", "disguises", "reveal" }, function( ply )
		Core:Send( ply, "Client", { "Reveal" } )
	end )
	
	self:Register( { "space", "spacetoggle", "holdtoggle", "auto" }, function( ply )
		ply.SpaceToggle = not ply.SpaceToggle
		Core:Send( ply, "Print", { "General", "Holding space will now" .. (not ply.SpaceToggle and " no longer" or "") .. " toggle" } )
		Core:Send( ply, "Client", { "Space", true } )
	end )
	
	-- Info commands
	self:Register( { "help", "commands", "command" }, function( ply, args )
		Command:GetHelp()
		
		if #args > 0 then
			local mainArg, th = "", table.HasValue
			for main,data in pairs( Command.Functions ) do
				if th( data[ 1 ], _low( args[ 1 ] ) ) then
					mainArg = main
					break
				end
			end
			
			if mainArg != "" then
				local data = Lang.Commands[ mainArg ]
				if data then
					if string.sub( data, 1, 7 ) == "A quick" or string.sub( data, 1, 7 ) == "For VIP" then
						Core:Send( ply, "Print", { "General", "The !" .. mainArg .. " command is " .. data:gsub("%a", string.lower, 1) } )
					else
						Core:Send( ply, "Print", { "General", "The !" .. mainArg .. " command " .. data:gsub("%a", string.lower, 1) } )
					end
				else
					Core:Send( ply, "Print", { "General", "The command '" .. mainArg .. "' has no documentation" } )
				end
			else
				Core:Send( ply, "Print", { "General", "The command '" .. mainArg .. "' isn't available or has no documentation" } )
			end
		else
			GAMEMODE:ShowHelp( ply )
		end
	end )

	self:Register( { "map", "mapdata", "mapinfo", "difficulty" }, function( ply, args )
		if #args > 0 then
			local real,data = RTV:MapExists( args[ 1 ], nil, true )
			if real then
				Core:Send( ply, "Print", { "General", Lang:Get( "RemoteMapInfo", { args[ 1 ], data[ 1 ], real } ) } )
			else
				Core:Send( ply, "Print", { "General", Lang:Get( "MapInavailable", { args[ 1 ] } ) } )
			end
		else
			local real,data = RTV:MapExists( nil, game.GetMap() )
			Core:Send( ply, "Print", { "General", Lang:Get( "CurrentMapInfo", { data[ 1 ], real } ) } )
		end
	end )
	
	self:Register( { "plays", "playcount", "timesplayed", "howoften", "overplayed" }, function( ply )
		Core:Send( ply, "Print", { "General", Lang:Get( "MapPlayed", { Timer:GetPlays() } ) } )
	end )
	
	self:Register( { "playtime", "timeplayed", "mytime" }, function( ply )
		if ply.ConnectedAt then
			local t = (ply.PlayTime or 0) + math.Round( (CurTime() - ply.ConnectedAt) / 60 )
			Core:Send( ply, "Print", { "General", "You have " .. math.Round( t / 60, 1 ) .. " hours played on this server. You've joined the server " .. (ply.JoinAmount or 1) .. " times." } )
		else
			Core:Send( ply, "Print", { "General", "Couldn't load essential data for calculation." } )
		end
	end )

	self:Register( { "end", "goend", "gotoend", "tpend" }, function( ply )
		if ply:Team() == TEAM_UNDEAD then
			if not Zones.EndPoint then
				return Core:Send( ply, "Print", { "Deathrun", Lang:Get( "UndeadEndNone" ) } )
			end
		
			ply:ResetTimer()
			Core:Send( ply, "Print", { "Deathrun", Lang:Get( "UndeadEndBegin" ) } )
			
			local pos = ply:GetPos()
			timer.Simple( 3, function()
				if ply:GetPos() != pos then
					Core:Send( ply, "Print", { "Deathrun", Lang:Get( "UndeadEndAbort", { math.ceil( (ply:GetPos() - pos):Length2D() ) } ) } )
				else
					ply:SetPos( Zones.EndPoint )
					Core:Send( ply, "Print", { "Deathrun", Lang:Get( "PlayerTeleport", { "the end zone!" } ) } )
				end
			end )
		else
			Core:Send( ply, "Print", { "Deathrun", Lang:Get( "UndeadFailed" ) } )
		end
	end )

	self:Register( { "hop", "switch", "server" }, function( ply, args )
		if #args > 0 then
			local data = Lang.Servers[ args[ 1 ] ]
			if data then
				ply.DCReason = "Player hopped to " .. data[ 2 ]
				Core:Send( ply, "Client", { "Server", data } )
				timer.Simple( 10, function()
					if IsValid( ply ) then
						ply.DCReason = nil
					end
				end )
			else
				Core:Send( ply, "Print", { "General", "The server '" .. args[ 1 ] .. "' is not a valid server." } )
			end
		else
			local servers = "None"
			local tab = {}
			
			for server,data in pairs( Lang.Servers ) do
				table.insert( tab, server )
			end
			
			if #tab > 0 then
				servers = string.Implode( ", ", tab )
			end
			
			Core:Send( ply, "Print", { "General", "Usage: !hop [server id]\nAvailable servers to !hop to: " .. servers } )
		end
	end )
	
	self:Register( { "about", "info", "credits", "author", "owner" }, function( ply )
		Core:Send( ply, "Print", { "General", Lang:Get( "MiscAbout" ) } )
	end )
	
	self:Register( { "tutorial", "tut", "howto", "helppls", "plshelp" }, function( ply )
		Core:Send( ply, "Client", { "Tutorial", Lang.TutorialLink } )
	end )
	
	self:Register( { "website", "flow", "surfline", "fl", "flweb", "web" }, function( ply )
		Core:Send( ply, "Client", { "Tutorial", Lang.WebsiteLink } )
	end )
	
	self:Register( { "youtube", "speedruns", "videos", "video" }, function( ply )
		Core:Send( ply, "Client", { "Tutorial", Lang.ChannelLink } )
	end )
	
	self:Register( { "forum", "forums", "community" }, function( ply )
		Core:Send( ply, "Client", { "Tutorial", Lang.ForumLink } )
	end )
	
	self:Register( { "donate", "donation", "sendmoney", "givemoney", "gibepls" }, function( ply )
		Core:Send( ply, "Client", { "Tutorial", Lang.DonateLink .. "&steam=" .. ply:SteamID() } )
	end )
	
	self:Register( { "version", "lastchange" }, function( ply )
		Core:Send( ply, "Client", { "Tutorial", Lang.ChangeLink } )
	end )
	
	-- VIP only commands
	self:Register( "extend", function( ply )
		Admin.VIPProcess( ply, { "extend" } )
	end )
	
	self:Register( { "emote", "me", "say" }, function( ply, args )
		Admin.VIPProcess( ply, { "me", args.Upper }, true )
	end )
	
	-- To-Do: Remove this once ranks are actually working
	self:Register( "miscrankget", function( ply, args )
		if #args == 1 and tonumber( args[ 1 ] ) and _C.Ranks[ tonumber( args[ 1 ] ) ] then
			ply:SetNWInt( "Rank", tonumber( args[ 1 ] ) )
			sql.Query( "UPDATE dr_players SET nRank = " .. tonumber( args[ 1 ] ) .. " WHERE szID = '" .. ply:SteamID() .. "'" )
		else
			Core:Send( ply, "Print", { "General", Lang:Get( "InvalidCommand", { args.Key } ) } )
		end
	end )
	
	-- Different handler functions
	self:Register( "admin", Admin.CommandProcess )
	self:Register( "vip", Admin.VIPProcess )
	self:Register( { "radio", "groove", "gs", "yt", "song", "play" }, Radio.CommandProcess )
	
	-- Default functions
	self:Register( "invalid", function( ply, args )
		Core:Send( ply, "Print", { "General", Lang:Get( "InvalidCommand", { args.Key } ) } )
	end )
end

function Command:Register( varCommand, varFunc )
	local MainCommand, CommandList = "undefined", { "undefined" }
	if type( varCommand ) == "table" then
		MainCommand = varCommand[ 1 ]
		CommandList = varCommand
	elseif type( varCommand ) == "string" then
		MainCommand = varCommand
		CommandList = { varCommand }
	end

	Command.Functions[ MainCommand ] = { CommandList, varFunc }
end

function Command:Trigger( ply, szCommand, szText )
	if not Command:Possible( ply ) then return nil end

	local szFunc = nil
	local mainCommand, commandArgs = szCommand, {}
	
	if _find( szCommand, " ", 1, true ) then
		local splitData = string.Explode( " ", szCommand )
		mainCommand = splitData[ 1 ]

		local splitDataUpper = string.Explode( " ", szText )
		commandArgs.Upper = {}
		
		for i = 2, #splitData do
			table.insert( commandArgs, splitData[ i ] )
			table.insert( commandArgs.Upper, splitDataUpper[ i ] )
		end
	end
	
	for _, data in pairs( Command.Functions ) do
		for __, alias in pairs( data[ 1 ] ) do
			if mainCommand == alias then
				szFunc = data[ 1 ][ 1 ]
				break
			end
		end
	end

	if not szFunc then szFunc = "invalid" end
	commandArgs.Key = mainCommand

	local varFunc = Command.Functions[ szFunc ]
	if varFunc then
		varFunc = varFunc[ 2 ]
		return varFunc( ply, commandArgs )
	end
	
	return nil
end

function Command:GetHelp()
	if not HelpData or not HelpLength then
		local tab = {}
		
		for command,data in pairs( Command.Functions ) do
			if not Lang.Commands[ command ] then continue end
			table.insert( tab, { Lang.Commands[ command ], data[ 1 ] } )
		end
		
		HelpData = util.Compress( util.TableToJSON( tab ) )
		HelpLength = #HelpData
	end
end


function Command:Possible( ply )
	if not Command.Limiter[ ply ] then
		Command.Limiter[ ply ] = CurTime()
	else
		if CurTime() - Command.Limiter[ ply ] < Command.TimeLimit then
			Core:Send( ply, "Print", { "General", Lang:Get( "CommandLimiter", { Lang.MiscCommandLimit[ math.random( 1, #Lang.MiscCommandLimit ) ], math.ceil( Command.TimeLimit - (CurTime() - Command.Limiter[ ply ]) ) } ) } )
			Command.Limiter[ ply ] = Command.Limiter[ ply ] + 0.5
			return false
		end
		
		Command.Limiter[ ply ] = CurTime()
	end
	
	return true
end

function Command:RemoveLimit( ply )
	Command.Limiter[ ply ] = nil
end

-- To-Do: Check if this works 100% properly
function Command.Restart( ply )
	if not Command:Possible( ply ) then return end
	if ply.LastUndeadSpawn and CurTime() - ply.LastUndeadSpawn < 60 then
		return Core:Send( ply, "Print", { "General", Lang:Get( "UndeadRestart", { math.ceil( 60 - (CurTime() - ply.LastUndeadSpawn) ) } ) } )
	end
	
	ply.LastUndeadSpawn = CurTime()
	
	if ply:Team() != TEAM_UNDEAD then
		if ply:Team() == TEAM_DEATH or ply:Alive() or Player:CountAlive( TEAM_RUNNER ) < 2 then
			Core:Send( ply, "Print", { "Deathrun", Lang:Get( "UndeadFailed" ) } )
		else
			Player:SpawnUndead( ply )
			
			Command:RemoveLimit( ply )
			Command.Restart( ply )
		end
	else
		local wep = ply:GetActiveWeapon()
		if IsValid( wep ) then
			ply.LastWeapon = wep:GetClass()
		else
			ply.LastWeapon = nil
		end
	
		ply:KillSilent()
		ply.GetLoadout = true
		ply:Spawn()
	end
end

function Command.Nominate( ply, _, varArgs )
	if not Command:Possible( ply ) then return end
	if not varArgs[ 1 ] then return end
	local exists,data = RTV:MapExists( varArgs[ 1 ], nil, true )
	if not exists or not data then return Core:Send( ply, "Print", { "Notification", Lang:Get( "MapInavailable", { varArgs[ 1 ] } ) } ) end
	if exists == game.GetMap() then return Core:Send( ply, "Print", { "Notification", Lang:Get( "NominateOnMap" ) } ) end
	
	RTV:Nominate( ply, exists, data[ 1 ] )
end


function Command.ServerCommand( ply, szCmd, varArgs )
	local bConsole = false
	if not IsValid( ply ) and not ply.Name and not ply.Team then
		bConsole = true
	end
	if not bConsole then return end
	
	if szCmd == "gg" then
		Core:Unload( true )
		RunConsoleCommand( "changelevel", game.GetMap() )
	elseif szCmd == "stop" then
		RunConsoleCommand( "exit" )
	elseif szCmd == "dodebug" then
		if CommandIncomplete then
			PrintTable( CommandIncomplete )
		end
	end
end

concommand.Add( "reset", Command.Restart )
concommand.Add( "nominate", Command.Nominate )

concommand.Add( "gg", Command.ServerCommand )
concommand.Add( "stop", Command.ServerCommand )
concommand.Add( "dodebug", Command.ServerCommand )