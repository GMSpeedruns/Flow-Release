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
	
end

function GM:ShowTeam( ply )
	ply:SendLua( "Window:Open('Spectate')" )
end

function GM:ShowSpare1( ply )
	if ply.Spectating then return end
	
	ply.ThirdPerson = 1 - ply.ThirdPerson
	ply:SendLua( "Client.ThirdPerson = " .. ply.ThirdPerson )
end


Command = {}
Command.Functions = {}
Command.TimeLimit = 2

function Command:Init()
	-- Main Commands
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
	
	--[[ self:Register( { "help", "commands" }, function( ply, args )
		local szID = args[1] or "Base"
		ply:SendLua( "Client:ShowHelp('" .. tostring( args[1] or "Base" ) .. "')" )
	end ) ]]
	
	self:Register( { "remove", "stripweapons" }, function( ply )
		ply:StripWeapons()
		Message:Single( ply, "GunStrip", Config.Prefix.Game )
	end )
	
	self:Register( { "ranks", "rank" }, function( ply )
		ply:SendLua( "Client:ShowRanks(" .. Player:GetProfileParam( ply, "Rank", 1 ) .. "," .. Player:GetProfileParam( ply, "Points", 0 ) .. ")" )
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
	
	self:Register( { "glock", "usp", "knife" }, function( ply, args )
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
	
	-- Mode Commands
	self:Register( { "auto", "a" }, function( ply ) Command.Mode( ply, nil, { Config.Modes["Auto"] } ) end )
	self:Register( { "sideways", "sw", "s" }, function( ply ) Command.Mode( ply, nil, { Config.Modes["Sideways"] } ) end )
	self:Register( { "wonly", "w-only", "w" }, function( ply ) Command.Mode( ply, nil, { Config.Modes["W-Only"] } ) end )
	self:Register( { "normal", "legit", "scroll", "n" }, function( ply ) Command.Mode( ply, nil, { Config.Modes["Scroll"] } ) end )
	self:Register( { "practice", "p" }, function( ply ) Command.Mode( ply, nil, { Config.Modes["Practice"] } ) end )
	self:Register( { "bonus", "b" }, function( ply ) Command.Mode( ply, nil, { Config.Modes["Bonus"] } ) end )
	
	self:Register( { "noclip", "clip", "pnoclip", "roam" }, function( ply )
		Command.NoClip( ply )
	end )
	
	-- Map / Vote Commands
	self:Register( { "rtv", "vote", "votechange" }, function( ply )
		RTV:Vote( ply )
	end )
	
	self:Register( "revoke", function( ply )
		RTV:Revoke( ply )
	end )
	
	self:Register( "timeleft", function( ply )
		Message:Single( ply, "TimeLeft", Config.Prefix.Game, { Timer:Convert( RTV.MapEnd - CurTime() ) } )
	end )
	
	-- Bot Commands
	self:Register( "bot", function( ply, args )
		if #args > 0 then
			if args[1] == "record" then
				Bot:Record( ply )
			elseif args[1] == "stop" then
				Bot:Record( ply, true )
			end
		else
			Message:Single( ply, "BotStatus", Config.Prefix.Bot, { ply.BotRecord and "Recorded" or "Not recorded" } )
		end
	end )
	
	-- Window Commands
	self:Register( { "wr", "record" }, function( ply, args )
		if #args > 0 then
			local ModeID, entered = Config.Modes["Auto"], string.lower( tostring( args[1] ) )
			for name, id in pairs( Config.Modes ) do
				if string.find( string.lower( name ), entered ) then
					ModeID = id break
				end
			end
		
			ply:SendLua( "Window:Open('WR', " .. ModeID .. ")" )
		else
			ply:SendLua( "Window:Open('WR')" )
		end
	end )
	
	self:Register( "nominate", function( ply, args )
		if #args > 0 then
			Command.Nominate( ply, nil, { args[1] } )
		else
			ply:SendLua( "Window:Open('Nominate')" )
		end
	end )
	
	self:Register( { "mode", "style" }, function( ply, args )
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
	
	self:Register( "admin", function( ply, args )
		if not Admin.CommandAccess[ ply:UniqueID() ] then
			return Message:Single( ply, "InvalidCommand", Config.Prefix.Command, { args.Key } )
		end
		
		if #args == 0 then return end
		local szID = args[1]
		
		if szID == "addarea" then
			if not args[2] or not tonumber( args[2] ) then
				if not ply.AreaEditor then
					for name, id in pairs( Config.Area ) do
						Message:Single( ply, "Generic", Config.Prefix.Admin, { "Area " .. name .. " - ID: " .. id } )
					end
					return Message:Single( ply, "Generic", Config.Prefix.Admin, { "Usage: !admin addarea <id>" } )
				else
					return Admin:ProcessArea( ply )
				end
			end
			
			Admin:AddArea( ply, tonumber( args[2] ) )
		elseif szID == "addtrigger" then
			if not args[2] or not tonumber( args[2] ) then
				for name, id in pairs( Map.Specials ) do
					Message:Single( ply, "Generic", Config.Prefix.Admin, { "Special " .. name .. " - ID: " .. id } )
				end
				return Message:Single( ply, "Generic", Config.Prefix.Admin, { "Usage: !admin addarea <id>" } )
			end
			
			Admin:AddTrigger( ply, tonumber( args[2] ), args[3] )
		elseif szID == "delarea" then
			if not args[2] or not tonumber( args[2] ) then
				for EntID, data in pairs ( Map.Entities ) do
					Message:Single( ply, "Generic", Config.Prefix.Admin, { "Entity [" .. EntID + 2 .. "]: " .. data.areatype } )
				end
				return
			end
			
			Admin:DelArea( ply, tonumber( args[2] ) )
		elseif szID == "stoparea" then
			Admin:StopArea( ply )
		elseif szID == "setpoints" then
			if not args[2] or not tonumber( args[2] ) then
				return Message:Single( ply, "Generic", Config.Prefix.Admin, { "Usage: !admin setpoints <points>" } )
			end
			
			local tabCurrent = Map.ServerList[ game.GetMap() ] or Map.Default
			tabCurrent.Points = tonumber( args[2] )
			FS:Write( "data_" .. game.GetMap() .. ".txt", FS.Folders.Maps, FS.Serialize:MapData( tabCurrent ) )
			
			-- To-Do: Reload everyone's points that has beaten this map
			
			Message:Single( ply, "Generic", Config.Prefix.Admin, { "Points updated! Be sure to re-cache maps!" } )
		elseif szID == "precord" then
			for _, p in pairs( player.GetHumans() ) do
				if tostring( p:UniqueID() ) == tostring( args[2] ) then
					local nCurrent = Player:GetProfileParam( p, "BotRecord", 0 )
					local nNew = 1 - nCurrent
					Player:SetProfileParam( p, "BotRecord", nNew )
					Message:Single( ply, "Generic", Config.Prefix.Admin, { p:Name() .. "'s bot record status is now set to: " .. nNew } )
					break
				end
			end
		elseif szID == "height" then
			if not args[2] or not tonumber( args[2] ) then return end
			if not args[3] or not tonumber( args[3] ) then return end
			if tonumber( args[2] ) == 1 then
				Admin:SetHeight( ply, 1, tonumber( args[3] ) )
			elseif tonumber( args[2] ) == 2 then
				Admin:SetHeight( ply, 2, tonumber( args[3] ) )
			end
		elseif szID == "reloadareas" then
			Map:CreateTimers( true )
			Map:CreateTriggers()
			Message:Single( ply, "Generic", Config.Prefix.Admin, { "Map areas have been reloaded!" } )
		elseif szID == "recache" then
			Map:Init()
			Message:Single( ply, "Generic", Config.Prefix.Admin, { "Map data has been re-cached!" } )
		elseif szID == "change" then
			timer.Simple( 3, function() RunConsoleCommand( "changelevel", args[2] ) end )
			Message:Single( ply, "Generic", Config.Prefix.Admin, { "Map changing to " .. args[2] } )
		end
	end )
	

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
		mainCommand = splitData[ 1 ]

		for i = 2, #splitData do
			table.insert( commandArgs, splitData[ i ] )
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

	local varFunc = Command.Functions[ szFunc ][ 2 ]
	return varFunc( ply, commandArgs )
end


function Command:Possible( ply )
	if not ply.CommandTimer then
		ply.CommandTimer = CurTime()
	else
		if CurTime() - ply.CommandTimer < Command.TimeLimit then
			Message:Single( ply, "CommandTimer", Config.Prefix.Command, { math.ceil( Command.TimeLimit - (CurTime() - ply.CommandTimer) ) } )
			ply.CommandTimer = ply.CommandTimer + 1
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
	else
		Message:Single( ply, "SpectateRestart", Config.Prefix.Command )
	end
end

function Command.Spectate( ply, _, varArgs )
	if not Command:Possible( ply ) then return end
	if ply.Spectating and varArgs and varArgs[1] then
		return Spectator:NewById( ply, varArgs[1] )
	elseif ply.Spectating then
		local target = ply:GetObserverTarget()
		ply:SetTeam( TEAM_HOP )
		Command.Restart( ply )
		ply.Spectating = false
		ply:SetNWInt( "Spectating", 0 )
		Spectator:End( ply, target )
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

function Command.AFK( ply )
	ply:Kick( "You have been AFK for too long!" )
end

function Command.PlusLeft( ply, _, varArgs )
	--return
	
	--[[if not varArgs or #varArgs == 0 then return end
	local bind = varArgs[1]
	if bind != "+left" and bind != "+right" then return end
	if ply.Mode != Config.Modes["Auto"] and ply.Mode != Config.Modes["Scroll"] then return end

	if ply.timer and not ply.timerFinish then
		ply:ResetTimer()
		Message:Single( ply, "LeftBlock", Config.Prefix.Timer, { bind } )
	end
	
	ply:SendLua( "Client.LeftSet = nil" )]]
end

function Command.NoClip( ply, _, varArgs )
	if ply.Mode == Config.Modes["Practice"] then
		if ply:GetMoveType() != MOVETYPE_NOCLIP then
			ply:SetMoveType( MOVETYPE_NOCLIP )
		else
			ply:SetMoveType( MOVETYPE_WALK )
		end
	else
		Message:Single( ply, "NoclipLimit", Config.Prefix.Command )
	end
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
concommand.Add( "leftblock", Command.PlusLeft )
concommand.Add( "requestmaps", Command.RequestMaps )
concommand.Add( "pnoclip", Command.NoClip )

concommand.Add( "finalize", Command.ServerCommand )
concommand.Add( "stop", Command.ServerCommand )
concommand.Add( "totalpoints", Command.ServerCommand )