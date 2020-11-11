Admin = {}
Admin.Protocol = "Admin"
Admin.DefaultSID = "STEAM_0:0:00000000"
Admin.GamemodeKey = "2"

Admin.Level = {
	None = 0,
	Base = 1,
	Elevated = 2, 
	Moderator = 4,
	Admin = 8,
	Super = 16,
	Developer = 32,
	Owner = 64
}

Admin.Icons = {
	[Admin.Level.Base] = 1,
	[Admin.Level.Elevated] = 2,
	[Admin.Level.Moderator] = 3,
	[Admin.Level.Admin] = 4,
	[Admin.Level.Super] = 5,
	[Admin.Level.Developer] = 6,
	[Admin.Level.Owner] = 7
}

Admin.LevelNames = {}
for key,id in pairs( Admin.Level ) do
	Admin.LevelNames[ id ] = key
end

Admin.NotificationDelay = 60

local Secure = {}

-- Insert your Steam API Key here if you want Family Shared bans to work
Secure.SteamAPIKey = ""

Secure.Levels = {}
Secure.Setup = {
	-- Normal admin management
	{ 13, "Toggle mute (chat)", Admin.Level.Elevated, { 390, 42, 100, 25, true } },
	{ 14, "Toggle gag (voice)", Admin.Level.Elevated, { 495, 42, 100, 25, true } },
	
	{ 12, "Move to spectator", Admin.Level.Admin, { 390, 77, 100, 25, true } },
	{ 23, "Strip weapons", Admin.Level.Admin, { 495, 77, 100, 25, true } },
	{ 4, "Monitor sync", Admin.Level.Admin, { 600, 77, 100, 25, true } },
	
	{ 15, "Kick player", Admin.Level.Admin, { 390, 112, 100, 25, true } },
	{ 16, "Ban player", Admin.Level.Admin, { 495, 112, 100, 25, true } },
	{ 25, "Unban player", Admin.Level.Super, { 600, 112, 100, 25, true } },

	-- Map functionality (for Supervisors)
	{ 5, "Force change map", Admin.Level.Super, { 390, 167, 100, 25 } },
	{ 3, "Set map multiplier", Admin.Level.Super, { 495, 167, 100, 25 } },
	{ 21, "Set bonus multiplier", Admin.Level.Super, { 600, 167, 100, 25 } },
	{ 11, "Set map options", Admin.Level.Super, { 705, 167, 100, 25 } },
	
	{ 1, "Set zone", Admin.Level.Super, { 390, 202, 100, 25 } },
	{ 10, "Remove zone", Admin.Level.Super, { 495, 202, 100, 25 } },
	{ 2, "Cancel creation", Admin.Level.Super, { 600, 202, 100, 25 } },
	{ 6, "Reload zones", Admin.Level.Super, { 705, 202, 100, 25 } },
	
	{ 9, "Set zone height", Admin.Level.Super, { 390, 237, 100, 25 } },
	{ 19, "Set bot frame", Admin.Level.Super, { 495, 237, 100, 25 } },
	{ 20, "Cancel map vote", Admin.Level.Super, { 600, 237, 100, 25 } },
	{ 31, "Request screen", Admin.Level.Super, { 705, 237, 100, 25, true } },
	
	-- Development functionality
	{ 17, "Remove time", Admin.Level.Developer, { 390, 292, 100, 25 } },
	{ 18, "Remove bot", Admin.Level.Developer, { 495, 292, 100, 25 } },
	{ 28, "Remove all times for specific style", Admin.Level.Developer, { 600, 292, 205, 25 } },
	
	{ 24, "Reload admins", Admin.Level.Developer, { 390, 327, 100, 25 } },
	{ 22, "Remove map", Admin.Level.Developer, { 495, 327, 100, 25 } },
	{ 7, "Set authority", Admin.Level.Developer, { 600, 327, 100, 25, true } },
	{ 8, "Remove authority", Admin.Level.Developer, { 705, 327, 100, 25, true } },
	
	{ 29, "Send notification", Admin.Level.Developer, { 390, 362, 100, 25, true } },
	{ 30, "Teleport player", Admin.Level.Developer, { 495, 362, 100, 25, true } },
	
	-- Personal functionality (at end)
	{ 27, "Incognito spectating", Admin.Level.Admin, { 390, 402, 120, 25 } },
	{ 32, "Incognito admin", Admin.Level.Super, { 515, 402, 120, 25 } },
	
	-- Access levels
	{ 26, "Legit speed zone", Admin.Level.Super },
}


local ti, tr = table.insert, table.remove

-- Summary: Loads all admins from the master server and saves their access levels in a secure table
function Admin:LoadAdmins( szOperator )
	SQL:Prepare(
		"SELECT szSteam, nLevel FROM gmod_admins WHERE nType = {0} or nType = 0 ORDER BY nLevel DESC",
		{ Admin.GamemodeKey }
	):Execute( function( data, varArg, szError )
		Secure.Levels = {}
		
		if data then
			for _,item in pairs( data ) do
				Secure.Levels[ item["szSteam"] ] = item["nLevel"]
			end
		end
		
		if varArg then
			if szOperator and szOperator != "" then
				Secure.Levels[ szOperator ] = Admin.Level.Owner
			end
		end
		
		for _,p in pairs( player.GetHumans() ) do
			Admin:CheckPlayerStatus( p, true )
		end
		
		Admin.Loaded = true
	end, szOperator )
end

-- Summary: Loads all notifications from the master server (only appropriate ones) and save them to a table for later usage
function Admin:LoadNotifications()
	SQL:Prepare(
		"SELECT nTimeout, szText FROM gmod_notifications WHERE nType = {0} OR nType = 0 ORDER BY nID DESC",
		{ Admin.GamemodeKey }
	):Execute( function( data, varArg, szError )
		Secure.Notifications = {}
		
		local loadTime = CurTime()
		if data then
			for id,item in pairs( data ) do
				ti( Secure.Notifications, { item["nTimeout"], item["szText"], loadTime, id } )
			end
		end
		
		Admin.Loaded = true
	end )
	
	if timer.Exists( "NotificationTick" ) then
		timer.Destroy( "NotificationTick" )
	end
	
	timer.Create( "NotificationTick", Admin.NotificationDelay, 0, Admin.NotificationTick )
end


function Admin:GetAccess( ply )
	return Secure.Levels[ ply:SteamID() ] or Admin.Level.None
end

function Admin:CanAccess( ply, required )
	return Admin:GetAccess( ply ) >= required
end

function Admin:CanAccessID( ply, id, bypass )
	local l
	
	for _,data in pairs( Secure.Setup ) do
		if data[ 1 ] == id then
			l = data[ 3 ]
			break
		end
	end

	if not l then
		if bypass then return true end
		return false
	end
	return Admin:CanAccess( ply, l )
end

function Admin:IsHigherThan( a, b, eq, by )
	if not by and (not IsValid( a ) or not IsValid( b )) then return false end
	local ac, bc = Admin:GetAccess( a ), Admin:GetAccess( b )
	return eq and ac >= bc or ac > bc
end


function Admin:SetAccessIcon( ply, nLevel )
	if Admin.Icons[ nLevel ] then
		ply:SetNWInt( "AccessIcon", Admin.Icons[ nLevel ] )
	end
end

function Admin:CheckPlayerStatus( ply, reload )
	local nAccess = Admin:GetAccess( ply )
	if nAccess >= Admin.Level.Admin then
		ply:SetUserGroup( "admin" )
	end
	
	if nAccess >= Admin.Level.Base then
		Admin:SetAccessIcon( ply, nAccess )
	end
	
	if not reload and SQL.Available then
		Admin:CheckBan( ply )
	end
end

-- Summary: Sends a message to the master server which then saves it in the database
function Admin:AddLog( szText, szSteam, szAdmin )
	SQL:Prepare(
		"INSERT INTO gmod_logging (nType, szData, szDate, szAdminSteam, szAdminName) VALUES ({0}, {1}, {2}, {3}, {4})",
		{ Admin.GamemodeKey, szText, os.date( "%Y-%m-%d %H:%M:%S", os.time() ), szSteam, szAdmin }
	):Execute( function( data, varArg, szError )
		if data then
			Core:Print( "Logging", "Added entry: " .. szText )
		end
	end )
end

-- Summary: Creates a new ban on our master server (this means a global ban)
function Admin:AddBan( szSteam, szName, nLength, szReason, szAdminSteam, szAdminName )
	SQL:Prepare(
		"INSERT INTO gmod_bans (szUserSteam, szUserName, nStart, nLength, szReason, szAdminSteam, szAdminName) VALUES ({0}, {1}, {2}, {3}, {4}, {5}, {6})",
		{ szSteam, szName, os.time(), nLength, szReason, szAdminSteam, szAdminName }
	):Execute( function( data, varArg, szError )
		if data then
			Core:Print( "Admin", "Succesfully banned player " .. szName .. " (Steam ID: " .. szSteam .. ") - By admin: " .. szAdminName )
		else
			Core:Print( "Admin", "Failed to ban player (Error: " .. szError .. ") " .. szName .. " (Steam ID: " .. szSteam .. ") - By admin: " .. szAdminName .. " for " .. szReason .. " - Length: " .. nLength )
		end
	end )
end

-- Summary: Checks if the player has any existing bans, if they do, make sure they cannot connect, if they don't: proceed loading
function Admin:CheckBan( ply )
	SQL:Prepare(
		"SELECT * FROM gmod_bans WHERE szUserSteam = {0} AND szReason != {1} ORDER BY nStart DESC",
		{ ply:SteamID(), "UNBANNED" }
	):Execute( function( data, varArg, szError )
		if data then
			local banData
			
			if #data > 0 then
				for _,item in pairs( data ) do
					local length = item["nLength"] * 60
					if length == 0 then
						banData = { "permanently", item["szReason"] }
						break
					else
						local endTime = item["nStart"] + length
						if endTime >= varArg then
							local banLength = math.ceil( (endTime - varArg) / 60 )
							if not banData then
								banData = { banLength, item["szReason"] }
							else
								if banLength > banData[ 1 ] then
									banData = { banLength, item["szReason"] }
								end
							end
						end
					end
				end
			end
			
			if banData then
				if tonumber( banData[ 1 ] ) then
					banData[ 1 ] = "for a remaining " .. banData[ 1 ] .. " minutes"
				end
				
				szReason = "[Banned " .. banData[ 1 ] .. "] Reason: " .. banData[ 2 ]
				ply.DCReason = "Banned " .. banData[ 1 ]
				timer.Simple( 1, function() ply:Kick( szReason ) end )
			else
				if ply.Shared then return end
				
				Admin:CheckVIP( ply, varArg )
				Admin:CheckShared( ply )
			end
		else
			if ply.Shared then return end
			
			Admin:CheckVIP( ply, varArg )
			Admin:CheckShared( ply )
		end
	end, os.time() )
