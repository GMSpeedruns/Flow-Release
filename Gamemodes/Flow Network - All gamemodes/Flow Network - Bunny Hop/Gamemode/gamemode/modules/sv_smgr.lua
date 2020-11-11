-- Strafe Sync Manager API initialization and setting of defaults on configurable variables
-- By Gravious, initially created for LifePunch

SMgrAPI = SMgrAPI or {}
SMgrAPI.Debugging = false
SMgrAPI.Protocol = "SMgrAPI"
SMgrAPI.DefaultDetail = 1
SMgrAPI.ViewDetail = 7
SMgrAPI.MaxDetail = 12
SMgrAPI.AcceptableLimit = 5000

util.AddNetworkString( SMgrAPI.Protocol )

local Monitored = {}
local MonitorAngle = {}

local SyncTotal = {}
local SyncAlignA = {}
local SyncAlignB = {}

local StateArchive = {}

local S1, S2, S3, S4, S5 = _C.Style.Normal, _C.Style.Legit, _C.Style["Easy Scroll"], _C.Style.Bonus, _C.Style.Practice
local function IsValidStyle( SX ) if SX == S1 or SX == S2 or SX == S3 or SX == S4 or SX == S5 then return true else return false end end

function SMgrAPI:Monitor( ply, bTarget )
	Monitored[ ply ] = bTarget or not Monitored[ ply ]
	
	MonitorAngle[ ply ] = ply:EyeAngles().y
	SyncTotal[ ply ] = 0
	SyncAlignA[ ply ] = 0
	SyncAlignB[ ply ] = 0
	
	return Monitored[ ply ]
end

function SMgrAPI:AdminMonitorToggle( ply )
	if Monitored[ ply ] and ply.SyncDisplay then
		return "still user monitored"
	end
	
	return SMgrAPI:Monitor( ply ) and "monitored" or "not monitored"
end

function SMgrAPI:ToggleSyncState( ply )
	if Monitored[ ply ] then
		if not ply.SyncDisplay then
			ply.SyncDisplay = ""
			SMgrAPI:ResetStatistics( ply )
		else
			ply.SyncDisplay = nil
			SMgrAPI:RemovePlayer( ply )
		end
	else
		SMgrAPI:Monitor( ply, true )
		ply.SyncDisplay = ""
	end
	
	Core:Send( ply, "Print", { "General", Lang:Get( "PlayerSyncStatus", { Monitored[ ply ] and "now" or "no longer" } ) } )
end

function SMgrAPI:ResetStatistics( ply )
	if Monitored[ ply ] then
		MonitorAngle[ ply ] = ply:EyeAngles().y
		SyncTotal[ ply ] = 0
		SyncAlignA[ ply ] = 0
		SyncAlignB[ ply ] = 0
	end
end

function SMgrAPI:RemovePlayer( ply )
	if IsValid( ply ) and Monitored[ ply ] then
		StateArchive[ ply:SteamID() ] = self:GetDataLine( ply, 0 )
		
		Monitored[ ply ] = nil
		MonitorAngle[ ply ] = nil
		SyncTotal[ ply ] = nil
		SyncAlignA[ ply ] = nil
		SyncAlignB[ ply ] = nil
	end
end

function SMgrAPI:GetFinishingSync( ply )
	if ply.SyncDisplay and IsValidStyle( ply.Style ) then
		return SMgrAPI:GetSync( ply, SMgrAPI.DefaultDetail )
	end
end

function SMgrAPI:GetSync( ply, nRound )
	if not Monitored[ ply ] then
		return "N/A"
	elseif SyncTotal[ ply ] == 0 then
		return 0.0
	end

	return math.Round( (SyncAlignA[ ply ] / SyncTotal[ ply ]) * 100.0, nRound or SMgrAPI.DefaultDetail )
end

