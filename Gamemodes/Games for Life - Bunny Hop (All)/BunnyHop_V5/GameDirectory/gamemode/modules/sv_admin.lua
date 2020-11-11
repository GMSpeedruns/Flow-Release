Admin = {}
Admin.Protocol = "Admin"

Admin.Access = {
	None = 0,		-- 00000
	Base = 1,		-- 00001
	Bonus = 2,		-- 00010
	Area = 4,		-- 00100
	Trigger = 8,	-- 01000
	Owner = 16		-- 10000
}

Admin.List = {}

Admin.Functions = {
	{ Admin.Access.Bonus, "Cancel Zone Set", 14 },

	{ Admin.Access.Bonus, "Set Bonus Start", 10 },
	{ Admin.Access.Bonus, "Remove Bonus Start", 11 },
	{ Admin.Access.Bonus, "Set Bonus End", 12 },
	{ Admin.Access.Bonus, "Remove Bonus End", 13 },
	
	{ Admin.Access.Area, "Set Start", 20 },
	{ Admin.Access.Area, "Remove Start", 21 },
	{ Admin.Access.Area, "Set End", 22 },
	{ Admin.Access.Area, "Remove End", 23 },
}

util.AddNetworkString( Admin.Protocol )


function Admin:Init()
	Admin:LoadAdmins()
end

function Admin:LoadAdmins()
	local Content = FS:Load( "AdminList.txt", FS.Folders.Players, true )
	if Content and Content != "" then
		local Admins = string.Explode( "\n", Content )
		for _, data in pairs( Admins ) do
			local tab = FS.Deserialize:AdminInfo( data )
			Admin.List[ tab.UID ] = tab.Access
		end
	end
end

function Admin:GetAdmin( ply )
	return Admin.List[ ply:UniqueID() ]
end

function Admin:SetAdmin( ply, varAccess )
	Admin.List[ ply:UniqueID() ] = varAccess
	Admin:SaveAdmins()
end

function Admin:SaveAdmins()
	local tabList = {}
	
	for uid, access in pairs( Admin.List ) do
		table.insert( tabList, FS.Serialize:AdminInfo( { UID = uid, Access = access } ) )
	end
	
	local szData = string.Implode( "\n", tabList )
	FS:Write( "AdminList.txt", FS.Folders.Players, szData )
end

function Admin:CanAccess( ply, nLevel, nAccess )
	local nAccess = nAccess or Admin:GetAdmin( ply )
	if nAccess then
		--return bit.band( nLevel, Admin.List[ ply:UniqueID() ] ) > 0
		return nAccess >= nLevel
	end
	
	return false
end

function Admin:GetFunctions( ply )
	local varConstruct = nil

	local nAccess = Admin:GetAdmin( ply )
	if nAccess then
		varConstruct = {}
		for _, data in pairs( Admin.Functions ) do
			if Admin:CanAccess( ply, data[1], nAccess ) then
				table.insert( varConstruct, data )
			end
		end
		if #varConstruct == 0 then
			varConstruct = nil
		end
	end
	
	return varConstruct
end

-- Network
function Admin:Send( ply, szIdentifier, varArgs )
	net.Start( Admin.Protocol )
	net.WriteString( szIdentifier )
	
	if varArgs and type( varArgs ) == "table" and #varArgs > 0 then
		net.WriteBit( true )
		net.WriteTable( varArgs )
	else
		net.WriteBit( false )
	end
	
	net.Send( ply )
end


