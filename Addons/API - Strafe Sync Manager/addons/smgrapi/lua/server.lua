-- Strafe Sync Manager API initialization and setting of defaults on configurable variables
SMgrAPI = SMgrAPI or {}
SMgrAPI.Debugging = false
SMgrAPI.Protocol = "SMgrAPI"
SMgrAPI.DefaultDetail = 1
SMgrAPI.ViewDetail = 7
SMgrAPI.MaxDetail = 12
SMgrAPI.AcceptableLimit = 5000

util.AddNetworkString( SMgrAPI.Protocol )

-- Local variables are at the top so they can be accessed by the global functions
local Monitored = {}
local MonitorAngle = {}

local SyncTotal = {}
local SyncAlignA = {}
local SyncAlignB = {}

local StateArchive = {}

-- Sets the players' monitor status. Provide the target with (bool)bTarget. If none provided, function will toggle
function SMgrAPI:Monitor( ply, bTarget )
	Monitored[ ply ] = bTarget or not Monitored[ ply ]
	
	-- Default variables are set so that no errors arise (This is done once so we get better performance later)
	MonitorAngle[ ply ] = ply:EyeAngles().y
	SyncTotal[ ply ] = 0
	SyncAlignA[ ply ] = 0
	SyncAlignB[ ply ] = 0
	
	if SMgrAPI.Debugging then
		print( "[SMgrAPI Debug] " .. ply:Name() .. "'s monitor status is now: " .. tostring( Monitored[ ply ] ) )
	end

	return Monitored[ ply ]
end

-- Resets the captured data for the player and essentially gives them a blank measurement again
function SMgrAPI:ResetStatistics( ply )
	if Monitored[ ply ] then
		MonitorAngle[ ply ] = ply:EyeAngles().y
		SyncTotal[ ply ] = 0
		SyncAlignA[ ply ] = 0
		SyncAlignB[ ply ] = 0
		
		if SMgrAPI.Debugging then
			print( "[SMgrAPI Debug] " .. ply:Name() .. "'s collected monitoring data has been reset" )
		end
	end
end

-- Called right before the player disconnects
function SMgrAPI:RemovePlayer( ply )
	if IsValid( ply ) and Monitored[ ply ] then
		StateArchive[ ply:SteamID() ] = self:GetDataLine( ply, 0 )
		
		Monitored[ ply ] = nil
	end
	
	MonitorAngle[ ply ] = nil
	SyncTotal[ ply ] = nil
	SyncAlignA[ ply ] = nil
	SyncAlignB[ ply ] = nil
end

-- This function returns the regular sync in a percentage with the supplied amount of rounding (Default is (int)1, which results in: 88.5%)
function SMgrAPI:GetSync( ply, nRound )
	if not Monitored[ ply ] then
		return "N/A"
	elseif SyncTotal[ ply ] == 0 then
		return 0.0
	end

	return math.Round( (SyncAlignA[ ply ] / SyncTotal[ ply ]) * 100.0, nRound or SMgrAPI.DefaultDetail )
end

-- This function returns the extra side speed sync in a percentage with the supplied amount of rounding (Default is (int)1, which results in: 88.5%)
function SMgrAPI:GetSyncEx( ply, nRound )
	if not Monitored[ ply ] then
		return "N/A"
	elseif SyncTotal[ ply ] == 0 then
		return 0.0
	end

	return math.Round( (SyncAlignB[ ply ] / SyncTotal[ ply ]) * 100.0, nRound or SMgrAPI.DefaultDetail )
end

-- This function returns the total amount of frames that were evaluated by the system
function SMgrAPI:GetFrames( ply )
	if not Monitored[ ply ] then
		return "N/A"
	else
		return SyncTotal[ ply ]
	end
end

-- Indicates whether or not the player is at a realistic level of measurement
function SMgrAPI:IsRealistic( ply )
	return Monitored[ ply ] and SyncTotal[ ply ] > SMgrAPI.AcceptableLimit or false
end

-- This function will show if a user uses a movement config to match up A and D perfectly, just for ease of use; returns in boolean by default (Provide bString for String output)
function SMgrAPI:HasConfig( ply, bString )
	if Monitored[ ply ] then
		local SyncA, SyncB = self:GetSync( ply, SMgrAPI.MaxDetail ), self:GetSyncEx( ply, SMgrAPI.MaxDetail )
		return (SyncA == SyncB and SyncA + SyncB > 0 and self:IsRealistic( ply )) and (bString and "Yes" or true) or (bString and "No" or false)
	else
		return (bString and "No data" or false)
	end
end

