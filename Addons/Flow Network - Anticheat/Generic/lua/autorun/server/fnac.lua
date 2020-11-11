-- Server end created by Gravious
-- Originally for Flow Network, hence the name, Flow Network Anti Cheat (FNAC)

if not SERVER then return end
local function FNAC_Print( szText )
	print( "[FNAC] " .. szText )
end

util.AddNetworkString("abc123thatgirlworeherjeanslikeme")
util.AddNetworkString("imastealinurshit")
util.AddNetworkString("immadisallowin")

local FNAC_BanCache = {}
local FNAC_Level = { Warn = 0, Kick = 1, Ban = 2 }
local FNAC_ReportList = {
	{ "setupvalue", FNAC_Level.Ban, 0 },
	{ "runstring", FNAC_Level.Ban, 10080 },
	{ "unwanted", FNAC_Level.Ban, 0 },
	{ "required", FNAC_Level.Ban, 0 },
	{ "library", FNAC_Level.Ban, 0 },
	{ "incorrect", FNAC_Level.Ban, 10080 },
	{ "overridden", FNAC_Level.Kick },
	{ "functions", FNAC_Level.Ban, 10080 },
	{ "module", FNAC_Level.Kick },
	{ "movement", FNAC_Level.Warn },
	{ "replay", FNAC_Level.Warn },
}

local function FNAC_Notify( szName, szReason )
	for _,p in pairs( player.GetHumans() ) do
		if p:IsAdmin() then
			if GMConsoleReport then
				GMConsoleReport( p, "Detection for " .. szName .. ": " .. szReason )
			else
				FNAC_Print( "Error: Report module not found!" )
			end
		end
	end
end

local function FNAC_Report( ply, szReason )
	local szAdminMessage = szReason
	local szMMR = "No data"
	
	if string.find( string.lower( szReason ), "recorder data", 1, true ) then
		szMMR = string.sub( szReason, 17 )
		
		szAdminMessage = "Movement assisting tools detected: " .. szMMR
		szReason = "Movement assisting tools detected"
	end

	local target = nil
	for _,data in pairs( FNAC_ReportList ) do
		if string.find( string.lower( szReason ), data[ 1 ], 1, true ) then
			if not target or (target and target[ 2 ] < data[ 2 ]) then
				target = data
			end
		end
	end
	
	if not target then
		FNAC_Print( "Unlisted cheat found!" )
		target = { "Unlisted cheat detected", FNAC_Level.Warn }
	end
	
	
	
	if target[ 1 ] == "overridden" then
		if string.find( string.lower( szReason ), "allowcslua", 1, true ) then
			target[ 2 ] = FNAC_Level.Ban
			target[ 3 ] = 10080
		end
	elseif target[ 1 ] == "movement" then
		local single, save = false, true
		local tab = string.Explode( " ", szMMR )
		for i = 1, #tab do
			tab[ i ] = tonumber( tab[ i ] )
			if not tab[ i ] then
				FNAC_Print( "Received invalid movement data! (" .. i .. ")" )
				if GMConsoleLog and not single then
					GMConsoleLog( "Received invalid movement data on this one! (" .. i .. ")" )
					single = true
				end
			end
		end
		
		local MMRMin = 0.5
		if tab[ 8 ] and tonumber( tab[ 8 ] ) then
			if tonumber( tab[ 8 ] ) < 15 then
				MMRMin = 0.9
			end
		end
		
		if (tab[ 3 ] == 0 and tab[ 2 ] > 0) or (tab[ 5 ] and tab[ 4 ] > 0) or (tab[ 7 ] == 0 and tab[ 6 ] > 0) then
			save = false
			return false
		elseif tab[ 1 ] > 0 or tab[ 2 ] / (tab[ 2 ] + tab[ 3 ]) > MMRMin or tab[ 4 ] / (tab[ 4 ] + tab[ 5 ]) > MMRMin then --or tab[ 6 ] / (tab[ 6 ] + tab[ 7 ]) > MMRMin then
			target[ 2 ] = FNAC_Level.Ban
			target[ 3 ] = 0
		end
		
		if GMConsoleLog and save then
			GMConsoleLog( "FNAC Movement data (" .. game.GetMap() .. ") of " .. ply:Name() .. " " .. szMMR )
		end
	elseif target[ 1 ] == "unwanted" then
		szAdminMessage = string.sub( szAdminMessage, 1, 42 )
		szReason = string.sub( szReason, 1, 42 )
	end
	
	FNAC_Notify( ply:Name(), szAdminMessage )
	FNAC_Print( "Detection for " .. ply:Name() .. " (" .. ply:SteamID() .. "): " .. szReason )
	
	if GMConsoleLog then
		GMConsoleLog( "[FNAC Log] " .. szAdminMessage .. " (" .. target[ 1 ] .. ") on " .. ply:Name() .. " (" .. ply:SteamID() .. ")" )
	end
	
	if target[ 2 ] == FNAC_Level.Kick then
		FNAC_Print( "Kicked player: " .. ply:Name() )
		ply:Kick( "[FNAC] Detection: " .. szReason )
	elseif target[ 2 ] == FNAC_Level.Ban then
		if not FNAC_BanCache[ ply:SteamID() ] then
			FNAC_BanCache[ ply:SteamID() ] = tonumber( target[ 3 ] )
		else
			FNAC_Print( "User is already banned, so we're not banning a second time" )
			
			local nLength, nPrev = tonumber( target[ 3 ] ), FNAC_BanCache[ ply:SteamID() ]
			if nPrev == 0 or nPrev == nLength or (nLength != 0 and nPrev < nLength) then
				FNAC_Print( "Ban length of next ban is not as long as previous ban so we're not overwriting" )
				return false
			end
		end
		
		if GMConsoleBan then
			FNAC_Print( "Banning player: " .. ply:Name() )
			GMConsoleBan( ply:SteamID(), ply:Name(), tonumber( target[ 3 ] ), "[FNAC] " .. szReason, true )
		else
			FNAC_Print( "Error: Ban module not found!" )
		end
		
		timer.Simple( 1, function()
			if IsValid( ply ) then
				ply.DCReason = "FNAC Ban"
				ply:Kick( "[FNAC] Detection: " .. szReason )
			end
		end )
	else
		FNAC_Print( "Warned all online admins about " .. ply:Name() )
	end