-- Commands
function Admin.CommandProcess( ply, args )
	if not Admin:CanAccess( ply, Admin.Access.Base ) then
		return Message:Single( ply, "InvalidCommand", Config.Prefix.Command, { args.Key } )
	end
	
	if #args == 0 then
		ply:SendLua( "Admin:SetAL(" .. Admin:GetAdmin( ply ) .. ")" )
		Admin:Send( ply, "Open", Admin:GetFunctions( ply ) )
	else
		local szID = args[1]
		if not Admin:CanAccess( ply, Admin.Access.Owner ) then
			return Message:Single( ply, "InvalidCommand", Config.Prefix.Command, { args.Key .. " " .. szID } )
		end

		if szID == "help" then
			Message:Single( ply, "Generic", Config.Prefix.Admin, { "Possible commands: " .. "help, addarea [id], addtrigger [id], delarea [id], stoparea, setpoints [points], precord [uid], height [id] [height], reloadareas, recache, change [map], time [uid] [seconds], bonusangles, listbots [strarg], removebot [mode] [confirm], getbotframe [mode], setbotframe [mode] [frame], gettimes, removetime [todo]" } )
		elseif szID == "addarea" then
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
				return Message:Single( ply, "Generic", Config.Prefix.Admin, { "Usage: !admin addtrigger <id>" } )
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
		elseif szID == "time" then
			if not args[2] or not tonumber( args[2] ) then return end
			if not args[3] or not tonumber( args[3] ) then return end
			for _,p in pairs( player.GetAll() ) do
				if tostring( p:UniqueID() ) == tostring( args[2] ) then
					Bot:RecordStop( p )
					p.timer = CurTime() - tonumber( args[3] )
					p:SendLua( "Timer:Start(" .. p.timer .. ")" )
				end
			end
		elseif szID == "bonusangles" then
			Admin:SetBonusAngles( ply )
		elseif szID == "listbots" then
			if args[2] and args[2] == "all" then
				-- To-Do
			else
				local list = Bot:GetInfo() or {}
				for mode, info in pairs( list ) do
					local szData = ""
					for name, item in pairs( info ) do
						szData = szData .. "(" .. name .. "): " .. item .. ", "
					end
					Message:Single( ply, "Generic", Config.Prefix.Admin, { "[Bot info - " .. Config.ModeNames[ mode ] .. "] " .. szData } )
				end
			end
		elseif szID == "removebot" then
			if args[3] and args[3] == "sure" and args[2] and tonumber( args[2] ) then
				local nMode = tonumber( args[2] )
				local Rem = Bot:RemoveBot( nMode )
				local szRem = "Run: " .. tostring( Rem[1] ) .. ", Info: " .. tostring( Rem[2] ) .. ", Bot: " .. tostring( Rem[3] )
				Message:Single( ply, "Generic", Config.Prefix.Admin, { "The " .. Config.ModeNames[ nMode ] .. " bot has been deleted - Result: " .. szRem } )
			elseif args[2] and tonumber( args[2] ) then
				local nMode = tonumber( args[2] )
				Message:Single( ply, "Generic", Config.Prefix.Admin, { "If you are sure you want to delete the " .. Config.ModeNames[ nMode ] .. " bot, type !admin removebot " .. nMode .. " sure."} )
			end
		elseif szID == "getbotframe" then
			if args[2] and tonumber( args[2] ) then
				local nFrames = Bot:GetFramePosition( tonumber( args[2] ) )
				Message:Single( ply, "Generic", Config.Prefix.Admin, { "The " .. Config.ModeNames[ tonumber( args[2] ) ] .. " bot is now at frame " .. nFrames[1] .. " / " .. nFrames[2] } )
			end
		elseif szID == "setbotframe" then
			if args[2] and tonumber( args[2] ) and args[3] and tonumber( args[3] ) then
				Bot:SetFramePosition( tonumber( args[2] ), tonumber( args[3] ) )
				Message:Single( ply, "Generic", Config.Prefix.Admin, { "The " .. Config.ModeNames[ tonumber( args[2] ) ] .. " bot has been set to frame " .. args[3] } )
			else
				Message:Single( ply, "Generic", Config.Prefix.Admin, { "Usage: !admin setbotframe [mode] [frame]" } )
			end
		elseif szID == "gettimes" then
			local result = {}
			for i = Config.Modes["Auto"], Config.Modes["Bonus"] do
				local list = Records:GetCache( i ) or "No records found"
				result[ i ] = Config.ModeNames[ i ]
				result[ Config.ModeNames[ i ] ] = list
			end
			Admin:Send( ply, "TimeList", result )
		elseif szID == "removetime" then
			
		else
			Message:Single( ply, "Generic", Config.Prefix.Admin, { szID .. " is not a registered admin command! Type !admin help for a list of commands." } )
		end
	end