-- This function shows whether or not a user uses a strafe hack (Note: This is not always the truth, but only a high probability); returns in boolean by default (Provide bString for String output)
function SMgrAPI:HasHack( ply, bString )
	if Monitored[ ply ] then
		local SyncA, SyncB = self:GetSync( ply, SMgrAPI.MaxDetail ), self:GetSyncEx( ply, SMgrAPI.MaxDetail )

		if (SyncA > 97 or SyncB > 97) and math.abs( SyncA - SyncB ) > 70 and self:IsRealistic( ply ) then
			return (bString and "Yes" or true)
		end
		
		if SyncA < 5 and SyncB < 5 and self:IsRealistic( ply ) then
			return (bString and "Yes" or true)
		end

		return (bString and "No" or false)
	else
		return (bString and "No data" or false)
	end
end

-- This function will be used for easy display of data on the GUI
function SMgrAPI:GetDataLine( ply, nID )
	if IsValid( ply ) then
		return { nID, ply:Name(), ply:SteamID(), self:GetSync( ply, SMgrAPI.ViewDetail ), self:GetSyncEx( ply, SMgrAPI.ViewDetail ), self:GetFrames( ply ), Monitored[ ply ] and "Yes" or "No", self:HasConfig( ply, true ), self:HasHack( ply, true ) }
	end
end

-- This function is mostly for debugging purposes but can be used to log data to console
function SMgrAPI:DumpState()
	print( "[SMgrAPI] Dump initiated" )
	
	for ply,bMonitored in pairs( Monitored ) do
		if IsValid( ply ) and bMonitored then
			print( "\nData for player " .. ply:Name() )
			print( "> Sync A: " .. self:GetSync( ply, SMgrAPI.ViewDetail ) )
			print( "> Sync B: " .. self:GetSyncEx( ply, SMgrAPI.ViewDetail ) )
			print( "> Total frames monitored: " .. SyncTotal[ ply ] )
		end
	end
	
	for sid,data in pairs( StateArchive ) do
		print( "\nData of disconnected player " .. data[ 2 ] .. " (" .. sid .. ")" )
		print( "> Sync A: " .. data[ 4 ] )
		print( "> Sync B: " .. data[ 5 ] )
		print( "> Total frames monitored: " .. data[ 6 ] )
	end
	
	print( "\n[SMgrAPI] End of data dump" )
end

-- This function will open a pop-up box on the players' screen
function SMgrAPI:PopSend( ply, szText )
	self:NetSend( ply, "OpenBox", { szText } )
end

-- This function is primarily used by SMgrAPI itself to easily send data to connected players
function SMgrAPI:NetSend( ply, szIdentifier, tabData )
	net.Start( SMgrAPI.Protocol )
	net.WriteString( szIdentifier )
	net.WriteTable( tabData )
	net.Send( ply )
end


---							---
---		Console			---
---							---

-- Available commands
-- > monitor [String: Player name] [Boolean: Target value ~ Default is toggle]
-- > monitorall [Boolean: Target value ~ Default is on]
-- > dump
--	> reset [String: Player name]
--	> resetall