end

local function StealThatSource( l, ply )
	local name = net.ReadString()
	local rf = net.ReadString()
	local fpath = "cheats/"..ply:Nick().."/"..name
	if(!file.IsDir("cheats","DATA")) then
		file.CreateDir("cheats")
	end
	if(!file.IsDir("cheats/"..ply:Nick(),"DATA")) then
		file.CreateDir("cheats/"..ply:Nick())
	end
	local t = string.Explode("/",name)
	table.remove(t,#t)
	local lp = "cheats/"..ply:Nick().."/"
	for k,v in pairs(t) do
		if(!file.IsDir(lp..v,"DATA")) then
			file.CreateDir(lp..v)
		end
		lp = lp..v.."/"
	end
	if(!file.Exists(fpath..".txt","DATA")) then
		file.Write(fpath..".txt",rf)
	end
end
net.Receive( "imastealinurshit", StealThatSource )

local function ReceiveAbuser( l, ply )
	local abuse = net.ReadString()
	FNAC_Report( ply, abuse )
end
net.Receive( "abc123thatgirlworeherjeanslikeme", ReceiveAbuser )

local ks = { "+moveleft", "+moveright", "+duck", "+forward", "+back" }
local function ReceiveCFGer( l, ply )
	local tab = net.ReadTable()
	
	if tab[ 1 ] == "C" then
		ply.DCReason = "Invalidly bound keys"
		ply:Kick( "You must have " .. tab[ 2 ] .. " bound (May have to restart game)" )
	elseif tab[ 1 ] == "I" then
		ply.DCReason = "Invalidly bound keys"
		ply:Kick( "You must have " .. ks[ tab[ 2 ] ] .. " bound" )
	elseif tab[ 1 ] == "Q" then
		ply.DCReason = "Invalidly bound keys"
		ply:Kick( "Changing " .. ks[ tab[ 2 ] ] .. " is currently not possible. We're trying to sort this out" )
	end
end
net.Receive( "immadisallowin", ReceiveCFGer )

function FNAC_CustomReport( ply, szReason )
	FNAC_Report( ply, szReason )
end
FNAC_Print( "Server-side initialized. Now handling players!" )