end

function Admin.ReceiveCommand( ply, _, args )
	if not args[1] or not tonumber( args[1] ) then return end
	local bAccess, varData, nID = false, nil
	
	for _id, data in pairs( Admin.Functions ) do
		if data[3] == tonumber( args[1] ) then
			varData = data
			break
		end
	end
	
	if varData and varData[1] and tonumber( varData[1] ) then
		bAccess = Admin:CanAccess( ply, varData[1] )
	end
	
	if not bAccess or not varData then
		return Message:Single( ply, "InvalidCommand", Config.Prefix.Command, { "admincmd" } )
	end
	
	Admin:ProcessCommand( ply, varData[3] )
end
concommand.Add( "admincmd", Admin.ReceiveCommand )

function Admin:ProcessCommand( ply, nID )
	if not nID then return end
	
	if nID == 10 then
		local bPresent, varEnt = false, nil
		for _, data in pairs( Map.Entities ) do
			if data.areatype == Config.Area.BonusA then
				bPresent = true
				varEnt = data
				break
			end
		end
		
		if bPresent then
			local szData = FS:Load( "triggers_" .. game.GetMap() .. ".txt", FS.Folders.Maps )
			if szData and szData != "" then
				local szLines = string.Explode( "\n", szData )
				local nRem = nil

				for _id,line in pairs( szLines ) do
					local tab = FS.Deserialize:TriggerInfo( line )
					if tab.ID == varEnt.areatype then
						nRem = _id
						break
					end
				end
				
				if nRem then
					table.remove( szLines, nRem )
					if #szLines > 0 then
						local szNew = string.Implode( "\n", szLines )
						FS:Write( "triggers_" .. game.GetMap() .. ".txt", FS.Folders.Maps, szNew )
					else
						FS:Write( "triggers_" .. game.GetMap() .. ".txt", FS.Folders.Maps, "" )
					end
					
					Admin:ReloadEnts( bFull )
				else
					return Message:Single( ply, "Generic", Config.Prefix.Admin, { "An error occurred while removing the current bonus area!" } )
				end
			end
		end
	
		if not ply.AreaEditor then
			Admin:AddArea( ply, 10 )
			Message:Single( ply, "Generic", Config.Prefix.Admin, { "You are now setting the bonus start zone! Move around! Press button again to complete." } )
		else
			Admin:ProcessArea( ply )
		end
	elseif nID == 14 then
		if ply.AreaEditor then
			Admin:StopArea( ply )
			Message:Single( ply, "Generic", Config.Prefix.Admin, { "Area editing has been stopped!" } )
		else
			Message:Single( ply, "Generic", Config.Prefix.Admin, { "You are currently not setting an area!" } )
		end
	end
end


function Admin:ReloadEnts( bFull, ply )
	if bFull then
		Map:Init()
	end
	
	Map:CreateTimers( true )
	Map:CreateTriggers()
	
	if ply then
		Message:Single( ply, "Generic", Config.Prefix.Admin, { "Areas have been " .. (bFull and "recached and ") .. "reloaded" } )
	end
end

function Admin:AddArea( ply, nID )
	ply.AreaEditor = {
		Open = true,
		Start = ply:GetPos(),
		Type = nID
	}
	
	local s = ply.AreaEditor.Start
	local x,y,z = s.x, s.y, s.z
	ply:SendLua( "Admin:AreaEdit(" .. nID .. ",Vector(" .. x .. "," .. y .. "," .. z .. "))" )
end