-- All SMgrAPI console commands are handled here
function SMgrAPI.Console( op, szCmd, varArgs )
	if not IsValid( op ) and not op.Name and not op.Team then
		if szCmd != "smgr" then return end
		
		local szSub = tostring( varArgs[1] )
		if szSub == "monitor" then
			if not varArgs[2] then return end
			
			local bTarget = nil
			if varArgs[3] then
				bTarget = varArgs[3] == "true" and true or false
			end
			
			for _,ply in pairs( player.GetHumans() ) do
				if string.find( tostring( varArgs[2] ), ply:Name(), 1, true ) then
					local bMonitored = SMgrAPI:Monitor( ply, bTarget )
					print( "[SMgrAPI] Console changed monitor status of " .. ply:Name() .. " to " .. tostring( bMonitored ) )
				end
			end
		elseif szSub == "monitorall" then
			local bTarget = true
			if varArgs[1] then
				bTarget = varArgs[1] == "false" and false or nil
			end
		
			for _,ply in pairs( player.GetHumans() ) do
				SMgrAPI:Monitor( ply, bTarget )
			end
			
			print( "[SMgrAPI] All players are now " .. (bTarget and "being" or "no longer being") .. " monitored." )
		elseif szSub == "reset" then
			if not varArgs[2] then return end
			
			for _,ply in pairs( player.GetHumans() ) do
				if string.find( tostring( varArgs[2] ), ply:Name(), 1, true ) then
					SMgrAPI:ResetStatistics( ply )
					print( "[SMgrAPI] " .. ply:Name() .. "'s collected monitoring data has been reset" )
				end
			end
		elseif szSub == "resetall" then
			for ply,bMonitored in pairs( Monitored ) do
				if IsValid( ply ) and bMonitored then
					SMgrAPI:ResetStatistics( ply )
				end
			end
			
			print( "[SMgrAPI] All collected monitoring data has been reset" )
		elseif szSub == "dump" then
			SMgrAPI:DumpState()
		else
			print( "[SMgrAPI] The command '" .. szSub .. "' is invalid!" )
			print( "[SMgrAPI] All available commands are: monitor, monitorall, reset, resetall, dump" )
		end
	elseif IsValid( op ) and szCmd == "smgr" then
		if not op:IsAdmin() and not SMgrAPI.Debugging then return end -- To-Do [By LP]: Use permissions here to make sure only selected players can use it
		
		local szSub = tostring( varArgs[1] )
		if szSub == "open" then -- To-Do [By LP]: Currently the only way to open the GUI is by using this console command (smgr open); we might want to change that, even though it's fine by me; secure this if you want
			SMgrAPI:NetSend( op, "OpenGUI", {} )
		elseif szSub == "load" then
			local varCache, nCounter = {}, 1
		
			for ply,bMonitored in pairs( Monitored ) do
				if not IsValid( ply ) then continue end
				local line = SMgrAPI:GetDataLine( ply, nCounter )
				
				if line then
					table.insert( varCache, SMgrAPI:GetDataLine( ply, nCounter ) )
					nCounter = nCounter + 1
				end
			end
			
			SMgrAPI:NetSend( op, "SetRange", varCache )
		elseif szSub == "warn" then
			local SteamID = tostring( varArgs[2] )
			
			print( "This player should be warned: " .. SteamID ) -- To-Do [By LP]: Warn Player functionality (Within LP Base / Core)
		elseif szSub == "update" then
			local SteamID = tostring( varArgs[2] )
			
			for _,ply in pairs( player.GetHumans() ) do
				if ply:SteamID() == SteamID then
					return SMgrAPI:NetSend( op, "UpdateItem", SMgrAPI:GetDataLine( ply ) )
				end
			end
			
			SMgrAPI:PopSend( op, "The player with Steam ID " .. SteamID .. " is no longer online." )
		elseif szSub == "toggle" then
			local SteamID = tostring( varArgs[2] )
			
			for _,ply in pairs( player.GetHumans() ) do
				if ply:SteamID() == SteamID then
					local bMonitored = SMgrAPI:Monitor( ply )
					return SMgrAPI:PopSend( op, ply:Name() .. " (" .. SteamID .. ") is " .. (bMonitored and "now" or "no longer") .. " being monitored." )
				end
			end
			
			SMgrAPI:PopSend( op, "The player with Steam ID " .. SteamID .. " is no longer online." )
		elseif szSub == "addnew" then
			local SteamID = tostring( varArgs[2] )
			
			for _,ply in pairs( player.GetHumans() ) do
				if ply:SteamID() == SteamID then
					if not Monitored[ ply ] then
						SMgrAPI:Monitor( ply, true )
						return SMgrAPI:PopSend( op, ply:Name() .. " (" .. SteamID .. ") is now being monitored!" )
					else
						return SMgrAPI:PopSend( op, ply:Name() .. " (" .. SteamID .. ") is already being monitored!" )
					end
				end
			end
			
			SMgrAPI:PopSend( op, "No online players found with this Steam ID: " .. SteamID )
		end
	end
end
concommand.Add( "smgr", SMgrAPI.Console )


---							---
---		Detection		---
---							---

-- Localized functions - they're called very often
local function norm( i ) if i > 180 then i = i - 360 elseif i < -180 then i = i + 360 end return i end
local fb = bit.band

local function MonitorInputSync( ply, data )
	if not Monitored[ ply ] then return end

	local buttons = data:GetButtons()
	local ang = data:GetAngles().y

	if not ply:IsFlagSet( FL_ONGROUND + FL_INWATER ) and ply:GetMoveType() != MOVETYPE_LADDER then
		local difference = norm( ang - MonitorAngle[ ply ] )
		
		if difference > 0 then
			SyncTotal[ ply ] = SyncTotal[ ply ] + 1
				
			if (fb( buttons, IN_MOVELEFT ) > 0) and not (fb( buttons, IN_MOVERIGHT ) > 0) then
				SyncAlignA[ ply ] = SyncAlignA[ ply ] + 1
			end
			if data:GetSideSpeed() < 0 then
				SyncAlignB[ ply ] = SyncAlignB[ ply ] + 1
			end
		elseif difference < 0 then
			SyncTotal[ ply ] = SyncTotal[ ply ] + 1

			if (fb( buttons, IN_MOVERIGHT ) > 0) and not (fb( buttons, IN_MOVELEFT ) > 0) then
				SyncAlignA[ ply ] = SyncAlignA[ ply ] + 1
			end
			if data:GetSideSpeed() > 0 then
				SyncAlignB[ ply ] = SyncAlignB[ ply ] + 1
			end
		end
	end
	
	MonitorAngle[ ply ] = ang
end
hook.Add( "SetupMove", "MonitorInputSync", MonitorInputSync )

local function MonitorDisconnect( ply )
	SMgrAPI:RemovePlayer( ply )
end
hook.Add( "PlayerDisconnected", "MonitorDisconnect", MonitorDisconnect )