end

-- Summary: Check if the player has any existing VIP subscriptions running, if they do: proceed loading it
function Admin:CheckVIP( ply, nTime )
	-- Fix for when stupid people who are rejoining f*cking often when they're banned
	Core:Broadcast( "Print", { "General", Lang:Get( "Connect", { ply:Name(), ply:SteamID() } ) } )

	SQL:Prepare(
		"SELECT * FROM gmod_vips WHERE szSteam = {0} ORDER BY nID DESC LIMIT 1",
		{ ply:SteamID() }
	):Execute( function( data, varArg, szError )
		if Core:Assert( data, "nID" ) then
			local item = data[ 1 ]
			local length = item["nLength"] * 60
			local remain
			
			if length == 0 then
				remain = 0
			elseif length > 0 then
				local endTime = item["nStart"] + length
				if endTime >= varArg then
					remain = math.floor( (endTime - varArg) / 60 )
				end
			end
			
			if remain then
				Admin:SetVIP( ply, item["nType"], item["szTag"], item["szName"], item["szChat"], remain, item["nID"] )
			end
		end
	end, nTime )
end

-- Summary: Called on all non-banned players; check if they are using a lended game, then check if the owner of the game is banned
function Admin:CheckShared( ply )
	if Secure.SteamAPIKey == "" then return end

	local id64 = util.SteamIDTo64( ply:SteamID() )
	local szPath = "http://api.steampowered.com/IPlayerService/IsPlayingSharedGame/v0001/?key=" .. Secure.SteamAPIKey .. "&format=json&steamid=" .. id64 .. "&appid_playing=4000"
	
	Admin:ExecuteRequest( szPath, function( body, varArg )
		local tab = util.JSONToTable( body )
		
		if tab and tab["response"] and tab["response"]["lender_steamid"] then
			local lenderId = tab["response"]["lender_steamid"]
			if lenderId != "0" then
				Admin:CheckBan( {
					SteamID = function() return util.SteamIDFrom64( lenderId ) end,
					Kick = function( szReason )
						local reason = string.Explode( "]", szReason )
						varArg.DCReason = string.sub( reason[ 1 ], 2 )
						varArg:Kick( szReason )
					end,
					Shared = true
				} )
			end
		end
	end, nil, ply )
end

-- Console functions for FNAC
function GMConsoleReport( ply, szText )
	Core:Send( ply, "Print", { "Admin", Lang:Get( "AdminFNACReport", { szText } ) } )
end

function GMConsoleBan( szSteam, szName, nLength, szReason, bFNAC )
	Admin:AddBan( szSteam, szName, nLength, szReason, "STEAM_0_CONSOLE", bFNAC and "FNAC" or "CONSOLE" )
end

function GMConsoleLog( szText )
	Admin:AddLog( szText, "STEAM_0_CONSOLE", "LOGGING" )
end

function Admin:GenerateRequest( szCaption, szTitle, szDefault, nReturn )
	return { Caption = szCaption, Title = szTitle, Default = szDefault, Return = nReturn }
end

function Admin:ExecuteRequest( szPath, callback, errorcall, param )
	http.Fetch( szPath, function( body ) callback( body, param ) end, errorcall or function() print( "[HTTP Error] Couldn't retrieve data from", szPath ) end )
end

function Admin:FindPlayer( szID )
	local t = nil
	
	for _,p in pairs( player.GetHumans() ) do
		if tostring( p:SteamID() ) == tostring( szID ) then
			t = p
			break
		end
	end
	
	return t
end