function Admin:DelArea( ply, nID )
	if nID == 1 or nID == 2 then
		local tabCurrent = Map.ServerList[ game.GetMap() ] or Map.Default
		if nID == 1 then
			tabCurrent.StartA = Vector(0, 0, 0)
			tabCurrent.StartB = Vector(0, 0, 0)
		elseif nID == 2 then
			tabCurrent.EndA = Vector(0, 0, 0)
			tabCurrent.EndB = Vector(0, 0, 0)
		end
		
		FS:Write( "data_" .. game.GetMap() .. ".txt", FS.Folders.Maps, FS.Serialize:MapData( tabCurrent ) )
		Message:Single( ply, "Generic", Config.Prefix.Admin, { "Start area has been updated!" } )
		Admin:ReloadEnts( true, ply )
	else
		local fData = nil
		nID = nID - 2
		for EntID, data in pairs( Map.Entities ) do
			if EntID == nID then
				fData = data
				Message:Single( ply, "Generic", Config.Prefix.Admin, { "Entity [" .. EntID .. "]: " .. data.areatype .. " - " .. GetVectorString( data.min, true ) } )
				data.EntID = EntID
			end
		end
		
		if fData then
			local szData = FS:Load( "triggers_" .. game.GetMap() .. ".txt", FS.Folders.Maps )
			if not szData or szData == "" then return end
			local szLines = string.Explode( "\n", szData )
			local nRem = nil

			for _,line in pairs( szLines ) do
				local tab = FS.Deserialize:TriggerInfo( line )
				if tab.ID == fData.areatype and string.find(string.lower(tab.Data), string.lower(GetVectorString(fData.min, true)), 1, true) then
					nRem = _
					break
				end
			end
			
			if nRem then
				Map.Entities[ fData.EntID ]:Remove()
				Map.Entities[ fData.EntID ] = nil
				
				table.remove( szLines, nRem )
				if #szLines > 0 then
					local szNew = string.Implode( "\n", szLines )
					FS:Write( "triggers_" .. game.GetMap() .. ".txt", FS.Folders.Maps, szNew )
				else
					FS:Write( "triggers_" .. game.GetMap() .. ".txt", FS.Folders.Maps, "" )
				end
				
				Message:Single( ply, "Generic", Config.Prefix.Admin, { "Triggers have been updated!" } )
				Admin:ReloadEnts( true, ply )
			end
		else
			Message:Single( ply, "Generic", Config.Prefix.Admin, { "Couldn't remove trigger!" } )
		end
	end
end

function Admin:StopArea( ply )
	ply.AreaEditor = nil
	ply:SendLua( "Admin:AreaStop()" )
end

