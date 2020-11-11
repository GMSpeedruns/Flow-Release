function GM:PlayerSay( ply, text )
	local Prefix = string.sub( text, 0, 1 )
	local szCommand = "invalid"
	
	if Prefix != "!" and Prefix != "/" then
		return self:FilterText( text )
	else
		szCommand = string.lower( string.gsub( string.gsub( text, "!", "" ), "/", "" ) )
	end
	
	local szReply = Command:Trigger( ply, szCommand, text )
	
	if not szReply or not type( szReply ) == "string" then
		return ""
	else
		return szReply
	end
end

function GM:FilterText( text )
	-- To-Do: Actually filter shit here, like non-ascii characters
	return text
end

function GM:ShowHelp( ply )
	if ply.Spectating then return end
	
	ply.ThirdPerson = 1 - ply.ThirdPerson
	ply:SendLua( "Client.ThirdPerson = " .. ply.ThirdPerson )
end

function GM:ShowTeam( ply )
	ply:SendLua( "Window:Open('Spectate')" )
end

function GM:ShowSpare1( ply )
--[[	if ply.Spectating then return end
	
	ply.ThirdPerson = 1 - ply.ThirdPerson
	ply:SendLua( "Client.ThirdPerson = " .. ply.ThirdPerson )]]
end


Command = {}
Command.Functions = {}
Command.TimeLimit = 1

Command.Settings = {
	LeftBlock = true,
	AFKLimit = true
}

