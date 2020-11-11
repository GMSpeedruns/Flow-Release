Admin = {}
Admin.Protocol = "Admin"

Admin.Access = {
	Owner = 3,
	Admin = 2,
	Moderator = 1,
	Default = 0
}
Admin.List = {}

Admin.Functions = {
	{ Admin.Access.Admin, "[Map] Reload", 11 },
	{ Admin.Access.Admin, "[Map] Area Editor", 12 },
	{ Admin.Access.Admin, "[Map] Times", 13 },
	{ Admin.Access.Admin, "[Map] Change", 14 },
	{ Admin.Access.Admin, "[Map] Specials", 15 },
	
	{ Admin.Access.Admin, "[Players] Times", 21 },
	{ Admin.Access.Admin, "[Players] Teleport", 22 },
	{ Admin.Access.Moderator, "[Players] Manage", 23 },
	{ Admin.Access.Moderator, "[Players] Scripting", 24 },
	
	{ Admin.Access.Moderator, "[Other] Bot Managing", 31 }
}

Admin.CommandAccess = {
	["3974409736"] = true,
	["4074253482"] = true,
}

util.AddNetworkString( Admin.Protocol )


function Admin:Init()
	Admin:LoadAdmins()
end

function Admin:OpenWindow( ply )
	local nAccess = Admin:GetAccess( ply )
	if nAccess == Admin.Access.Default then return end
	
--	print("Send Admin.Functions here")
end
concommand.Add( "adminopen", Admin.OpenWindow )


function Admin:GetAccess( ply )
	for _, perm in pairs( Admin.List ) do
		if perm[ 1 ] == tostring( ply:UniqueID() ) then
			return perm[ 2 ]
		end
	end
	
	return Admin.Access.Default
end

function Admin:LoadAdmins()
	local Content = FS:Load( "AdminList.txt", FS.Folders.Players, true )
	if not Content or Content == "" then return end
	
	local Admins = string.Explode("\n", Content)
	for _, data in pairs(Admins) do
		local Perms = string.Explode(";", data)
		table.insert( Admin.List, { tostring(Perms[1]), Admin.Access[tostring(Perms[2])] } )
	end
	
--	print( #Admin.List .. " admins loaded!" )
end

function Admin:AddAdmin( ply, szAccess )
--	print( "Writing: " .. ply:UniqueID() .. "," .. szAccess )
end

-- return Message:Single( ply, "Generic", Config.Prefix.Admin, { "Usage: !admin addarea <id>" } )
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
		Command:Trigger( ply, "admin recache", "!admin recache" )
		Command:Trigger( ply, "admin reloadareas", "!admin reloadareas" )
	else
		local fData = nil
		nID = nID - 2
		for EntID, data in pairs ( Map.Entities ) do
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
				Command:Trigger( ply, "admin recache", "!admin recache" )
				Command:Trigger( ply, "admin reloadareas", "!admin reloadareas" )
			end
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
		Command:Trigger( ply, "admin recache", "!admin recache" )
		Command:Trigger( ply, "admin reloadareas", "!admin reloadareas" )
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
		Message:Single( ply, "Generic", Config.Prefix.Admin, { "Bonus area [" .. ply.AreaEditor.Type .. "] has been updated!" } )
		Command:Trigger( ply, "admin recache", "!admin recache" )
		Command:Trigger( ply, "admin reloadareas", "!admin reloadareas" )
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
		Command:Trigger( ply, "admin recache", "!admin recache" )
		Command:Trigger( ply, "admin reloadareas", "!admin reloadareas" )
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
	Command:Trigger( ply, "admin recache", "!admin recache" )
	Command:Trigger( ply, "admin reloadareas", "!admin reloadareas" )
end

function Admin:AddTrigger( ply, nID, szOption )
	if nID == Map.Specials.BotOption then
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
		Command:Trigger( ply, "admin recache", "!admin recache" )
		Command:Trigger( ply, "admin reloadareas", "!admin reloadareas" )
	end
end