function Admin.NotificationTick()
	if #Secure.Notifications > 0 then
		if not Admin.FirstNotification then
			local r = RTV:TrueRandom( 1, #Secure.Notifications )
			if Secure.Notifications[ r ][ 1 ] >= 600 then
				return Admin.NotificationTick()
			end
			
			Secure.Notifications[ r ][ 3 ] = CurTime()
			Admin:AddNotification( Secure.Notifications[ r ][ 2 ] )
			Admin.FirstNotification = true
		else
			local tabBlank, tabAvailable = {}, {}
			local nBlank, nAvailable = 0, 0
			local singleBlank = false
			
			for _,d in pairs( Secure.Notifications ) do
				if not d[ 3 ] then
					if d[ 1 ] < 600 then
						nBlank = nBlank + 1
						ti( tabBlank, d )
						singleBlank = true
					end
				elseif d[ 3 ] + d[ 1 ] < CurTime() then
					nAvailable = nAvailable + 1
					ti( tabAvailable, d )
				end
			end
			
			if not singleBlank and not Admin.AddedLong then
				for id,item in pairs( Secure.Notifications ) do
					Secure.Notifications[ id ][ 3 ] = CurTime() - item[ 1 ]
				end
				
				Admin.AddedLong = true
				return Admin.NotificationTick()
			end
		
			if nBlank > 0 then
				local r = RTV:TrueRandom( 1, #tabBlank )
				local a = tabBlank[ r ]
				
				Secure.Notifications[ a[ 4 ] ][ 3 ] = CurTime()
				Admin:AddNotification( a[ 2 ] )
			elseif nAvailable > 0 then
				local r = RTV:TrueRandom( 1, #tabAvailable )
				local a = tabAvailable[ r ]
				
				Secure.Notifications[ a[ 4 ] ][ 3 ] = CurTime()
				Admin:AddNotification( a[ 2 ] )
			end
		end
	end
end

function Admin:AddNotification( szText )
	Core:Broadcast( "Print", { _C["ServerName"], szText } )
end

function Admin:SetVIP( ply, nType, szTag, szName, szChat, nRemaining, nID )
	ply.IsVIP = true
	ply.VIPID = nID
	
	ply.VIPRemaining = tonumber( nRemaining )
	ply.VIPExpire = ply.VIPRemaining == 0 and "Never" or (os.date( "%Y-%m-%d %H:%M:%S", os.time() + (ply.VIPRemaining or 0) * 60 ) or "Unknown")
	ply.VIPLevel = nil
	
	if nType == 1 then
		ply.VIPLevel = Admin.Level.Base
	elseif nType == 2 then
		ply.VIPLevel = Admin.Level.Elevated
	end
	
	if szTag and szTag != "" and szTag != "NULL" then
		local tabTag = string.Explode( " ", szTag )
		ply.VIPTag = { Vector( tr( tabTag, 1 ), tr( tabTag, 1 ), tr( tabTag, 1 ) ), string.Implode( " ", tabTag ) }
		
		ply:SetNWString( "VIPTag", ply.VIPTag[ 2 ] )
		ply:SetNWVector( "VIPTagColor", ply.VIPTag[ 1 ] )
	end
	
	if szName and szName != "" and szName != "NULL" then
		local tabName = Core.Util:NoEmpty( string.Explode( " ", szName ) )
		if #tabName >= 6 and ply.VIPLevel and ply.VIPLevel == Admin.Level.Elevated then
			local customName = false
			if tabName[ 7 ] and tostring( tabName[ 7 ] ) != "" and tostring( tabName[ 7 ] ) != " " then
				customName = true
			end
			
			ply.VIPGradient = {}
			if tonumber( tabName[ 4 ] ) and tonumber( tabName[ 5 ] ) and tonumber( tabName[ 6 ] ) then
				ply.VIPGradient = { Vector( tr( tabName, 1 ), tr( tabName, 1 ), tr( tabName, 1 ) ), Vector( tr( tabName, 1 ), tr( tabName, 1 ), tr( tabName, 1 ) ), "Console" }
				local a,b = ply.VIPGradient[ 1 ], ply.VIPGradient[ 2 ]
				if not a.x or not a.y or not a.z or a.x < 0 or a.y < 0 or a.z < 0 then ply.VIPGradient[ 1 ] = Vector( -1, 0, 0 ) end
				if not b.x or not b.y or not b.z or b.x < 0 or b.y < 0 or b.z < 0 then ply.VIPGradient[ 2 ] = Vector( -1, 0, 0 ) end
			end
			
			ply.VIPGradient[ 3 ] = customName and string.Implode( " ", tabName ) or ply:Name()
			ply.VIPName = { Vector( 257, 0, 0 ), ply.VIPGradient[ 3 ] }
			
			ply:SetNWString( "VIPName", ply.VIPName[ 2 ] )
			ply:SetNWVector( "VIPNameColor", ply.VIPName[ 1 ] )
			if ply.VIPGradient and ply.VIPGradient[ 1 ] and ply.VIPGradient[ 2 ] then
				ply:SetNWVector( "VIPGradientS", ply.VIPGradient[ 1 ] )
				ply:SetNWVector( "VIPGradientE", ply.VIPGradient[ 2 ] )
			end
		elseif #tabName == 3 then
			ply.VIPName = { Vector( tr( tabName, 1 ), tr( tabName, 1 ), tr( tabName, 1 ) ), ply:Name() }
			
			ply:SetNWString( "VIPName", ply.VIPName[ 2 ] )
			ply:SetNWVector( "VIPNameColor", ply.VIPName[ 1 ] )
		else
			ply.VIPName = { Vector( tr( tabName, 1 ), tr( tabName, 1 ), tr( tabName, 1 ) ), string.Implode( " ", tabName ) }
			
			ply:SetNWString( "VIPName", ply.VIPName[ 2 ] )
			ply:SetNWVector( "VIPNameColor", ply.VIPName[ 1 ] )
		end
	end
	
	if szChat and szChat != "" and szChat != "NULL" then
		local tabChat = string.Explode( " ", szChat )
		ply.VIPChat = Vector( tr( tabChat, 1 ), tr( tabChat, 1 ), tr( tabChat, 1 ) )
		
		ply:SetNWVector( "VIPChat", ply.VIPChat )
	end
	
	if not Admin:CanAccess( ply, Admin.Level.Admin ) then
		Secure.Levels[ ply:SteamID() ] = ply.VIPLevel
		Admin:CheckPlayerStatus( ply, true )
	end
end

local VIPInvalid = { "mod", "moderator", "admin", "admln", "admun", "administrator", "supervisor", "developer", "owner", "0wn3r", "0wner", "own3r", "gravious", "push", "delete", "select", ";", "*", "truncate", "table" }
function Admin:IsVIPCustomValid( ply, szInput )
	local szInvalid = nil

	if Admin:CanAccess( ply, Admin.Level.Developer ) then
		return szInvalid
	end
	
	for _,needle in pairs( VIPInvalid ) do
		if string.find( string.lower( szInput ), needle, 1, true ) then
			szInvalid = needle
			break
		end
	end
	
	return szInvalid
end

-- Summary: Sets the players VIP data by the given type and returns a message with the callback result
function Admin:SetVIPData( ply, szMessage, nType, szData )
	if not ply.IsVIP or not ply.VIPID then return end
	
	local queries = {
		"UPDATE gmod_vips SET szTag = {0} WHERE nID = {1}",
		"UPDATE gmod_vips SET szName = {0} WHERE nID = {1}",
		"UPDATE gmod_vips SET szChat = {0} WHERE nID = {1}"
	}

	SQL:Prepare(
		queries[ nType ],
		{ szData, ply.VIPID }
	):Execute( function( data, varArg, szError )
		if data then
			Core:Send( varArg[ 1 ], "Print", { "VIP", varArg[ 2 ] } )
		else
			Core:Send( varArg[ 1 ], "Print", { "VIP", "We couldn't save your changes. Please try again." } )
		end
	end, { ply, szMessage } )
end

function Admin:VIPPanelCall( ply, args )
	if not ply.IsVIP then return end
	local data = args[ 2 ]
	
	local szType = tostring( data[ 1 ] )
	if szType == "Rainbow" and ply.VIPLevel and ply.VIPLevel >= Admin.Level.Elevated then
		local szName = ply:GetNWString( "VIPName", ply:Name() )
		local szInvalid = Admin:IsVIPCustomValid( ply, szName )
		if szInvalid then
			return Core:Send( ply, "Print", { "VIP", "You had some disallowed pieces of text in your name: " .. szInvalid } )
		end
		
		ply.VIPName = { Vector( 98, 176, 255 ), szName }
		
		local colorVector = ply:GetNWVector( "VIPNameColor", Vector( -1, 0, 0 ) )
		if colorVector.x == 256 then
			ply.VIPName[ 1 ] = Vector( 98, 176, 255 )
		else
			ply.VIPName[ 1 ] = Vector( 256, 0, 0 )
		end
		
		ply:SetNWString( "VIPName", ply.VIPName[ 2 ] )
		ply:SetNWVector( "VIPNameColor", ply.VIPName[ 1 ] )
		
		Admin:SetVIPData( ply, "Your name is now " .. (ply.VIPName[ 1 ].x > 255 and "" or "no longer ") .. "displayed in rainbow colors", 2, string.Implode( " ", { math.floor( ply.VIPName[ 1 ].x ), math.floor( ply.VIPName[ 1 ].y ), math.floor( ply.VIPName[ 1 ].z ), ply.VIPName[ 2 ] } ) )
	elseif szType == "Gradient" and ply.VIPLevel and ply.VIPLevel >= Admin.Level.Elevated then
		if not ply.VIPSetGradient then
			Core:Send( ply, "Print", { "VIP", Lang:Get( "MiscVIPGradient" ) } )
			ply.VIPSetGradient = true
		else
			local szInvalid = Admin:IsVIPCustomValid( ply, data[ 4 ] )
			if szInvalid then
				return Core:Send( ply, "Print", { "VIP", "You had some disallowed pieces of text in your name: " .. szInvalid } )
			end
			
			local szLen = string.len( data[ 4 ] )
			if szLen < 3 or szLen > 26 then
				return Core:Send( ply, "Print", { "VIP", "You name length must be between 3 and 26 characters" } )
			end
		
			ply.VIPSetGradient = nil
			ply.VIPGradient = { Vector( data[ 2 ].r, data[ 2 ].g, data[ 2 ].b ), Vector( data[ 3 ].r, data[ 3 ].g, data[ 3 ].b ), data[ 4 ] == "" and ply:Name() or data[ 4 ] }
			ply.VIPName = { Vector( 257, 0, 0 ), ply.VIPGradient[ 3 ] }
			
			ply:SetNWString( "VIPName", ply.VIPName[ 2 ] )
			ply:SetNWVector( "VIPNameColor", ply.VIPName[ 1 ] )
			ply:SetNWVector( "VIPGradientS", ply.VIPGradient[ 1 ] )
			ply:SetNWVector( "VIPGradientE", ply.VIPGradient[ 2 ] )
			
			Admin:SetVIPData( ply, "Your name is now displayed in a gradient", 2, string.Implode( " ", { math.floor( ply.VIPGradient[ 1 ].x ), math.floor( ply.VIPGradient[ 1 ].y ), math.floor( ply.VIPGradient[ 1 ].z ), math.floor( ply.VIPGradient[ 2 ].x ), math.floor( ply.VIPGradient[ 2 ].y ), math.floor( ply.VIPGradient[ 2 ].z ), ply.VIPName[ 2 ] } ) )
		end
	elseif szType == "Save" and ply.VIPLevel and ply.VIPLevel >= Admin.Level.Elevated then
		if data[ 2 ] then
			ply.VIPChat = Vector( data[ 2 ].r, data[ 2 ].g, data[ 2 ].b )
			ply:SetNWVector( "VIPChat", ply.VIPChat )
			
			Admin:SetVIPData( ply, "Your chat text color has been changed", 3, string.Implode( " ", { math.floor( ply.VIPChat.x ), math.floor( ply.VIPChat.y ), math.floor( ply.VIPChat.z ) } ) )
		end
	elseif szType == "Tag" then
		if data[ 3 ] == "" or data[ 3 ] == " " then
			ply.VIPTag = nil
			ply:SetNWString( "VIPTag", "" )
			ply:SetNWVector( "VIPTagColor", Vector( -1, 0, 0 ) )
			
			Admin:SetVIPData( ply, "Your tag has been reset", 1, "" )
		else
			local szInvalid = Admin:IsVIPCustomValid( ply, data[ 3 ] )
			if szInvalid then
				return Core:Send( ply, "Print", { "VIP", "You had some disallowed pieces of text in your tag: " .. szInvalid } )
			end
			
			local szLen = string.len( data[ 3 ] )
			if szLen < 3 or szLen > 20 then
				return Core:Send( ply, "Print", { "VIP", "You tag length must be between 3 and 20 characters" } )
			end
			
			ply.VIPTag = { Vector( data[ 2 ].r, data[ 2 ].g, data[ 2 ].b ), data[ 3 ] }
			ply:SetNWString( "VIPTag", ply.VIPTag[ 2 ] )
			ply:SetNWVector( "VIPTagColor", ply.VIPTag[ 1 ] )
			
			Admin:SetVIPData( ply, "Your tag has been changed to: " .. ply.VIPTag[ 2 ], 1, string.Implode( " ", { math.floor( ply.VIPTag[ 1 ].x ), math.floor( ply.VIPTag[ 1 ].y ), math.floor( ply.VIPTag[ 1 ].z ), ply.VIPTag[ 2 ] } ) )
		end
	elseif szType == "Name" then
		if data[ 3 ] == "" or data[ 3 ] == " " then
			ply.VIPName = nil
			ply:SetNWString( "VIPName", ply:Name() )
			ply:SetNWVector( "VIPNameColor", Vector( -1, 0, 0 ) )
			
			Admin:SetVIPData( ply, "Your name has been reset to: " .. ply:Name(), 2, "" )
		else
			local szInvalid = Admin:IsVIPCustomValid( ply, data[ 3 ] )
			if szInvalid then
				return Core:Send( ply, "Print", { "VIP", "You had some disallowed pieces of text in your name: " .. szInvalid } )
			end
			
			local szLen = string.len( data[ 3 ] )
			if szLen < 3 or szLen > 26 then
				return Core:Send( ply, "Print", { "VIP", "You name length must be between 3 and 26 characters" } )
			end
			
			ply.VIPName = { Vector( data[ 2 ].r, data[ 2 ].g, data[ 2 ].b ), data[ 3 ] }
			ply:SetNWString( "VIPName", ply.VIPName[ 2 ] )
			ply:SetNWVector( "VIPNameColor", ply.VIPName[ 1 ] )
			
			Admin:SetVIPData( ply, "Your name has been changed to: " .. ply.VIPName[ 2 ], 2, string.Implode( " ", { math.floor( ply.VIPName[ 1 ].x ), math.floor( ply.VIPName[ 1 ].y ), math.floor( ply.VIPName[ 1 ].z ), ply.VIPName[ 2 ] } ) )
		end
	end
end

function Admin.VIPProcess( ply, args, extra )
	if not ply.IsVIP or not ply.VIPLevel then
		return Core:Send( ply, "Print", { _C["ServerName"], Lang:Get( "MiscVIPRequired" ) } )
	end

	if #args > 0 then
		local szType = args[ 1 ]
		if szType == "remaining" then
			Core:Send( ply, "Print", { "VIP", "VIP Expires on: " .. ply.VIPExpire .. " - Remaining minutes: " .. (ply.VIPRemaining or 0) } )
		elseif szType == "extend" then
			RTV:VIPExtend( ply )
		elseif szType == "me" or szType == "emote" then
			if ply.VIPLevel >= Admin.Level.Elevated then
				if ply.AdminMute then return end
				local tab = extra and args[ 2 ] or args.Upper
				if not tab then return end
				if tab and not extra then table.remove( tab, 1 ) end
				if tab and #tab > 0 then
					local message = string.Implode( " ", tab )
					Core:Broadcast( "Client", { "Emote", { tostring( ply:SteamID() ), message } } )
				else
					Core:Send( ply, "Print", { "VIP", "Your must supply a status to send. Example: /me is feeling good" } )
				end
			else
				Core:Send( ply, "Print", { "VIP", "This command is only available for Elevated VIPs" } )
			end
		elseif szType == "gag" or szType == "mute" then
			if ply.VIPLevel >= Admin.Level.Elevated then
				Admin:CreateWindow( ply )
			else
				Core:Send( ply, "Print", { "VIP", "This command is only available for Elevated VIPs" } )
			end
		else
			Core:Send( ply, "Print", { "VIP", "Invalid subcommand. Available VIP commands: remaining, extend, me, gag, mute" } )
		end
	else
		local tab = {
			Title = ply:Name() .. "'s VIP Panel",
			Width = 240,
			Height = 469,
		}
		
		local tag = ply:GetNWString( "VIPTag", "I'm a VIP" )
		local tagc = ply:GetNWVector( "VIPTagColor", Vector( 98, 176, 255 ) )
		local tagcv = Color( tagc.x, tagc.y, tagc.z )
		
		local name = ply:GetNWString( "VIPName", ply:Name() )
		local namec = ply:GetNWVector( "VIPNameColor", Vector( 98, 176, 255 ) )
		local namecv = Color( namec.x, namec.y, namec.z )
		
		local chatc = ply:GetNWVector( "VIPChat", Vector( 255, 255, 255 ) )
		local chatcv = Color( chatc.x, chatc.y, chatc.z )
		
		table.insert( tab, { Type = "DLabel", Modifications = { ["SetPos"] = { 20, 40 }, ["SetSize"] = { 200, 16 }, ["SetText"] = { "Normal VIP (Remaining days: " .. (ply.VIPRemaining == 0 and "Infinite" or math.ceil( ply.VIPRemaining / 1440 )) .. ")" } } } )
		table.insert( tab, { Type = "DLabel", Modifications = { ["SetPos"] = { 20, 60 }, ["SetSize"] = { 200, 16 }, ["SetText"] = { "Tag color" } } } )
		table.insert( tab, { Type = "DColorMixer", Label = "ColorTag", Modifications = { ["SetAlphaBar"] = { false }, ["SetPalette"] = { false }, ["SetColor"] = { tagcv }, ["SetPos"] = { 20, 80 }, ["SetSize"] = { 200, 120 } } } )
		table.insert( tab, { Type = "DLabel", Modifications = { ["SetPos"] = { 20, 209 }, ["SetSize"] = { 60, 16 }, ["SetText"] = { "Tag text:" } } } )
		table.insert( tab, { Type = "DTextEntry", Label = "TextTag", Modifications = { ["SetPos"] = { 75, 207 }, ["SetSize"] = { 145, 22 }, ["SetText"] = { tag } } } )
		
		table.insert( tab, { Type = "DLabel", Modifications = { ["SetPos"] = { 20, 242 }, ["SetSize"] = { 200, 16 }, ["SetText"] = { "Name color" } } } )
		table.insert( tab, { Type = "DColorMixer", Label = "ColorName", Modifications = { ["SetAlphaBar"] = { false }, ["SetPalette"] = { false }, ["SetColor"] = { namecv }, ["SetPos"] = { 20, 260 }, ["SetSize"] = { 200, 120 } } } )
		table.insert( tab, { Type = "DLabel", Modifications = { ["SetPos"] = { 20, 389 }, ["SetSize"] = { 60, 16 }, ["SetText"] = { "Name text:" } } } )
		table.insert( tab, { Type = "DTextEntry", Label = "TextName", Modifications = { ["SetPos"] = { 85, 387 }, ["SetSize"] = { 135, 22 }, ["SetText"] = { name } } } )
		table.insert( tab, { Type = "DButton", VIP = true, Extra = "Tag", Modifications = { ["SetPos"] = { 20, 422 }, ["SetSize"] = { 95, 25 }, ["SetText"] = { "Save Tag" } } } )
		table.insert( tab, { Type = "DButton", VIP = true, Extra = "Name", Modifications = { ["SetPos"] = { 125, 422 }, ["SetSize"] = { 95, 25 }, ["SetText"] = { "Save Name" } } } )
		
		if ply.VIPLevel >= Admin.Level.Elevated then
			tab.Width = tab.Width + 235
			
			table.insert( tab, { Type = "DLabel", Modifications = { ["SetPos"] = { 250, 40 }, ["SetSize"] = { 200, 16 }, ["SetText"] = { "Extended VIP (Remaining days: " .. (ply.VIPRemaining == 0 and "Infinite" or math.ceil( ply.VIPRemaining / 1440 )) .. ")" } } } )
			
			table.insert( tab, { Type = "DLabel", Modifications = { ["SetPos"] = { 250, 60 }, ["SetSize"] = { 200, 16 }, ["SetText"] = { "Chat text color" } } } )
			table.insert( tab, { Type = "DColorMixer", Label = "ColorChat", Modifications = { ["SetAlphaBar"] = { false }, ["SetPalette"] = { false }, ["SetColor"] = { chatcv }, ["SetPos"] = { 250, 80 }, ["SetSize"] = { 200, 120 } } } )
			
			table.insert( tab, { Type = "DLabel", Modifications = { ["SetPos"] = { 250, 365 }, ["SetSize"] = { 200, 100 }, ["SetText"] = { "To mute or gag people,\ntype !admin or !vip gag/mute\n\nIf you want to reset your tag or name,\nsimply leave the box blank and save!" } } } )
			
			table.insert( tab, { Type = "DButton", VIP = true, Extra = "Random", Modifications = { ["SetPos"] = { 250, 207 }, ["SetSize"] = { 95, 25 }, ["SetText"] = { "Randomize color" } } } )
			table.insert( tab, { Type = "DButton", VIP = true, Extra = "Save", Modifications = { ["SetPos"] = { 355, 207 }, ["SetSize"] = { 95, 25 }, ["SetText"] = { "Save chat color" } } } )
			table.insert( tab, { Type = "DButton", VIP = true, Extra = "Rainbow", Modifications = { ["SetPos"] = { 250, 260 }, ["SetSize"] = { 200, 25 }, ["SetText"] = { "Toggle rainbow color in name" } } } )
			table.insert( tab, { Type = "DButton", VIP = true, Extra = "Gradient", Modifications = { ["SetPos"] = { 250, 295 }, ["SetSize"] = { 200, 25 }, ["SetText"] = { "Set gradient (Press for help)" } } } )
		end
		
		table.insert( tab, { Type = "DButton", Close = true, Modifications = { ["SetPos"] = { tab.Width - 25, 8 }, ["SetSize"] = { 16, 16 }, ["SetText"] = { "X" } } } )
		
		Core:Send( ply, "Admin", { "GUI", "VIP", tab } )
	end
end

local tabNames = nil
function Admin:GetAccessString( nLevel )
	if tabNames then
		return tabNames[ nLevel ]
	end
	
	tabNames = {}
	for name,level in pairs( Admin.Level ) do
		tabNames[ level ] = name
	end
	
	return tabNames[ nLevel ]
end

function Admin:GetOnlineAdmins()
	local tab = {}
	
	for _,p in pairs( player.GetHumans() ) do
		if Admin:CanAccess( p, Admin.Level.Moderator ) then
			table.insert( tab, p )
		end
	end
	
	return tab
end

function Admin:HandleTeamChat( ply, text, original )
	if not Admin:CanAccess( ply, Admin.Level.Moderator ) then return text end
	
	local nLevel = Admin:GetAccess( ply )
	local tabAdmins = Admin:GetOnlineAdmins()
	
	Core:Send( tabAdmins, "Print", { "Admin", Lang:Get( "AdminChat", { Admin:GetAccessString( nLevel ), ply:Name(), text } ) } )
	return ""
end

function Admin:URLEncode( str )
	if str then
		str = string.gsub( str, "\n", "\r\n" )
		str = string.gsub( str, "([^%w ])", function( sub ) return string.format( "%%%02X", string.byte( sub ) ) end )
		str = string.gsub( str, " ", "+" )
	end
	
	return str
end

function Admin:GetPlayerList()
	local tab = {}
	
	for _,p in pairs( player.GetHumans() ) do
		local nAccess = Admin:GetAccess( p )
		local szAccess = nAccess > 0 and Admin.LevelNames[ nAccess ] or "Player"
		
		table.insert( tab, { p:Name(), p:SteamID(), szAccess } )
	end
	
	return tab
end


function Admin.CommandProcess( ply, args )
	if not Admin:CanAccess( ply, Admin.Level.Elevated ) then
		return Core:Send( ply, "Print", { "General", Lang:Get( "InvalidCommand", { args.Key } ) } )
	end
	
	if #args == 0 then
		Admin:CreateWindow( ply )
	else
		local szID, nAccess = args[ 1 ], Admin:GetAccess( ply )
		if szID == "mute" and nAccess >= Admin.Level.Elevated then
			if not args[ 2 ] then return Core:Send( ply, "Print", { "Admin", "Please enter a valid Steam ID like this: !admin " .. szID .. " STEAM_0:ID" } ) end
			Admin:HandleButton( ply, { -2, 13, args.Upper[ 2 ] } )
		elseif szID == "gag" and nAccess >= Admin.Level.Elevated then
			if not args[ 2 ] then return Core:Send( ply, "Print", { "Admin", "Please enter a valid Steam ID like this: !admin " .. szID .. " STEAM_0:ID" } ) end
			Admin:HandleButton( ply, { -2, 14, args.Upper[ 2 ] } )
		elseif szID == "spectator" and nAccess >= Admin.Level.Admin then
			if not args[ 2 ] then return Core:Send( ply, "Print", { "Admin", "Please enter a valid Steam ID like this: !admin " .. szID .. " STEAM_0:ID" } ) end
			Admin:HandleButton( ply, { -2, 12, args.Upper[ 2 ] } )
		elseif szID == "strip" and nAccess >= Admin.Level.Admin then
			if not args[ 2 ] then return Core:Send( ply, "Print", { "Admin", "Please enter a valid Steam ID like this: !admin " .. szID .. " STEAM_0:ID" } ) end
			Admin:HandleButton( ply, { -2, 23, args.Upper[ 2 ] } )
		elseif szID == "monitor" and nAccess >= Admin.Level.Admin then
			if not args[ 2 ] then return Core:Send( ply, "Print", { "Admin", "Please enter a valid Steam ID like this: !admin " .. szID .. " STEAM_0:ID" } ) end
			Admin:HandleButton( ply, { -2, 4, args.Upper[ 2 ] } )
		elseif szID == "kick" and nAccess >= Admin.Level.Admin then
			if not args[ 2 ] then return Core:Send( ply, "Print", { "Admin", "Please enter a valid Steam ID like this: !admin " .. szID .. " STEAM_0:ID" } ) end
			Admin:HandleButton( ply, { -2, 15, args.Upper[ 2 ] } )
		elseif szID == "ban" and nAccess >= Admin.Level.Admin then
			if not args[ 2 ] then return Core:Send( ply, "Print", { "Admin", "Please enter a valid Steam ID like this: !admin " .. szID .. " STEAM_0:ID" } ) end
			Admin:HandleButton( ply, { -2, 16, args.Upper[ 2 ] } )
		else
			Core:Send( ply, "Print", { "Admin", "This is not a valid subcommand of " .. args.Key .. "." } )
		end
	end
end

function Admin:CreateWindow( ply )
	local access = Admin:GetAccess( ply )
	local tab = {
		Title = ply:Name() .. "'s Admin Panel",
		Width = 720,
		Height = 447,
	}
	
	if access < Admin.Level.Elevated then return end
	if access > Admin.Level.Admin then tab.Width = tab.Width + 105 end
	
	table.insert( tab, { Type = "DButton", Close = true, Modifications = { ["SetPos"] = { tab.Width - 25, 8 }, ["SetSize"] = { 16, 16 }, ["SetText"] = { "X" } } } )
	table.insert( tab, { Type = "DListView", Label = "PlayerList", Modifications = { ["SetMultiSelect"] = { false }, ["SetPos"] = { 20, 42 }, ["SetSize"] = { 360, 360 }, ["Sequence"] = { { "AddColumn", { "Player" } }, { "AddColumn", { "Steam ID" }, "SetFixedWidth", 120 }, { "AddColumn", { "Authority" } } } } } )
	table.insert( tab, { Type = "DTextEntry", Label = "PlayerSteam", Modifications = { ["SetPos"] = { 20, 407 }, ["SetSize"] = { 360, 22 }, ["SetText"] = { "Steam ID" } } } )
	
	for _,item in pairs( Secure.Setup ) do
		if not item[ 3 ] or not item[ 4 ] then continue end
		if access >= item[ 3 ] then
			local data = item[ 4 ]
			local mod = {
				["SetPos"] = { data[ 1 ], data[ 2 ] },
				["SetSize"] = { data[ 3 ], data[ 4 ] },
				["SetText"] = { item[ 2 ] }
			}
			
			table.insert( tab, { Type = "DButton", Identifier = item[ 1 ], Require = item[ 5 ], Modifications = mod } )
		end
	end
	
	Core:Send( ply, "Admin", { "GUI", "Admin", tab } )
	Core:Send( ply, "Admin", { "GUIData", "Players", Admin:GetPlayerList() } )
	Core:Send( ply, "Admin", { "GUIData", "Store", { "PlayerSteam", "Steam ID" } } )
end

function Admin:HandleClient( ply, args )
	local nID = tonumber( args[ 1 ] )
	if nID == 1 then
		Admin:VIPPanelCall( ply, args )
	elseif nID == -1 then
		Admin:HandleRequest( ply, args )
	elseif nID == -2 then
		Admin:HandleButton( ply, args )
	end
end

-- Calls when a button is pressed
function Admin:HandleButton( ply, args )
	local ID, Steam = tonumber( args[ 2 ] ), tostring( args[ 3 ] )
	if not Admin:CanAccessID( ply, ID ) then
		return Core:Send( ply, "Print", { "Admin", "You don't have access to use this functionality" } )
	end
	
	if ID == 1 then
		if Zones:CheckSet( ply, true, ply.ZoneExtra ) then return end
		if Steam == "Extra" then ply.ZoneExtra = true end
		
		local tabQuery = {
			Caption = "What kind of zone do you want to set?\n(Note: When you select one, you will immediately start placing it!)",
			Title = "Select zone type"
		}

		for name,id in pairs( Zones.Type ) do
			table.insert( tabQuery, { name, { ID, id } } )
		end
		
		table.insert( tabQuery, { "Close", {} } )
		
		if not ply.ZoneExtra then
			table.insert( tabQuery, { "Add Extra", { ID, -10 } } )
		else
			table.insert( tabQuery, { "Stop Extra", { ID, -20 } } )
		end
		
		Core:Send( ply, "Admin", { "Query", tabQuery } )
	elseif ID == 2 then
		if Zones:CheckSet( ply ) then
			Zones:CancelSet( ply, true )
		else
			Core:Send( ply, "Print", { "Admin", Lang:Get( "ZoneNoEdit" ) } )
		end
	elseif ID == 3 then
		local tabRequest = Admin:GenerateRequest( "Enter the map multiplier. This is the weight or points value of the map (Default is 1)", "Map multiplier", tostring( Timer.Multiplier ), ID )
		Core:Send( ply, "Admin", { "Request", tabRequest } )
	elseif ID == 4 then
		local target = Admin:FindPlayer( Steam )
		
		if IsValid( target ) then
			Core:Send( ply, "Print", { "Admin", "Toggled " .. target:Name() .. "'s admin sync state to: " .. SMgrAPI:AdminMonitorToggle( target ) } )
		else
			Core:Send( ply, "Print", { "Admin", "Couldn't find a valid player with Steam ID: " .. Steam } )
		end
	elseif ID == 5 then
		local tabRequest = Admin:GenerateRequest( "Enter the map to change to (Default is the current map - Note: Changing to the same map might cause glitches)", "Change map", game.GetMap(), ID )
		Core:Send( ply, "Admin", { "Request", tabRequest } )
	elseif ID == 6 then
		Zones:Reload()
		Core:Send( ply, "Print", { "Admin", Lang:Get( "AdminOperationComplete" ) } )
	elseif ID == 7 then
		local target = Admin:FindPlayer( Steam )
		
		if IsValid( target ) then
			ply.AdminTarget = target:SteamID()
			
			local tabRequest = Admin:GenerateRequest( "Enter the desired access level.\nAvailable levels: Moderator, Admin, Super, Developer, Owner\nNote: This will only set their admin for this server", "Set authority", "Admin", ID )
			Core:Send( ply, "Admin", { "Request", tabRequest } )
		else
			Core:Send( ply, "Print", { "Admin", "Couldn't find a valid player with Steam ID: " .. Steam } )
		end
	elseif ID == 8 then
		-- Summary: Fully removes all admin access from the specified Steam ID
		SQL:Prepare(
			"DELETE FROM gmod_admins WHERE szSteam = {0}",
			{ Steam }
		):Execute( function( data, varArg, szError )
			if data then
				if IsValid( varArg ) then
					if varArg:GetNWInt( "AccessIcon", 0 ) > 0 then
						varArg:SetNWInt( "AccessIcon", 0 )
					end
					
					Secure.Levels[ varArg:SteamID() ] = varArg.VIPLevel
				end
				
				Core:Send( ply, "Print", { "Admin", Lang:Get( "AdminOperationComplete" ) } )
			else
				Core:Send( ply, "Print", { "Admin", Lang:Get( "AdminErrorCode", { szError } ) } )
			end
		end, Admin:FindPlayer( Steam ) )
	elseif ID == 9 then
		local tabQuery = {
			Caption = "Which zone do you want to edit height of?\n(Note: When you select one, you will get a new window that shows height!)",
			Title = "Select zone"
		}

		for _,zone in pairs( Zones.Entities ) do
			if IsValid( zone ) then
				table.insert( tabQuery, { Zones:GetName( zone.zonetype ) .. " (" .. zone:EntIndex() .. ")", { ID, zone:EntIndex() } } )
			end
		end
		
		table.insert( tabQuery, { "Close", {} } )
		
		Core:Send( ply, "Admin", { "Query", tabQuery } )
	elseif ID == 10 then
		local tabQuery = {
			Caption = "Select the zone that you want to remove.\n(Note: The zone will be removed immediately!)\n(Note: The higher the number, the later it was added)",
			Title = "Remove zone"
		}
		
		for _,zone in pairs( Zones.Entities ) do
			if IsValid( zone ) then
				local extra = ""
				if zone.zonetype == Zones.Type.LegitSpeed then
					extra = " (" .. zone.speed .. ")"
				end
				
				table.insert( tabQuery, { Zones:GetName( zone.zonetype ) .. " (" .. zone:EntIndex() .. ")" .. extra, { ID, zone:EntIndex() } } )
			end
		end
		
		table.insert( tabQuery, { "Close", {} } )
		
		Core:Send( ply, "Admin", { "Query", tabQuery } )
	elseif ID == 11 then
		local tabQuery = {
			Caption = "Please click map required options. Select values that you want to add. Once you're done, press Save (Default is none)",
			Title = "Map options"
		}
		
		for name,zone in pairs( Zones.Options ) do
			local szAdd = bit.band( Timer.Options, zone ) > 0 and " (On)" or " (Off)"
			table.insert( tabQuery, { name .. szAdd, { ID, zone } } )
		end
		
		table.insert( tabQuery, { "Save", { ID, -1 } } )
		table.insert( tabQuery, { "Cancel", {} } )
		
		Core:Send( ply, "Admin", { "Query", tabQuery } )
	elseif ID == 12 then
		local target = Admin:FindPlayer( Steam )
		
		if IsValid( target ) then
			if Admin:IsHigherThan( target, ply, true ) then
				return Core:Send( ply, "Print", { "Admin", Lang:Get( "AdminHierarchy" ) } )
			end
			
			if not target.Spectating then
				Command.Spectate( target )
				Core:Send( ply, "Print", { "Admin", "You have moved " .. target:Name() .. " to spectator." } )
			else
				Core:Send( ply, "Print", { "Admin", "This player is already spectating." } )
			end
		else
			Core:Send( ply, "Print", { "Admin", "Couldn't find a valid player with Steam ID: " .. Steam } )
		end
	elseif ID == 13 then
		local target = Admin:FindPlayer( Steam )
		
		if IsValid( target ) then
			if Admin:IsHigherThan( target, ply, true ) then
				return Core:Send( ply, "Print", { "Admin", Lang:Get( "AdminHierarchy" ) } )
			end
			
			target.AdminMute = not target.AdminMute
			Core:Broadcast( "Manage", { "Mute", target:SteamID(), target.AdminMute } )
			Core:Send( ply, "Print", { "Admin", "You have " .. (target.AdminMute and "muted " or "unmuted ") .. target:Name() .. "!" } )
		else
			Core:Send( ply, "Print", { "Admin", "Couldn't find a valid player with Steam ID: " .. Steam } )
		end
	elseif ID == 14 then
		local target = Admin:FindPlayer( Steam )
		
		if IsValid( target ) then
			if Admin:IsHigherThan( target, ply, true ) then
				return Core:Send( ply, "Print", { "Admin", Lang:Get( "AdminHierarchy" ) } )
			end
			
			target.AdminGag = not target.AdminGag
			Core:Broadcast( "Manage", { "Gag", target:SteamID(), target.AdminGag } )
			Core:Send( ply, "Print", { "Admin", "You have " .. (target.AdminGag and "gagged " or "ungagged ") .. target:Name() .. "!" } )
		else
			Core:Send( ply, "Print", { "Admin", "Couldn't find a valid player with Steam ID: " .. Steam } )
		end
	elseif ID == 15 then
		local target = Admin:FindPlayer( Steam )
		
		if IsValid( target ) then
			if Admin:IsHigherThan( target, ply, true ) then
				return Core:Send( ply, "Print", { "Admin", Lang:Get( "AdminHierarchy" ) } )
			end
			
			ply.AdminTarget = target:SteamID()
			
			local tabRequest = Admin:GenerateRequest( "Enter reason for kick", "Kick player", "I would kindly request you to get the fuck out.", ID )
			Core:Send( ply, "Admin", { "Request", tabRequest } )
		else
			Core:Send( ply, "Print", { "Admin", "Couldn't find a valid player with Steam ID: " .. Steam } )
		end
	elseif ID == 16 then
		local target = { SteamID = function() return Steam end }
		
		if Admin:IsHigherThan( target, ply, true, true ) then
			return Core:Send( ply, "Print", { "Admin", Lang:Get( "AdminHierarchy" ) } )
		end
		
		ply.AdminTarget = target:SteamID()
		
		local tabRequest = Admin:GenerateRequest( "Enter length and reason for ban separated with a semicolon (;)", "Ban player", "1440;One day ban for misbehaving.", ID )
		Core:Send( ply, "Admin", { "Request", tabRequest } )
	elseif ID == 17 then
		if not ply.RemovingTimes then
			ply.RemovingTimes = true
			Core:Send( ply, "Admin", { "Edit", ID } )
			Core:Send( ply, "Print", { "Admin", "You are now editing times. Type !wr and select an item to remove it. Press this option again to disable it." } )
		else
			ply.RemovingTimes = nil
			Core:Send( ply, "Admin", { "Edit", nil } )
			Core:Send( ply, "Print", { "Admin", "You have left time editing mode." } )
		end
	elseif ID == 18 then
		local tabRequest = Admin:GenerateRequest( "Are you sure you want to remove a current bot? Type the ID of the target style to confirm. (This cannot be un-done)", "Confirm removal", "No", ID )
		Core:Send( ply, "Admin", { "Request", tabRequest } )
	elseif ID == 19 then
		local ob = ply:GetObserverTarget()
		if not IsValid( ob ) or not ob:IsBot() then
			return Core:Send( ply, "Print", { "Admin", "You have to spectate the target bot to change position of the bot." } )
		end
		
		ply.AdminBotStyle = ob.Style
		
		local tabData = Bot:GetFramePosition( ply.AdminBotStyle )
		local tabRequest = Admin:GenerateRequest( "Change position in run of the bot (Currently at " .. tabData[ 1 ] .. " / " .. tabData[ 2 ] .. ")", "Change position of playback", tostring( tabData[ 1 ] ), ID )
		Core:Send( ply, "Admin", { "Request", tabRequest } )
	elseif ID == 20 then
		RTV.CancelVote = not RTV.CancelVote
		Core:Send( ply, "Print", { "Admin", "The map vote is now set to " .. (not RTV.CancelVote and "not " or "") .. "be cancelled!" } )
	elseif ID == 21 then
		local tabRequest = Admin:GenerateRequest( "Enter the bonus multiplier. This is the weight or points value of the bonus (Default is 1)", "Bonus multiplier", tostring( Timer.BonusMultiplier ), ID )
		Core:Send( ply, "Admin", { "Request", tabRequest } )
	elseif ID == 22 then
		local tabRequest = Admin:GenerateRequest( "Enter the name of the map to be removed.\nWARNING: This will remove all saved data of the map, including times!", "Completely remove map", "", ID )
		Core:Send( ply, "Admin", { "Request", tabRequest } )
	elseif ID == 23 then
		local target = Admin:FindPlayer( Steam )
		
		if IsValid( target ) then
			if Admin:IsHigherThan( target, ply, true ) then
				return Core:Send( ply, "Print", { "Admin", Lang:Get( "AdminHierarchy" ) } )
			end
			
			target.WeaponStripped = not target.WeaponStripped
			target:StripWeapons()
			target:StripAmmo()
	
			local szPickup = target.WeaponStripped and "They can no longer pick anything up" or "They can pick weapons up again"
			Core:Send( ply, "Print", { "Admin", "You have stripped " .. target:Name() .. " of their weapons (" .. szPickup .. ")." } )
		else
			Core:Send( ply, "Print", { "Admin", "Couldn't find a valid player with Steam ID: " .. Steam } )
		end
	elseif ID == 24 then
		Admin:LoadAdmins()
		Core:Send( ply, "Print", { "Admin", "All admins have been reloaded!" } )
	elseif ID == 25 then
		local function UnbanPlayerById( nID, adminPly )
			-- Summary: Unbans the player on a specific ban with the given ID
			SQL:Prepare(
				"UPDATE gmod_bans SET nStart = {0}, nLength = {1}, szReason = {2}, szAdminName = {3} WHERE nID = {4}",
				{ os.time(), 1, "UNBANNED", adminPly:Name(), nID }
			):Execute( function( data, varArg, szError )
				if data then
					Core:Send( varArg, "Print", { "Admin", "You have unbanned the player with Steam ID: " .. Steam .. "(ID: " .. nID .. ")" } )
					Admin:AddLog( "Admin unbanned player " .. Steam, varArg:SteamID(), varArg:Name() )
				else
					Core:Send( varArg, "Print", { "Admin", "An error occurred when unbanning the player with Steam ID: " .. Steam } )
				end
			end, adminPly )
		end
	
		-- Summary: Gets the latest ban on the player and makes sure it's unbanned if there's any (if they have multiple bans, they must be unbanned multiple times)
		SQL:Prepare(
			"SELECT nID FROM gmod_bans WHERE szUserSteam = {0} ORDER BY nStart DESC LIMIT 1",
			{ Steam }
		):Execute( function( data, varArg, szError )
			if Core:Assert( data, "nID" ) then
				local unbanFunc = varArg[ 1 ]
				local adminPly = varArg[ 2 ]
				
				unbanFunc( data[ 1 ]["nID"], adminPly )
			end
		end, { UnbanPlayerById, ply } )
	elseif ID == 26 then
		Zones.Editor[ ply ].Steps = true
		
		local tabRequest = Admin:GenerateRequest( "Please enter the maximum speed the player will be able to get after entering this zone.\nNote: The player will keep this speed until entering a new zone.", "Enter speed limit for zone", "480", ID )
		Core:Send( ply, "Admin", { "Request", tabRequest } )
	elseif ID == 27 then
		if ply.Spectating then
			return Core:Send( ply, "Print", { "Admin", "You must be outside of spectator mode in order to change this setting in order to avoid suspicion." } )
		end
		
		ply.Incognito = not ply.Incognito
		Core:Send( ply, "Print", { "Admin", "Your incognito mode is now " .. (ply.Incognito and "enabled" or "disabled") } )
	elseif ID == 28 then
		local tabRequest = Admin:GenerateRequest( "Enter the ID of the style of which all times are to be removed.\nWARNING: This will remove all times permanently!", "Remove all times for mode", "No", ID )
		Core:Send( ply, "Admin", { "Request", tabRequest } )
	elseif ID == 29 then
		ply.AdminTarget = nil
		
		if Steam then
			local target = Admin:FindPlayer( Steam )
			
			if IsValid( target ) then
				ply.AdminTarget = target
			end
		end
		
		local tabRequest = Admin:GenerateRequest( "Enter the message to print on the screen" .. (IsValid( ply.AdminTarget ) and " of " .. ply.AdminTarget:Name() or ""), "Show admin notification", "", ID )
		Core:Send( ply, "Admin", { "Request", tabRequest } )
	elseif ID == 30 then
		local target = Admin:FindPlayer( Steam )
		
		if IsValid( target ) then
			ply.AdminTarget = target:SteamID()
			
			local tabRequest = Admin:GenerateRequest( "Enter the Steam ID of the target player (where the selected player will be teleported to).\nWARNING: This is possible on any style and will not stop their timer!", "Teleport player", "", ID )
			Core:Send( ply, "Admin", { "Request", tabRequest } )
		else
			Core:Send( ply, "Print", { "Admin", "Couldn't find a valid player with Steam ID: " .. Steam } )
		end
	elseif ID == 31 then
		local target = Admin:FindPlayer( Steam )
		
		if IsValid( target ) then
			if Admin:IsHigherThan( target, ply, true ) then
				return Core:Send( ply, "Print", { "Admin", Lang:Get( "AdminHierarchy" ) } )
			end
			
			if not Admin.Screenshot then
				Admin.Screenshot = {}
			end
			
			Admin.Screenshot[ target ] = ply
			Core:Send( ply, "Print", { "Admin", "Now requesting screen capture of " .. target:Name() } )
			Core:Send( target, "Admin", { "Grab" } )
		else
			Core:Send( ply, "Print", { "Admin", "Couldn't find a valid player with Steam ID: " .. Steam } )
		end
	elseif ID == 32 then
		local now = ply:GetNWInt( "AccessIcon", 0 )
		if now > 0 then
			ply:SetNWInt( "AccessIcon", 0 )
		else
			local nAccess = Admin:GetAccess( ply )
			if nAccess >= Admin.Level.Base then
				Admin:SetAccessIcon( ply, nAccess )
			end
		end
		
		Core:Send( ply, "Print", { "Admin", "Your admin incognito mode is now " .. (now > 0 and "enabled" or "disabled") } )
	end
end

-- Responses from Derma requests or Queries
function Admin:HandleRequest( ply, args )
	local ID, Value = tonumber( args[ 2 ] ), args[ 3 ]
	if ID != 17 then
		Value = tostring( Value )
	end
	
	if not Admin:CanAccessID( ply, ID, ID > 50 ) then
		return Core:Send( ply, "Print", { "Admin", "You don't have access to use this functionality" } )
	end
	
	if ID == 1 then
		local Type = tonumber( Value )
		if Type == -10 then
			return Admin:HandleButton( ply, { -2, ID, "Extra" } )
		elseif Type == -20 then
			ply.ZoneExtra = nil
			return Admin:HandleButton( ply, { -2, ID } )
		end
		
		Zones:StartSet( ply, Type )
	elseif ID == 3 then
		local nMultiplier = tonumber( Value )
		if not nMultiplier then
			return Core:Send( ply, "Print", { "Admin", Lang:Get( "AdminInvalidFormat", { Value, "Number" } ) } )
		end
		
		local nOld = Timer.Multiplier or 1
		Timer.Multiplier = nMultiplier
		
		local Check = sql.Query( "SELECT szMap FROM game_map WHERE szMap = '" .. game.GetMap() .. "'" )
		if Core:Assert( Check, "szMap" ) then
			sql.Query( "UPDATE game_map SET nMultiplier = " .. Timer.Multiplier .. " WHERE szMap = '" .. game.GetMap() .. "'" )
		else
			sql.Query( "INSERT INTO game_map VALUES ('" .. game.GetMap() .. "', " .. Timer.Multiplier .. ", NULL, 0, NULL)" )
		end
		
		for i = _C.Style.Normal, _C.Style.Bonus do
			Timer:RecalculatePoints( i )
		end
		Timer:LoadRecords()
		for _,p in pairs( player.GetHumans() ) do
			Player:UpdateRank( p )
		end
		
		RTV:UpdateMapListVersion()
		Core:Send( ply, "Print", { "Admin", Lang:Get( "AdminSetValue", { "Multiplier", Timer.Multiplier } ) } )
		Admin:AddLog( "Changed map multiplier on " .. game.GetMap() .. " from " .. nOld .. " to " .. nMultiplier, ply:SteamID(), ply:Name() )
	elseif ID == 5 then
		Core:Unload()
		RunConsoleCommand( "changelevel", Value )
	elseif ID == 7 then
		local szSteam, szLevel, nType = ply.AdminTarget, Value, tonumber( Admin.GamemodeKey )
		local nAccess = Admin.Level.None
		
		for name,level in pairs( Admin.Level ) do
			if string.find( string.lower( name ), string.lower( szLevel ) ) then
				nAccess = level
				break
			end
		end
		
		if nAccess == Admin.Level.None then
			return Core:Send( ply, "Print", { "Admin", Lang:Get( "AdminMisinterpret", { szLevel } ) } )
		end
		
		local function UpdateAdminStatus( bUpdate, sqlArg, adminPly )
			local function UpdateAdminCallback( data, varArg, szError )
				local targetAdmin, targetData = varArg[ 1 ], varArg[ 2 ]
				
				if data then
					Admin:LoadAdmins()
					Core:Send( targetAdmin, "Print", { "Admin", Lang:Get( "AdminOperationComplete" ) } )
					Admin:AddLog( "Updated admin with identifier [" .. targetData[ 1 ] .. "] to level " .. targetData[ 2 ] .. " and type " .. targetData[ 3 ], targetAdmin:SteamID(), targetAdmin:Name() )
				else
					print( "No data, that sucks mayne!" )
					Core:Send( targetAdmin, "Print", { "Admin", Lang:Get( "AdminErrorCode", { szError } ) } )
				end
			end
			
			-- Summary: Adds a new admin whether they exist or not with the specified details
			if bUpdate then
				SQL:Prepare(
					"UPDATE gmod_admins SET nLevel = {1}, nType = {2} WHERE nID = {0}",
					sqlArg
				):Execute( UpdateAdminCallback, { adminPly, sqlArg } )
			else
				SQL:Prepare(
					"INSERT INTO gmod_admins (szSteam, nLevel, nType) VALUES ({0}, {1}, {2})",
					sqlArg
				):Execute( UpdateAdminCallback, { adminPly, sqlArg } )
			end
		end
		
		-- Summary: Checks if the entered Steam ID has any existing admin powers, and see whether we promote or demote him
		SQL:Prepare(
			"SELECT nID FROM gmod_admins WHERE szSteam = {0} ORDER BY nLevel DESC LIMIT 1",
			{ szSteam }
		):Execute( function( data, varArg, szError )
			local adminPly, sqlArg = varArg[ 2 ], varArg[ 3 ]
			local bUpdate = false
			
			if Core:Assert( data, "nID" ) then
				bUpdate = true
				sqlArg[ 1 ] = data[ 1 ]["nID"]
			end
			
			local updateFunc = varArg[ 1 ]
			updateFunc( bUpdate, sqlArg, adminPly )
		end, { UpdateAdminStatus, ply, { szSteam, nAccess, nType } } )
	elseif ID == 9 then
		local nIndex, bFind = tonumber( Value ), false
		
		for _,zone in pairs( Zones.Entities ) do
			if IsValid( zone ) and zone:EntIndex() == nIndex then
				ply.ZoneData = { zone.zonetype, zone.min, zone.max }
				bFind = true
				break
			end
		end
		
		if not bFind then
			Core:Send( ply, "Print", { "Admin", "Couldn't find selected entity. Please try again." } )
		else
			local nHeight = math.Round( ply.ZoneData[ 3 ].z - ply.ZoneData[ 2 ].z )
			local tabRequest = Admin:GenerateRequest( "Enter new desired height (Default is 128)", "Change height", tostring( nHeight ), 90 )
			Core:Send( ply, "Admin", { "Request", tabRequest } )
		end
	elseif ID == 90 then
		local nValue = tonumber( Value )
		if not nValue then
			return Core:Send( ply, "Print", { "Admin", Lang:Get( "AdminInvalidFormat", { Value, "Number" } ) } )
		end

		local OldPos1 = util.TypeToString( ply.ZoneData[ 2 ] )
		local OldPos2 = util.TypeToString( ply.ZoneData[ 3 ] )
		
		local nMin = ply.ZoneData[ 2 ].z
		ply.ZoneData[ 3 ].z = nMin + nValue
		
		sql.Query( "UPDATE game_zones SET vPos1 = '" .. util.TypeToString( ply.ZoneData[ 2 ] ) .. "', vPos2 = '" .. util.TypeToString( ply.ZoneData[ 3 ] ) .. "' WHERE szMap = '" .. game.GetMap() .. "' AND nType = " .. ply.ZoneData[ 1 ] .. " AND vPos1 = '" .. OldPos1 .. "' AND vPos2 = '" .. OldPos2 .. "'" )
		
		Zones:Reload()
		Core:Send( ply, "Print", { "Admin", Lang:Get( "AdminOperationComplete" ) } )
	elseif ID == 10 then
		local nIndex, bFind, nType = tonumber( Value ), false, nil
		
		for _,zone in pairs( Zones.Entities ) do
			if IsValid( zone ) and zone:EntIndex() == nIndex then
				if zone.zonetype == Zones.Type.LegitSpeed and zone.speed then
					zone.deltype = zone.zonetype .. zone.speed
				end
				
				sql.Query( "DELETE FROM game_zones WHERE szMap = '" .. game.GetMap() .. "' AND nType = " .. (zone.deltype or zone.zonetype) .. " AND vPos1 = '" .. util.TypeToString( zone.min ) .. "' AND vPos2 = '" .. util.TypeToString( zone.max ) .. "'" )
				
				nType = zone.zonetype
				bFind = true
				break
			end
		end
		
		if not bFind then
			Core:Send( ply, "Print", { "Admin", "Couldn't find selected entity. Please try again." } )
		else
			Zones:Reload()
			Core:Send( ply, "Print", { "Admin", Lang:Get( "AdminOperationComplete" ) } )
			
			Admin:AddLog( "Admin removed zone of type " .. Zones:GetName( nType ), ply:SteamID(), ply:Name() )
		end
	elseif ID == 11 then
		local nValue = tonumber( Value )
		if not nValue then
			return Core:Send( ply, "Print", { "Admin", Lang:Get( "AdminInvalidFormat", { Value, "Number" } ) } )
		end
		
		if nValue > 0 then
			local has = bit.band( Timer.Options, nValue ) > 0
			Timer.Options = has and bit.band( Timer.Options, bit.bnot( nValue ) ) or bit.bor( Timer.Options, nValue )
			Zones:MapChecks()
			Admin:HandleButton( ply, { -2, ID } )
		else
			local szValue = Timer.Options == 0 and "NULL" or Timer.Options
		
			local Check = sql.Query( "SELECT szMap FROM game_map WHERE szMap = '" .. game.GetMap() .. "'" )
			if Core:Assert( Check, "szMap" ) then
				sql.Query( "UPDATE game_map SET nOptions = " .. szValue .. " WHERE szMap = '" .. game.GetMap() .. "'" )
			else
				sql.Query( "INSERT INTO game_map VALUES ('" .. game.GetMap() .. "', " .. Timer.Multiplier .. ", NULL, 0, " .. szValue .. ")" )
			end
			
			Admin:AddLog( "Admin changed map options to " .. szValue, ply:SteamID(), ply:Name() )
			Core:Send( ply, "Print", { "Admin", Lang:Get( "AdminSetValue", { "Options", Timer.Options } ) } )
		end
	elseif ID == 15 then
		local target = Admin:FindPlayer( ply.AdminTarget )
		
		if IsValid( target ) then
			if Admin:IsHigherThan( target, ply, true ) then
				return Core:Send( ply, "Print", { "Admin", Lang:Get( "AdminHierarchy" ) } )
			end
			
			local szReason, szName = Value or "Unknown reason", target:Name()
			target.DCReason = "Kicked by admin"
			target:Kick( "[Kicked] Reason: " .. szReason )
			
			Core:Broadcast( "Print", { "General", Lang:Get( "AdminPlayerKick", { szName, szReason } ) } )
			Core:Send( ply, "Print", { "Admin", "You have kicked " .. szName .. " for reason: " .. szReason } )
			
			Admin:AddLog( "Admin issued kick on " .. szName .. " with reason: " .. szReason, ply:SteamID(), ply:Name() )
		else
			Core:Send( ply, "Print", { "Admin", "Couldn't find a valid player with Steam ID: " .. ply.AdminTarget } )
		end
	elseif ID == 16 then
		local split = string.Explode( ";", Value )
		if #split != 2 then
			return Core:Send( ply, "Print", { "Admin", Lang:Get( "AdminMisinterpret", { Value } ) } )
		end
		
		local target = Admin:FindPlayer( ply.AdminTarget )
		local nLength, szReason, szName = tonumber( split[ 1 ] ), split[ 2 ], "Offline Player"
		
		if not nLength then
			return Core:Send( ply, "Print", { "Admin", Lang:Get( "AdminInvalidFormat", { split[ 1 ], "Number" } ) } )
		end
		
		if util.SteamIDTo64( ply.AdminTarget or "" ) == "0" then
			return Core:Send( ply, "Print", { "Admin", Lang:Get( "AdminInvalidFormat", { ply.AdminTarget, "Steam ID" } ) } )
		end
		
		if IsValid( target ) then
			szName = target:Name()
			target.DCReason = "Banned by admin"
			target:Kick( "[Banned " .. (nLength == 0 and "permanently" or "for " .. nLength .. " minutes") .. "] Reason: " .. szReason )
		end
		
		Admin:AddBan( ply.AdminTarget, szName, nLength, szReason, ply:SteamID(), ply:Name() )
		Admin:AddLog( "Admin banned player " .. ply.AdminTarget .. " (" .. nLength .. " mins) for reason: " .. szReason, ply:SteamID(), ply:Name() )
		
		if not IsValid( target ) then
			szName = ply.AdminTarget
		end
		
		Core:Broadcast( "Print", { "General", Lang:Get( "AdminPlayerBan", { szName, nLength, szReason } ) } )
		Core:Send( ply, "Print", { "Admin", "You have banned " .. szName .. " for reason: " .. szReason .. " (Length: " .. nLength .. ")" } )
	elseif ID == 17 then
		ply.TimeRemoveData = Value
		local tabRequest = Admin:GenerateRequest( "Are you sure you want to remove " .. Value[ 4 ] .. "'s #" .. Value[ 2 ] .. " time? (Type Yes to confirm)", "Confirm removal", "No", 170 )
		Core:Send( ply, "Admin", { "Request", tabRequest } )
	elseif ID == 170 then
		if Value != "Yes" then
			return Core:Send( ply, "Print", { "Admin", "Time removal operation has been cancelled!" } )
		end
		
		local d = ply.TimeRemoveData
		local nStyle, nRank, szUID = tonumber( d[ 1 ] ), tonumber( d[ 2 ] ), tostring( d[ 3 ] )
		
		sql.Query( "DELETE FROM game_times WHERE szMap = '" .. game.GetMap() .. "' AND nStyle = " .. nStyle .. " AND szUID = '" .. szUID .. "'" )
		Timer:LoadRecords()
		
		local i = Bot:GetInfo( nStyle )
		if i and i.Style and i.SteamID and i.Style == nStyle and i.SteamID == szUID then
			sql.Query( "DELETE FROM game_bots WHERE szMap = '" .. game.GetMap() .. "' AND nStyle = " .. nStyle .. " AND szUID = '" .. szUID .. "'" )
			
			if Bot:Exists( i.Style ) then
				for _,b in pairs( player.GetBots() ) do
					if b.Style == i.Style then
						b.DCReason = "Bot runner time was removed"
						b:Kick( "Bot time was removed" )
					end
				end
			end
			
			Bot:ClearStyle( nStyle )
			
			local szStyle = nStyle == _C.Style.Normal and ".txt" or ("_" .. nStyle .. ".txt")
			if file.Exists( _C.GameType .. "/bots/bot_" .. game.GetMap() .. szStyle, "DATA" ) then
				file.Delete( _C.GameType .. "/bots/bot_" .. game.GetMap() .. szStyle )
			end
		end
		
		for _,p in pairs( player.GetHumans() ) do
			if IsValid( p ) and p:SteamID() == szUID then
				Player:LoadBest( p )
				break
			end
		end
		
		ply.TimeRemoveData = nil
		Core:Send( ply, "Print", { "Admin", d[ 4 ] .. "'s #" .. nRank .. " time has been deleted and records have been reloaded!" } )
	elseif ID == 18 then
		local nStyle = tonumber( Value )
		if not nStyle then
			return Core:Send( ply, "Print", { "Admin", "Bot removal operation has been cancelled!" } )
		end
		
		if not Core:IsValidStyle( nStyle ) then
			return Core:Send( ply, "Print", { "Admin", "Invalid style entered!" } )
		end
		
		for _,b in pairs( player.GetBots() ) do
			if b.Style == nStyle then
				b.DCReason = "Bot was deleted"
				b:Kick( "Bot deleted" )
			end
		end
		
		local szStyle = nStyle == _C.Style.Normal and ".txt" or ("_" .. nStyle .. ".txt")
		if file.Exists( _C.GameType .. "/bots/bot_" .. game.GetMap() .. szStyle, "DATA" ) then
			file.Delete( _C.GameType .. "/bots/bot_" .. game.GetMap() .. szStyle )
		end
		
		sql.Query( "DELETE FROM game_bots WHERE szMap = '" .. game.GetMap() .. "' AND nStyle = " .. nStyle )
		Bot:ClearStyle( nStyle )
	elseif ID == 19 then
		local nFrame = tonumber( Value )
		if not nFrame then
			return Core:Send( ply, "Print", { "Admin", Lang:Get( "AdminInvalidFormat", { Value, "Number" } ) } )
		end
		
		local tabData = Bot:GetFramePosition( ply.AdminBotStyle )
		if nFrame >= tabData[ 2 ] then
			nFrame = tabData[ 2 ] - 2
		elseif nFrame < 1 then
			nFrame = 1
		end
		
		local info = Bot:GetInfo( ply.AdminBotStyle )
		local current = (nFrame / tabData[ 2 ]) * info.Time
		info.Start = CurTime() - current
		
		Bot:SetInfoData( ply.AdminBotStyle, info )
		Bot:SetFramePosition( ply.AdminBotStyle, nFrame )
	elseif ID == 21 then
		local nMultiplier = tonumber( Value )
		if not nMultiplier then
			return Core:Send( ply, "Print", { "Admin", Lang:Get( "AdminInvalidFormat", { Value, "Number" } ) } )
		end
		
		local nOld = Timer.BonusMultiplier or 1
		Timer.BonusMultiplier = nMultiplier
		
		local Check = sql.Query( "SELECT szMap FROM game_map WHERE szMap = '" .. game.GetMap() .. "'" )
		if Core:Assert( Check, "szMap" ) then
			sql.Query( "UPDATE game_map SET nBonusMultiplier = " .. Timer.BonusMultiplier .. " WHERE szMap = '" .. game.GetMap() .. "'" )
		else
			sql.Query( "INSERT INTO game_map VALUES ('" .. game.GetMap() .. "', " .. Timer.Multiplier .. ", " .. Timer.BonusMultiplier .. ", 0, NULL)" )
		end
		
		Timer:RecalculatePoints( _C.Style.Bonus )
		Timer:LoadRecords()
		for _,p in pairs( player.GetHumans() ) do
			Player:UpdateRank( p )
		end
		
		Admin:AddLog( "Changed bonus multiplier on " .. game.GetMap() .. " from " .. nOld .. " to " .. nMultiplier, ply:SteamID(), ply:Name() )
		Core:Send( ply, "Print", { "Admin", Lang:Get( "AdminSetValue", { "Bonus multiplier", Timer.BonusMultiplier } ) } )
	elseif ID == 22 then
		if not RTV:MapExists( Value ) then
			Core:Send( ply, "Print", { "Admin", "The entered map '" .. Value .. "' is not on the nominate list, and thus cannot be deleted as it contains no info." } )
		else
			sql.Query( "DELETE FROM game_bots WHERE szMap = '" .. Value .. "'" )
			sql.Query( "DELETE FROM game_map WHERE szMap = '" .. Value .. "'" )
			sql.Query( "DELETE FROM game_times WHERE szMap = '" .. Value .. "'" )
			sql.Query( "DELETE FROM game_zones WHERE szMap = '" .. Value .. "'" )
			
			if file.Exists( _C.GameType .. "/bots/bot_" .. Value .. ".txt", "DATA" ) then
				file.Delete( _C.GameType .. "/bots/bot_" .. Value .. ".txt" )
			end
			
			for i = 1, 8 do
				if file.Exists( _C.GameType .. "/bots/bot_" .. Value .. "_" .. i .. ".txt", "DATA" ) then
					file.Delete( _C.GameType .. "/bots/bot_" .. Value .. "_" .. i .. ".txt" )
				end
			end
			
			Core:Send( ply, "Print", { "Admin", "All found info has been deleted!" } )
			Admin:AddLog( "Fully removed map " .. Value, ply:SteamID(), ply:Name() )
		end
	elseif ID == 26  then
		local nValue = tonumber( Value )
		if not nValue then
			return Core:Send( ply, "Print", { "Admin", Lang:Get( "AdminInvalidFormat", { Value, "Number" } ) } )
		end
		
		Zones:FinishSet( ply, nValue )
	elseif ID == 28 then
		local nStyle = tonumber( Value )
		if not nStyle then
			return Core:Send( ply, "Print", { "Admin", "Time deletion operation has been cancelled!" } )
		end
		
		if not Core:IsValidStyle( nStyle ) then
			return Core:Send( ply, "Print", { "Admin", "Invalid style entered!" } )
		end
		
		sql.Query( "DELETE FROM game_times WHERE szMap = '" .. game.GetMap() .. "' AND nStyle = " .. nStyle )
		Timer:LoadRecords()
		
		for _,p in pairs( player.GetHumans() ) do
			if IsValid( p ) then
				Player:LoadBest( p )
				break
			end
		end
	elseif ID == 29 then
		if Value == "" then
			return Core:Send( ply, "Print", { "Admin", "Oborting notification because text was empty." } )
		else
			Value = "[" .. Admin:GetAccessString( Admin:GetAccess( ply ) ) .. "] " .. ply:Name() .. ": " .. Value
		end
		
		if IsValid( ply.AdminTarget ) then
			Core:Send( ply.AdminTarget, "Admin", { "Message", Value } )
		else
			Core:Broadcast( "Admin", { "Message", Value } )
		end
		
		ply.AdminTarget = nil
	elseif ID == 30 then
		local target = Admin:FindPlayer( Value )
		
		if IsValid( target ) then
			local source = Admin:FindPlayer( ply.AdminTarget )
			if not IsValid( source ) then
				return Core:Send( ply, "Print", { "Admin", "The source entity was lost or disconnected." } )
			end
			
			source:SetPos( target:GetPos() )
			Core:Send( ply, "Print", { "Admin", source:Name() .. " has been teleported to " .. target:Name() } )
		else
			Core:Send( ply, "Print", { "Admin", "Couldn't find a valid target player with Steam ID: " .. Steam } )
		end
	end
end