function Command:Init()
	-- Main Commands
	self:Register( { "help", "commands", "allcmd" }, function( ply )
		ply:SendLua( "Client:ListCommands()" )
	end )
	
	self:Register( { "restart", "r" }, function( ply )
		Command.Restart( ply )
	end )
	
	self:Register( { "spec", "watch" }, function( ply, args )
		if #args > 0 then
			if type( args[1] ) == "string" then
				local ar = Spectator:GetAlive()
				local target = nil
				local search = string.lower( args[1] )
				for id, p in pairs( ar ) do
					if string.find( string.lower( p:Name() ), search, 1, true ) then
						target = p:UniqueID()
						break
					end
				end
				if target then
					if ply.Spectating then
						return Spectator:NewById( ply, target )
					else
						args[1] = target
					end
				end
			end

			Command.Spectate( ply, nil, args )
		else
			Command.Spectate( ply )
		end
	end )
	
	self:Register( { "muteall", "unmuteall" }, function( ply, args )
		ply:SendLua( args.Key .. "()" )
	end )

	self:Register( { "chat", "togglechat" }, function( ply )
		ply:SendLua( "togglechat()" )
	end )
	
	self:Register( { "lj", "ljstats" }, function( ply )
		LJ:Toggle( ply )
	end )

	self:Register( { "remove", "stripweapons" }, function( ply )
		ply:StripWeapons()
		Message:Single( ply, "GunStrip", Config.Prefix.Game )
	end )
	
	self:Register( { "ranks", "rank" }, function( ply )
		ply:SendLua( "Client:ShowRanks(" .. Player:GetProfileParam( ply, "Rank", 1 ) .. "," .. Player:GetProfileParam( ply, "Points", 0 ) .. ")" )
	end )
	
	self:Register( { "top", "toplist", "best" }, function( ply )
		Data:Single( ply, "TopList", { Player:GetTop( ply ) } )
	end )
	
	self:Register( { "points", "mappoints" }, function( ply, args )
		local szMap = game.GetMap()
		if #args > 0 then
			szMap = args[1]
		end
		
		if Map.ServerList[ szMap ] then
			Message:Single( ply, "MapPoints", Config.Prefix.Command, { szMap, Map.ServerList[ szMap ].Points } )
		else
			Message:Single( ply, "MapLack", Config.Prefix.Command, { szMap } )
		end
	end )
	
	self:Register( { "glock", "usp", "knife", "p90", "mp5", "crowbar" }, function( ply, args )
		if ply.Spectating or ply:Team() == TEAM_SPECTATOR then
			return Message:Single( ply, "GunSpec", Config.Prefix.Command )
		end
		
		local Found = false
		for _,ent in pairs( ply:GetWeapons() ) do
			if ent:GetClass() == "weapon_" .. args.Key then
				Found = true
				break
			end
		end
		if not Found then
			ply:Give( "weapon_" .. args.Key )
			Message:Single( ply, "GunReceive", Config.Prefix.Command, { "a " .. args.Key } )
		else
			Message:Single( ply, "GunHave", Config.Prefix.Command, { "a " .. args.Key } )
		end
	end )
	
	self:Register( { "show", "hide" }, function( ply, args )
		ply:SendLua( "Client:Visibility(" .. (args.Key == "hide" and 0 or 1) .. ")" )
	end )
	
	self:Register( { "fixwater", "water" }, function( ply )
		ply:SendLua( "Client:WaterFix()" )
	end )
	
	self:Register( { "decals", "decal", "removedecals" }, function( ply )
		ply:SendLua( "Client:DecalFix()" )
	end )
	
	self:Register( { "crosshair", "togglecross" }, function( ply )
		if IsValid( ply:GetActiveWeapon() ) then
			ply:GetActiveWeapon():SetNWBool( "NoCrosshair", not ply:GetActiveWeapon():GetNWBool( "NoCrosshair" ) )
		end
	end )
	
	-- Mode Commands
	self:Register( { "auto", "autohop" }, function( ply ) Command.Mode( ply, nil, { Config.Modes["Auto"] } ) end )
	self:Register( { "sideways", "sw", "s" }, function( ply ) Command.Mode( ply, nil, { Config.Modes["Sideways"] } ) end )
	self:Register( { "wonly", "w-only", "w" }, function( ply ) Command.Mode( ply, nil, { Config.Modes["W-Only"] } ) end )
	self:Register( { "normal", "legit", "scroll", "n" }, function( ply ) Command.Mode( ply, nil, { Config.Modes["Scroll"] } ) end )
	self:Register( { "practice", "p" }, function( ply ) Command.Mode( ply, nil, { Config.Modes["Practice"] } ) end )
	self:Register( { "bonus", "b" }, function( ply ) Command.Mode( ply, nil, { Config.Modes["Bonus"] } ) end )
	
	self:Register( { "noclip", "clip", "pnoclip", "roam" }, function( ply )
		Command.NoClip( ply )
	end )
	
	self:Register( { "gotoplayer", "tpto", "teleto", "practicetp" }, function( ply, args )
		if ply.Mode == Config.Modes["Practice"] then
			if ply.Spectating or IsValid( ply:GetObserverTarget() ) then
				return Message:Single( ply, "TeleportSpec", Config.Prefix.Command )
			end
			
			if #args == 0 or (args[1] and args[1] == "") then
				Message:Single( ply, "TeleportTarget", Config.Prefix.Command )
			else			
				local tply = nil
				if tonumber( args[1] ) then
					for _, p in pairs( player.GetAll() ) do
						if tostring( p:UniqueID() ) == tostring( args[1] ) then
							tply = p
							break
						end
					end
				else
					for _, p in pairs( player.GetAll() ) do
						if string.find( string.lower( p:Name() ), string.lower( args[1] ), 1, true ) then
							tply = p
							break
						end
					end
				end
				
				if tply and IsValid( tply ) then
					if ply == tply then
						Message:Single( ply, "TeleportSelf", Config.Prefix.Command )
					elseif tply.Spectating then
						Message:Single( ply, "TeleportInSpec", Config.Prefix.Command )
					else
						ply:SetPos( tply:GetPos() )
						Message:Single( ply, "TeleportSuccess", Config.Prefix.Command, { tply:Name() } )
					end
				else
					Message:Single( ply, "TeleportTarget", Config.Prefix.Command )
				end
			end
		else
			Message:Single( ply, "TeleportAccess", Config.Prefix.Command )
		end
	end )
	
	self:Register( { "specgo", "spectele", "spectp" }, function( ply )
		if ply.Mode == Config.Modes["Practice"] then
			if not ply.Spectating or not IsValid( ply:GetObserverTarget() ) then
				return Message:Single( ply, "SpecGotoLimit", Config.Prefix.Command )
			end
			
			local ob = ply:GetObserverTarget()
			Command.Spectate( ply, nil, { nil, ob:GetPos(), ob:Name() }, "custom", true )
		else
			Message:Single( ply, "TeleportAccess", Config.Prefix.Command )
		end
	end )
	
	self:Register( { "end", "toend", "goend" }, function( ply )
		if ply.Mode == Config.Modes["Practice"] then
			if IsValid( Map.Timer.End ) then
				ply:SetPos( Map.Timer.End:GetPos() )
				Message:Single( ply, "Generic", Config.Prefix.Command, { "You have been teleported to the end zone!" } )
			else
				Message:Single( ply, "Generic", Config.Prefix.Command, { "No end zone was set for this map." } )
			end
		else
			Message:Single( ply, "TeleportAccess", Config.Prefix.Command )
		end
	end )
	
	-- Map / Vote Commands
	self:Register( { "rtv", "vote", "votechange" }, function( ply, args )
		if #args > 0 then
			if args[1] == "who" then
				RTV:Who( ply )
			elseif args[1] == "check" then
				RTV:Check( ply )
			end
		else
			RTV:Vote( ply )
		end
	end )
	
	self:Register( "revoke", function( ply )
		RTV:Revoke( ply )
	end )
	
	self:Register( "timeleft", function( ply )
		Message:Single( ply, "TimeLeft", Config.Prefix.Game, { Timer:Convert( RTV.MapEnd - CurTime() ) } )
	end )
	
	self:Register( { "playtime", "onlinetime", "doihavealife" }, function( ply )
		local nTime = Player:GetProfileParam( ply, "ConnectionTime", 0 )
		Message:Single( ply, "Generic", Config.Prefix.Command, { "You have played for: " .. Timer:LongConvert( nTime or 0 ) } )
	end )

	-- Bot Commands
	self:Register( "bot", function( ply, args )
		if #args > 0 then
			if args[1] == "record" then
				Bot:RecordStart( ply )
			elseif args[1] == "stop" then
				Bot:RecordStop( ply )
			elseif args[1] == "who" then
				Bot:RecordList( ply )
			else
				Message:Single( ply, "InvalidCommand", Config.Prefix.Command, { args.Key .. " " .. args[1] } )
			end
		else
			Message:Single( ply, "BotStatus", Config.Prefix.Bot, { Bot:IsRecorded( ply ) and "Recorded" or "Not recorded" } )
		end
	end )
	
	-- Window Commands
	self:Register( { "wr", "records" }, function( ply, args )
		if #args > 0 then
			local ModeID, entered = Config.Modes["Auto"], string.lower( tostring( args[1] ) )
			for name, id in pairs( Config.Modes ) do
				if string.find( string.lower( name ), entered ) then
					ModeID = id
					break
				end
			end
			
			if ModeID == Config.Modes["Practice"] then
				return Message:Single( ply, "Generic", Config.Prefix.Command, { "There are no records for the Practice mode." } )
			end
			
			Records:OpenWindow( ply, ModeID )
		else
			Records:OpenWindow( ply, ply.Mode or Config.Modes["Auto"] )
		end
	end )
	
	self:Register( "nominate", function( ply, args )
		if #args > 0 then
			Command.Nominate( ply, nil, { args[1] } )
		else
			ply:SendLua( "Window:Open('Nominate')" )
		end
	end )
	
	self:Register( { "mode", "style", "modes", "styles" }, function( ply, args )
		if #args > 0 then
			local ModeID, entered = Config.Modes["Auto"], string.lower( tostring( args[1] ) )
			for name, id in pairs( Config.Modes ) do
				if string.find( string.lower( name ), entered ) then
					ModeID = id break
				end
			end
			
			Command.Mode( ply, nil, { ModeID } )
		else
			ply:SendLua( "Window:Open('Style')" )
		end
	end )
	
	self:Register( "admin", Admin.CommandProcess )
	self:Register( "radio", Radio.CommandProcess )
	

	self:Register( "invalid", function( ply, args )
		Message:Single( ply, "InvalidCommand", Config.Prefix.Command, { args.Key } )
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
	local szFunc = nil
	local mainCommand, commandArgs = szCommand, {}
	
	if string.find( szCommand, " ", 1, true ) then
		local splitData = string.Explode( " ", szCommand )
		mainCommand = splitData[1]

		for i = 2, #splitData do
			table.insert( commandArgs, splitData[ i ] )
		end
	end
	
	for _, data in pairs( Command.Functions ) do
		for __, alias in pairs( data[1] ) do
			if mainCommand == alias then
				szFunc = data[1][1]
				break
			end
		end
	end

	if not szFunc then szFunc = "invalid" end
	commandArgs.Key = mainCommand

	local varFunc = Command.Functions[ szFunc ]
	if varFunc then
		varFunc = varFunc[2]
		return varFunc( ply, commandArgs )
	end
	
	return nil
end


function Command:Possible( ply )
	if not ply.CommandTimer then
		ply.CommandTimer = CurTime()
	else
		if CurTime() - ply.CommandTimer < Command.TimeLimit then
			Message:Single( ply, "CommandTimer", Config.Prefix.Command, { math.ceil( Command.TimeLimit - (CurTime() - ply.CommandTimer) ) } )
			ply.CommandTimer = ply.CommandTimer + 0.2
			return false
		end
		ply.CommandTimer = CurTime()
	end
	
	return true
end

function Command.Restart( ply )
	if ply:Team() != TEAM_SPECTATOR then
		local szWeapon = Config.Player.DefaultWeapon
		if IsValid( ply:GetActiveWeapon() ) then
			szWeapon = ply:GetActiveWeapon():GetClass() or Config.Player.DefaultWeapon
		elseif not ply.Spectating then
			szWeapon = nil
		end

		ply:KillSilent()
		ply:Spawn()
		
		if ply.Mode == Config.Modes["Bonus"] then
			ply:BonusReset()
		else
			ply:ResetTimer()
		end
		
		if szWeapon then
			ply:SelectWeapon( szWeapon )
		else
			ply:StripWeapons()
		end
		
		ply:SetInSpawn( true, false )
	else
		Message:Single( ply, "SpectateRestart", Config.Prefix.Command )
	end
end

function Command.Spectate( ply, _, varArgs, szFull, bServer )
	if ply.Spectating and varArgs and varArgs[1] then
		return Spectator:NewById( ply, varArgs[1] )
	elseif ply.Spectating then
		local target = ply:GetObserverTarget()
		ply:SetTeam( TEAM_HOP )
		Command.Restart( ply )
		ply.Spectating = false
		ply:SetNWInt( "Spectating", 0 )
		ply:SendLua( "Spectator:Clear()" )
		Spectator:End( ply, target )
		
		if varArgs and varArgs[2] and varArgs[3] and ply.Mode == Config.Modes["Practice"] and szFull == "custom" and bServer then
			ply:SetPos( varArgs[2] )
			Message:Single( ply, "SpecTeleport", Config.Prefix.Command, { varArgs[3] } )
		end
	else
		ply:SetNWInt( "Spectating", 1 )
		ply:SendLua( "Spectator:Clear()" )
		ply.Spectating = true
		ply:KillSilent()
		ply:ResetTimer()
		GAMEMODE:PlayerSpawnAsSpectator( ply )
		ply:SetTeam( TEAM_SPECTATOR )
		if ply.InSpawn then ply.InSpawn = false end
		
		if varArgs and varArgs[1] then
			return Spectator:NewById( ply, varArgs[1] )
		end
		
		Spectator:New( ply )
	end
end

function Command.Mode( ply, _, varArgs )
	if not Command:Possible( ply ) then return end
	if not varArgs[1] or not tonumber( varArgs[1] ) then return end
	if tonumber( varArgs[1] ) == ply.Mode then return Message:Single( ply, "ModeSame", Config.Prefix.Command, { Config.ModeNames[ ply.Mode ] } ) end
	
	local nMode = tonumber( varArgs[1] ) or Config.Modes["Auto"]
	if nMode == Config.Modes["Bonus"] and not Map.Bonus then
		return Message:Single( ply, "MapBonus", Config.Prefix.Command )
	elseif nMode == Config.Modes["Bonus"] then
		ply:ResetTimer()
	elseif ply.Mode == Config.Modes["Bonus"] then
		ply:BonusReset()
	end
	
	ply.Mode = nMode
	Player:LoadMode( ply )
end

function Command.Nominate( ply, _, varArgs )
	if not Command:Possible( ply ) then return end
	if not varArgs[1] then return end
	if not Map.ServerList[ varArgs[1] ] then return end
	if varArgs[1] == game.GetMap() then return end
	
	RTV:Nominate( ply, varArgs[1] )
end

function Command.Vote( ply, _, varArgs )
	if not RTV.VotePossible then return end
	if not varArgs[1] then return end
	if not varArgs[2] then
		local nVote = tonumber( varArgs[1] )
		if not nVote or nVote < 1 or nVote > 6 then return end
		RTV.MapVoteList[ nVote ] = RTV.MapVoteList[ nVote ] + 1
		Data:Global( "VoteData", RTV.MapVoteList )
	else
		local nVote, nPrev = tonumber( varArgs[1] ), tonumber( varArgs[2] )
		if not nVote or not nPrev or nVote < 1 or nVote > 6 or nPrev < 1 or nPrev > 6 then return end
		RTV.MapVoteList[ nVote ] = RTV.MapVoteList[ nVote ] + 1
		RTV.MapVoteList[ nPrev ] = RTV.MapVoteList[ nPrev ] - 1
		if RTV.MapVoteList[ nPrev ] < 0 then RTV.MapVoteList[ nPrev ] = 0 end
		Data:Global( "VoteData", RTV.MapVoteList )
	end
end

function Command.AFK( ply, _, varArgs )
	if not varArgs or not varArgs[1] then return end
	if tostring(varArgs[1]) != Config.Player.Phrase then return end
	if Command.Settings.AFKLimit then
		ply:Kick( "You have been AFK for too long!" )
	end
end

function Command.SVBypass( ply, _, varArgs )
	if not varArgs or not varArgs[1] then return end
	if tostring(varArgs[1]) != Config.Player.Phrase then return end
	if ply.Ban then
		ply:Ban( 1440, "CV Bypass" )
	end
	
	ply:Kick( "You have been banned for bypassing certain values" )
end

function Command.FPSLimit( ply, _, varArgs )
	if not varArgs or not varArgs[1] or not varArgs[2] then return end
	if tostring(varArgs[2]) != Config.Player.Phrase then return end
	if not ply.Spectating or ply:Team() != TEAM_SPECTATOR then
		Message:Single( ply, "Generic", Config.Prefix.Game, { "Your FPS (fps_max) has be set to 300 to play on this server." } )
		Command.Spectate( ply )
	end
end

local LeftKill = {}
function Command.PlusLeft( ply, _, varArgs )
	if not varArgs or #varArgs == 0 then return end
	if not Command.Settings.LeftBlock then return end
	
	local bind = varArgs[1]
	if bind != "+left" and bind != "+right" then return end

	if ply.timer and not ply.timerFinish then
		if not LeftKill[ ply ] then
			ply:SetLocalVelocity( Vector(0, 0, -100) )
			Message:Single( ply, "Generic", Config.Prefix.Timer, { "If you use " .. bind .. " again, your timer will be stopped." } )
			LeftKill[ ply ] = true
		else
			ply:ResetTimer()
			Message:Single( ply, "LeftBlock", Config.Prefix.Timer, { bind } )
			LeftKill[ ply ] = nil
		end
	end
	
	ply:SendLua( "Client.LeftSet = nil" )
end

function Command.NoClip( ply, _, varArgs )
	if ply.Mode == Config.Modes["Practice"] then
		if ply:GetMoveType() != MOVETYPE_NOCLIP then
			ply:SetMoveType( MOVETYPE_NOCLIP )
			ply:StripWeapons()
		else
			ply:SetMoveType( MOVETYPE_WALK )
		end
	else
		Message:Single( ply, "NoclipLimit", Config.Prefix.Command )
	end
end

function Command.GetWRInfo( ply, _, varArgs )
	if not Command:Possible( ply ) then return end
	if not varArgs or #varArgs != 2 then return end
	if not tonumber( varArgs[1] ) or not tonumber( varArgs[2] ) then return end
	local nMode, nID = tonumber( varArgs[1] ), tonumber( varArgs[2] )
	
	if nID == 16 then
		Records:OpenWindow( ply, nMode, true )
		return
	end
	
	local ModeCache = Records:GetCache( nMode )
	
	if not ModeCache or not ModeCache[ nID ] then
		return Message:Single( ply, "Generic", Config.Prefix.Command, { "No WRs found for this mode or ID" } )
	end
	
	local DataCache = ModeCache[ nID ]
	local DataString = "[" .. Config.ModeNames[ DataCache.Mode ] .. "] #" .. nID .. "/" .. #ModeCache .. " - Record by " .. DataCache.Name .. ": " .. Timer:Convert( DataCache.Time )
	local DataExtra = {}
	
	if DataCache.Date then table.insert( DataExtra, "Date obtained: " .. DataCache.Date ) end
	if DataCache.Jumps then table.insert( DataExtra, "Jumps: " .. DataCache.Jumps ) end
	if DataCache.Position then table.insert( DataExtra, "Original position: " .. DataCache.Position ) end
	
	if #DataExtra > 0 then
		DataString = DataString .. " - Additional data ["
		DataString = DataString .. string.Implode( ", ", DataExtra )
		DataString = DataString .. "]"
	end
	
	Message:Single( ply, "Generic", Config.Prefix.Timer, { DataString } )
end

function Command.RequestMaps( ply )
	if not IsValid( ply ) then return end
	
	Map:Send( ply )
end

function Command.ServerCommand( ply, szCmd )
	local bConsole = false
	if not IsValid( ply ) and not ply.Name and not ply.Team then
		bConsole = true
	end
	if not bConsole then return end
	
	if szCmd == "finalize" then
		FS:Finalize()
	elseif szCmd == "stop" then
		FS:Finalize()
		RunConsoleCommand( "exit" )
	elseif szCmd == "totalpoints" then
		local nPoints = 0
		
		for _, data in pairs( Map.ServerMaps ) do
			nPoints = nPoints + data[2]
		end
		
		print("Points of all " .. #Map.ServerMaps .. " maps: " .. nPoints)
	end
end

concommand.Add( "respawn", Command.Restart )
concommand.Add( "spectate", Command.Spectate )
concommand.Add( "mode", Command.Mode )
concommand.Add( "nominate", Command.Nominate )
concommand.Add( "vote", Command.Vote )
concommand.Add( "afk", Command.AFK )
concommand.Add( "svbypass", Command.SVBypass )
concommand.Add( "leftblock", Command.PlusLeft )
concommand.Add( "requestmaps", Command.RequestMaps )
concommand.Add( "pnoclip", Command.NoClip )
concommand.Add( "fpslimit", Command.FPSLimit )
concommand.Add( "getwrinfo", Command.GetWRInfo )

concommand.Add( "finalize", Command.ServerCommand )
concommand.Add( "stop", Command.ServerCommand )
concommand.Add( "totalpoints", Command.ServerCommand )