function Admin:ProcessArea( ply )
	ply.AreaEditor.End = ply:GetPos()

	local Start, End = ply.AreaEditor.Start, ply.AreaEditor.End
	local Min = Vector(math.min(Start.x, End.x), math.min(Start.y, End.y), math.min(Start.z, End.z))
	local Max = Vector(math.max(Start.x, End.x), math.max(Start.y, End.y), math.max(Start.z + 128, End.z + 128))
	
	if ply.AreaEditor.Type == Config.Area.Start then
		local tabCurrent = Map.ServerList[ game.GetMap() ] or Map.Default
		tabCurrent.StartA = Min
		tabCurrent.StartB = Max
		FS:Write( "data_" .. game.GetMap() .. ".txt", FS.Folders.Maps, FS.Serialize:MapData( tabCurrent ) )
		Message:Single( ply, "Generic", Config.Prefix.Admin, { "Start area has been updated!" } )
		Command:Trigger( ply, "admin recache", "!admin recache" )
		Command:Trigger( ply, "admin reloadareas", "!admin reloadareas" )
	elseif ply.AreaEditor.Type == Config.Area.Finish then
		local tabCurrent = Map.ServerList[ game.GetMap() ] or Map.Default
		tabCurrent.EndA = Min
		tabCurrent.EndB = Max
		FS:Write( "data_" .. game.GetMap() .. ".txt", FS.Folders.Maps, FS.Serialize:MapData( tabCurrent ) )
		Message:Single( ply, "Generic", Config.Prefix.Admin, { "End area has been updated!" } )
		Admin:ReloadEnts( true, ply )
	elseif ply.AreaEditor.Type == Config.Area.BonusA or ply.AreaEditor.Type == Config.Area.BonusB then
		local szData = FS:Load( "triggers_" .. game.GetMap() .. ".txt", FS.Folders.Maps, true )
		local tabData = { Map = game.GetMap(), ID = ply.AreaEditor.Type, Data = GetVectorString( Min, true) .. ";" .. GetVectorString( Max, true ) }
		local szNew = FS.Serialize:TriggerInfo( tabData )
		if szData == "" then
			szData = szNew
		else
			szData = szData .. "\n" .. szNew
		end
		FS:Write( "triggers_" .. game.GetMap() .. ".txt", FS.Folders.Maps, szData )
		Message:Single( ply, "Generic", Config.Prefix.Admin, { "Bonus area has been updated!" } )
		Admin:ReloadEnts( true )
	elseif ply.AreaEditor.Type == Map.Specials.Freestyle then
		local szData = FS:Load( "triggers_" .. game.GetMap() .. ".txt", FS.Folders.Maps, true )
		local tabData = { Map = game.GetMap(), ID = ply.AreaEditor.Type, Data = GetVectorString( Min, true) .. ";" .. GetVectorString( Max, true ) }
		local szNew = FS.Serialize:TriggerInfo( tabData )
		if szData == "" then
			szData = szNew
		else
			szData = szData .. "\n" .. szNew
		end
		FS:Write( "triggers_" .. game.GetMap() .. ".txt", FS.Folders.Maps, szData )
		Message:Single( ply, "Generic", Config.Prefix.Admin, { "Freestyle area has been updated!" } )
		Admin:ReloadEnts( true, ply )
	else
		Message:Single( ply, "Generic", Config.Prefix.Admin, { "Unknown Area ID: " .. ply.AreaEditor.Type } )
	end
	
	ply.AreaEditor = nil
	ply:SendLua( "Admin:AreaStop()" )
end


function Admin:SetHeight( ply, nID, nHeight )
	local tabCurrent = Map.ServerList[ game.GetMap() ] or Map.Default
	if nID == 1 then
		tabCurrent.StartB = Vector( tabCurrent.StartB.x, tabCurrent.StartB.y, tabCurrent.StartA.z + nHeight )
	elseif nID == 2 then
		tabCurrent.EndB = Vector( tabCurrent.EndB.x, tabCurrent.EndB.y, tabCurrent.EndA.z + nHeight )
	end
	
	FS:Write( "data_" .. game.GetMap() .. ".txt", FS.Folders.Maps, FS.Serialize:MapData( tabCurrent ) )
	Message:Single( ply, "Generic", Config.Prefix.Admin, { "Area [" .. nID .. "] height has been updated" } )
	Admin:ReloadEnts( true, ply )
end

function Admin:AddTrigger( ply, nID, szOption )
--	if nID == Map.Specials.BotOption then

	local szData = FS:Load( "triggers_" .. game.GetMap() .. ".txt", FS.Folders.Maps, true )
	local tabData = { Map = game.GetMap(), ID = nID, Data = szOption }
	local szNew = FS.Serialize:TriggerInfo( tabData )
	if szData == "" then
		szData = szNew
	else
		szData = szData .. "\n" .. szNew
	end
	FS:Write( "triggers_" .. game.GetMap() .. ".txt", FS.Folders.Maps, szData )
	Message:Single( ply, "Generic", Config.Prefix.Admin, { "Trigger has been updated!" } )
	Admin:ReloadEnts( true, ply )
end

function Admin:SetBonusAngles( ply )
	local angles = ply:EyeAngles()
	Admin:AddTrigger( ply, Map.Specials.BonusAngles, angles.p .. ";" .. angles.y )
end