function SMgrAPI:GetSyncEx( ply, nRound )
	if not Monitored[ ply ] then
		return "N/A"
	elseif SyncTotal[ ply ] == 0 then
		return 0.0
	end

	return math.Round( (SyncAlignB[ ply ] / SyncTotal[ ply ]) * 100.0, nRound or SMgrAPI.DefaultDetail )
end

function SMgrAPI:GetFrames( ply )
	if not Monitored[ ply ] then
		return "N/A"
	else
		return SyncTotal[ ply ]
	end
end

function SMgrAPI:IsRealistic( ply )
	return Monitored[ ply ] and SyncTotal[ ply ] > SMgrAPI.AcceptableLimit or false
end

function SMgrAPI:HasConfig( ply, bString )
	if Monitored[ ply ] then
		local SyncA, SyncB = self:GetSync( ply, SMgrAPI.MaxDetail ), self:GetSyncEx( ply, SMgrAPI.MaxDetail )
		return (SyncA == SyncB and SyncA + SyncB > 0 and self:IsRealistic( ply )) and (bString and "Yes" or true) or (bString and "No" or false)
	else
		return (bString and "No data" or false)
	end
end

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

function SMgrAPI:GetDataLine( ply, nID )
	if IsValid( ply ) then
		return { nID, ply:Name(), ply:SteamID(), self:GetSync( ply, SMgrAPI.ViewDetail ), self:GetSyncEx( ply, SMgrAPI.ViewDetail ), self:GetFrames( ply ), Monitored[ ply ] and "Yes" or "No", self:HasConfig( ply, true ), self:HasHack( ply, true ) }
	end
end

function SMgrAPI:SendSyncData( ply, data )
	Core:Send( ply, "Admin", { "Raw", data } )
end

function SMgrAPI:SendSyncPlayer( ply, data )
	local viewers = ply.Watchers or {}
	table.insert( viewers, ply )
	Core:Send( viewers, "Client", { "Display", data } )
end

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


function SMgrAPI.Console( op, szCmd, varArgs )
	if not IsValid( op ) and not op.Name and not op.Team then
		if szCmd != "smgr" then return end
		
		local szSub = tostring( varArgs[1] )
		if szSub == "dump" then
			SMgrAPI:DumpState()
		else
			print( "[SMgrAPI] The command '" .. szSub .. "' is invalid!" )
			print( "[SMgrAPI] All available commands are: dump" )
		end
	end
end
concommand.Add( "smgr", SMgrAPI.Console )


local function DistributeStatistics()
	for _,a in pairs( player.GetHumans() ) do
		if not a.Spectating then
			if a.SyncDisplay and IsValidStyle( a.Style ) then
				local szText = "Sync: " .. SMgrAPI:GetSync( a, SMgrAPI.DefaultDetail ) .. "%"
				if szText != a.SyncDisplay then
					SMgrAPI:SendSyncPlayer( a, szText )
					a.SyncDisplay = szText
				end
				
				a.SyncVisible = true
			elseif a.SyncVisible then
				SMgrAPI:SendSyncPlayer( a, nil )
				a.SyncVisible = nil
			end
		else
			if Admin:CanAccess( a, Admin.Level.Admin ) then
				local target = a:GetObserverTarget()
				if not IsValid( target ) then continue end
				
				local m = Monitored[ target ]
				if m then
					local data = {
						"Player: " .. target:Name(),
						"Sync A: " .. SMgrAPI:GetSync( target, SMgrAPI.ViewDetail ) .. "%",
						"Sync B: " .. SMgrAPI:GetSyncEx( target, SMgrAPI.ViewDetail ) .. "%",
						"Frames: " .. SMgrAPI:GetFrames( target ),
						"Possible config: " .. SMgrAPI:HasConfig( target, true ),
						"Possible hacks: " .. SMgrAPI:HasHack( target, true )
					}
					
					SMgrAPI:SendSyncData( a, data )
				else
					SMgrAPI:SendSyncData( a, {} )
				end
			end
		end
	end
end
timer.Create( "SyncDistribute", 2, 0, DistributeStatistics )


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