local PLAYER = FindMetaTable( "Player" )
local CT = CurTime
local CAPVEL = 280

Timer = {}
Timer.Multiplier = 1
Timer.BonusMultiplier = 1
Timer.Options = 0

local function ValidTimer( ply, bBonus )
	if ply:IsBot() then return false end
	if ply.Style == _C.Style.Practice then return false end
	
	if bBonus then
		if ply.Style != _C.Style.Bonus then return false end else
		if ply.Style == _C.Style.Bonus then return false end
	end
	
	return true
end


function PLAYER:StartTimer()
	if not ValidTimer( self ) then return end
	
	local vel2d = self:GetVelocity():Length2D()
	if vel2d > CAPVEL and not (bit.band( Timer.Options, Zones.Options.NoStartLimit ) > 0) then
		self:SetLocalVelocity( Vector( 0, 0, 0 ) )
		Player:SpawnChecks( self )
		return Core:Send( self, "Print", { "Bhop Timer", Lang:Get( "ZoneSpeed", { math.ceil( vel2d ) .. " u/s" } ) } )
	end

	self.Tn = CT()
	
	Core.Util:SetPlayerJumps( self, 0 )
	Core:Send( self, "Timer", { "Start", self.Tn } )
	
	if self.Style == _C.Style.Legit and self.LegitTopSpeed then
		if self.LegitTopSpeed != 480 then
			self:SetLegitSpeed( 480 )
		end
	end
	
	if Bot:IsRecorded( self ) then
		self.BotFull = true
		Bot:CleanRecording( self )
		Bot:SetActive( self, true )
	else
		self.BotFull = nil
		Bot:SetActive( self, nil )
	end
	
	Spectator:PlayerRestart( self )
	SMgrAPI:ResetStatistics( self )
end

function PLAYER:ResetTimer()
	Core:Send( self, "Timer", { "Restart" } )

	if not ValidTimer( self ) then return end
	if not self.Tn then return end
	
	self.Tn = nil
	self.TnF = nil
	
	Bot:SetActive( self, nil )
	Spectator:PlayerRestart( self )
	SMgrAPI:ResetStatistics( self )
	
	Core:Send( self, "Timer", { "Start", self.Tn } )
end

function PLAYER:StopTimer()
	if not ValidTimer( self ) then return end
	self.TnF = CT()
	
	Bot:SetActive( self, nil )
	
	Core:Send( self, "Timer", { "Finish", self.TnF } )
	Timer:Finish( self, self.TnF - self.Tn )
end


function PLAYER:BonusStart()
	if not ValidTimer( self, true ) then return end
	
	local vel2d = self:GetVelocity():Length2D()
	if vel2d > CAPVEL then
		self:SetLocalVelocity( Vector( 0, 0, 0 ) )
		Player:SpawnChecks( self )
		return Core:Send( self, "Print", { "Bhop Timer", Lang:Get( "ZoneSpeed", { math.ceil( vel2d ) .. " u/s" } ) } )
	end
	
	self.Tb = CT()
	
	Core.Util:SetPlayerJumps( self, 0 )
	Core:Send( self, "Timer", { "Start", self.Tb } )
	
	if Bot:IsRecorded( self ) then
		self.BotFull = true
		Bot:CleanRecording( self )
		Bot:SetActive( self, true )
	else
		self.BotFull = nil
		Bot:SetActive( self, nil )
	end
	
	Spectator:PlayerRestart( self )
	SMgrAPI:ResetStatistics( self )
end

function PLAYER:BonusReset()
	if not ValidTimer( self, true ) then return end
	if not self.Tb then return end
	
	self.Tb = nil
	self.TbF = nil
	
	Bot:SetActive( self, nil )
	Spectator:PlayerRestart( self )
	SMgrAPI:ResetStatistics( self )
	
	Core:Send( self, "Timer", { "Start", self.Tb } )
end

function PLAYER:BonusStop()
	if not ValidTimer( self, true ) then return end
	self.TbF = CT()
	
	Bot:SetActive( self, nil )
	
	Core:Send( self, "Timer", { "Finish", self.TbF } )
	Timer:Finish( self, self.TbF - self.Tb )
end

function PLAYER:StopAnyTimer()
	if self:IsBot() then return false end
	if self.Style == _C.Style.Practice then return false end
	
	self.Tn = nil
	self.TnF = nil
	self.Tb = nil
	self.TbF = nil
	
	Bot:SetActive( self, nil )
	
	Core:Send( self, "Timer", { "Start" } )
	return true
end

function PLAYER:StartFreestyle()
	if not ValidTimer( self ) then return end
	
	if self.Style >= _C.Style.SW and self.Style <= _C.Style["A-Only"] then
		self.Freestyle = true
		Core:Send( self, "Timer", { "Freestyle", self.Freestyle } )
		Core:Send( self, "Print", { "Bhop Timer", Lang:Get( "StyleFreestyle", { "entered a", " All key combinations are now possible." } ) } )
	end
end

function PLAYER:StopFreestyle()
	if not ValidTimer( self ) then return end
	
	if self.Style >= _C.Style.SW and self.Style <= _C.Style["A-Only"] then
		self.Freestyle = nil
		Core:Send( self, "Timer", { "Freestyle", self.Freestyle } )
		Core:Send( self, "Print", { "Bhop Timer", Lang:Get( "StyleFreestyle", { "left the", "" } ) } )
	end
end

function PLAYER:SetLegitSpeed( nTop )
	if not ValidTimer( self ) then return end
	if self.Style != _C.Style.Legit then return end
	
	if not self.LegitTopSpeed or (self.LegitTopSpeed and self.LegitTopSpeed != nTop) then
		self.LegitTopSpeed = nTop

		Core.Util:SetPlayerLegit( self, nTop )
		Core:Send( self, "Timer", { "Legit", nTop } )
	end
end



function Timer:Finish( ply, nTime )
	local szMessage = ply.Style == _C.Style.Bonus and "StyleBonusFinish" or "TimerFinish"
	local nDifference = ply.Record > 0 and nTime - ply.Record or nil
	local szSlower = nDifference and (" (" .. (nDifference < 0 and "-" or "+") .. Timer:Convert( math.abs( nDifference ) ) .. ")") or ""
	local varSync, szSync = SMgrAPI:GetFinishingSync( ply ), ""
	if varSync then szSync = " (With " .. varSync .. "% Sync)" ply.LastSync = varSync end
	
	Core:Send( ply, "Print", { "Bhop Timer", Lang:Get( szMessage, { Timer:Convert( nTime ), szSlower, szSync } ) } )
	
	local OldRecord = ply.Record or 0
	if ply.Record != 0 and nTime >= ply.Record then return end
	
	ply.Record = nTime
	ply.SpeedRequest = ply.Style
	ply:SetNWFloat( "Record", ply.Record )

	Timer:AddRecord( ply, nTime, OldRecord )
end


-- Records

local RC = {
	[_C.Style.Normal] = { Total = 0, Count = 0, Average = 0 },
	[_C.Style.SW] = { Total = 0, Count = 0, Average = 0 },
	[_C.Style.HSW] = { Total = 0, Count = 0, Average = 0 },
	[_C.Style["W-Only"]] = { Total = 0, Count = 0, Average = 0 },
	[_C.Style["A-Only"]] = { Total = 0, Count = 0, Average = 0 },
	[_C.Style["Easy Scroll"]] = { Total = 0, Count = 0, Average = 0 },
	[_C.Style.Legit] = { Total = 0, Count = 0, Average = 0 },
	[_C.Style.Bonus] = { Total = 0, Count = 0, Average = 0 }
}

local TC = {
	[_C.Style.Normal] = {},
	[_C.Style.SW] = {},
	[_C.Style.HSW] = {},
	[_C.Style["W-Only"]] = {},
	[_C.Style["A-Only"]] = { Total = 0, Count = 0, Average = 0 },
	[_C.Style["Easy Scroll"]] = {},
	[_C.Style.Legit] = {},
	[_C.Style.Bonus] = {}
}

local IR = {}

local function GetAverage( nStyle )
	return RC[ nStyle ].Average
end

local function CalcAverage( nStyle )
	RC[ nStyle ].Average = RC[ nStyle ].Total / RC[ nStyle ].Count
end

local function PushTime( nStyle, nTime, nOld, bAvg )
	if nOld then
		RC[ nStyle ].Total = RC[ nStyle ].Total + (nTime - nOld)
	else
		RC[ nStyle ].Total = RC[ nStyle ].Total + nTime
		RC[ nStyle ].Count = RC[ nStyle ].Count + 1
	end
	
	if bAvg then CalcAverage( nStyle ) end
end

local function GetRecordCount( nStyle )
	return TC[ nStyle ] and #TC[ nStyle ] or 0
end

local function UpdateRecords( ply, nPos, nNew, nOld, data )
	local tab = { ply:SteamID(), data[ 1 ]["szPlayer"], nNew, Core:Null( data[ 1 ]["szDate"] ), nil }
	ply.SpeedPos = nPos
	
	if nOld == 0 then
		table.insert( TC[ ply.Style ], nPos, tab )
	else
		local nID = -1
		for id,sub in pairs( TC[ ply.Style ] ) do
			if sub[ 1 ] == tab[ 1 ] then
				nID = id
				break
			end
		end
		
		if nID >= 0 then
			table.remove( TC[ ply.Style ], nID )
			table.insert( TC[ ply.Style ], nPos, tab )
		else
			print( "A really odd error occurred. Please restart server immediately." )
		end
	end
end


function Timer:LoadRecords()
	for id,_ in pairs( RC ) do
		local Query = sql.Query( "SELECT SUM(nTime) AS nSum, COUNT(nTime) AS nCount, AVG(nTime) AS nAverage FROM game_times WHERE szMap = '" .. game.GetMap() .. "' AND nStyle = " .. id )
		
		RC[ id ].Total = Core:Assert( Query, "nSum" ) and tonumber( Query[1]["nSum"] ) or 0
		RC[ id ].Count = Core:Assert( Query, "nCount" ) and tonumber( Query[1]["nCount"] ) or 0
		RC[ id ].Average = Core:Assert( Query, "nAverage" ) and tonumber( Query[1]["nAverage"] ) or 0
	end

	local Map = sql.Query( "SELECT nMultiplier, nBonusMultiplier, nOptions FROM game_map WHERE szMap = '" .. game.GetMap() .. "'" )
	if Core:Assert( Map, "nMultiplier" ) then
		Timer.Multiplier = tonumber( Core:Null( Map[ 1 ]["nMultiplier"], 1 ) )
		Timer.BonusMultiplier = tonumber( Core:Null( Map[ 1 ]["nBonusMultiplier"], 1 ) )
		Timer.Options = tonumber( Core:Null( Map[ 1 ]["nOptions"], 0 ) )
	end
	
	for id,_ in pairs( TC ) do
		local Rec = sql.Query( "SELECT * FROM game_times WHERE szMap = '" .. game.GetMap() .. "' AND nStyle = " .. id .. " ORDER BY nTime ASC" )
		TC[ id ] = {}
		
		if Core:Assert( Rec, "szUID" ) then
			for _a,data in pairs( Rec ) do
				table.insert( TC[ id ], { data["szUID"], data["szPlayer"], tonumber( data["nTime"] ), Core:Null( data["szDate"] ), Core:Null( data["vData"] ) } )
			end
		end
	end
	
	for _,id in pairs( _C.Style ) do
		if TC[ id ] and TC[ id ][ 1 ] and TC[ id ][ 1 ][ 3 ] then
			IR[ id ] = tonumber( TC[ id ][ 1 ][ 3 ] )
		end
	end
	
	Zones:MapChecks()
end

function Timer:AddRecord( ply, nTime, nOld )
	local nAverage = GetAverage( ply.Style )

	local OldEntry = sql.Query( "SELECT nTime FROM game_times WHERE szMap = '" .. game.GetMap() .. "' AND szUID = '" .. ply:SteamID() .. "' AND nStyle = " .. ply.Style )
	if Core:Assert( OldEntry, "nTime" ) then
		PushTime( ply.Style, nTime, nOld, true )
		sql.Query( "UPDATE game_times SET szPlayer = " .. sql.SQLStr( ply:Name() ) .. ", nTime = " .. nTime .. ", szDate = '" .. Timer:GetDate() .. "' WHERE szMap = '" .. game.GetMap() .. "' AND szUID = '" .. ply:SteamID() .. "' AND nStyle = " .. ply.Style )
	else
		PushTime( ply.Style, nTime, nil, true )
		sql.Query( "INSERT INTO game_times VALUES ('" .. ply:SteamID() .. "', " .. sql.SQLStr( ply:Name() ) .. ", '" .. game.GetMap() .. "', " .. ply.Style .. ", " .. nTime .. ", 0, NULL, '" .. Timer:GetDate() .. "')" )
	end
	
	Timer:RecalculatePoints( ply.Style )
	Player:UpdateRank( ply )
	Player:AddScore( ply )
	
	local nID, szID = 1, ""
	local Rank = sql.Query( "SELECT t1.*, (SELECT COUNT(*) + 1 FROM game_times AS t2 WHERE szMap = '" .. game.GetMap() .. "' AND t2.nTime < t1.nTime AND nStyle = " .. ply.Style .. ") AS nRank FROM game_times AS t1 WHERE t1.szUID = '" .. ply:SteamID() .. "' AND t1.szMap = '" .. game.GetMap() .. "' AND t1.nStyle = " .. ply.Style )
	if Rank and Rank[ 1 ] and Rank[ 1 ]["nRank"] then
		nID = tonumber( Rank[ 1 ]["nRank"] )
	end
	
	UpdateRecords( ply, nID, nTime, nOld, Rank )
	Player:ReloadSubRanks( ply, nAverage )

	local Data = { "[" .. Core:StyleName( ply.Style ) .. "] ", "You" }
	local nRec = GetRecordCount( ply.Style )
	
	if nID <= 10 then
		if nOld == 0 then
			szID, Data[ 3 ], Data[ 4 ], Data[ 5 ] = "TimerWRFirst", "#" .. nID, Timer:Convert( nTime ), nID .. " / " .. nRec
		else
			szID, Data[ 3 ], Data[ 4 ], Data[ 5 ], Data[ 6 ] = "TimerWRNext", "#" .. nID, Timer:Convert( nTime ), Timer:Convert( nOld - nTime ), nID .. " / " .. nRec
		end
		
		Player:SetRankMedal( ply, nID )
	else
		if nOld == 0 then
			szID, Data[ 3 ], Data[ 4 ] = "TimerPBFirst", Timer:Convert( nTime ), nID .. " / " .. nRec
		else
			szID, Data[ 3 ], Data[ 4 ], Data[ 5 ] = "TimerPBNext", Timer:Convert( nTime ), Timer:Convert( nOld - nTime ), nID .. " / " .. nRec
		end
	end
	
	if nID == 1 then
		Timer:RecalculateInitial( ply.Style )
	end
	
	local p = Bot.PerStyle[ ply.Style ] or 0
	if p > 0 and nID <= p then
		Bot:SetWRPosition( ply.Style )
	end
	
	Core:Send( ply, "Timer", { "Record", nTime, nil, true } )
	Core:Send( ply, "Print", { "Bhop Timer", Lang:Get( szID, Data ) } )
	
	Data[ 2 ] = ply:Name()
	Core:Broadcast( "Print", { "Bhop Timer", Lang:Get( szID, Data ) }, ply )
	
	Bot:EndRun( ply, nTime, nID )
end

function Timer:AddSpeedData( ply, tab )
	if ply.Record and ply.Record > 0 and ply.SpeedRequest then
		local szData = Core.Util:TabToString( { math.floor( tab[ 1 ] ), math.floor( tab[ 2 ] ), Core.Util:GetPlayerJumps( ply ), ply.LastSync or 0 } )
		sql.Query( "UPDATE game_times SET vData = '" .. szData .. "' WHERE szUID = '" .. ply:SteamID() .. "' AND szMap = '" .. game.GetMap() .. "' AND nStyle = " .. ply.SpeedRequest )

		if ply.SpeedPos and ply.SpeedPos > 0 and TC[ ply.Style ] and TC[ ply.Style ][ ply.SpeedPos ] and TC[ ply.Style ][ ply.SpeedPos ][ 1 ] == ply:SteamID() then
			TC[ ply.Style ][ ply.SpeedPos ][ 5 ] = Core:Null( szData )
		end
	end
end

function Timer:AddPlays()
	Timer.PlayCount = 1
	
	local Check = sql.Query( "SELECT szMap, nPlays FROM game_map WHERE szMap = '" .. game.GetMap() .. "'" )
	if Core:Assert( Check, "szMap" ) then
		Timer.PlayCount = tonumber( Check[ 1 ]["nPlays"] ) + 1
		sql.Query( "UPDATE game_map SET nPlays = nPlays + 1 WHERE szMap = '" .. game.GetMap() .. "'" )
	end
end

function Timer:RecalculatePoints( nStyle )
	local nMult = Timer:GetMultiplier( nStyle )
	sql.Query( "UPDATE game_times SET nPoints = " .. nMult .. " * (" .. GetAverage( nStyle ) .. " / nTime) WHERE szMap = '" .. game.GetMap() .. "' AND nStyle = " .. nStyle )
	
	local nFourth, nDouble = nMult / 4, nMult * 2
	sql.Query( "UPDATE game_times SET nPoints = " .. nDouble .. " WHERE szMap = '" .. game.GetMap() .. "' AND nStyle = " .. nStyle .. " AND nPoints > " .. nDouble )
	sql.Query( "UPDATE game_times SET nPoints = " .. nFourth .. " WHERE szMap = '" .. game.GetMap() .. "' AND nStyle = " .. nStyle .. " AND nPoints < " .. nFourth )
end

function Timer:RecalculateInitial( id )
	if TC[ id ] and TC[ id ][ 1 ] and TC[ id ][ 1 ][ 3 ] then
		IR[ id ] = tonumber( TC[ id ][ 1 ][ 3 ] )
	end
	
	Core:Broadcast( "Timer", { "Initial", IR } )
end

function Timer:SendInitialRecords( ply )
	Core:Send( ply, "Timer", { "Initial", IR } )
end

function Timer:GetRecordID( nTime, nStyle )
	if TC and TC[ nStyle ] then
		for pos,data in pairs( TC[ nStyle ] ) do
			if nTime <= data[ 3 ] then
				return pos
			end
		end
		
		return #TC[ nStyle ] + 1
	else
		return 0
	end
end

function Timer:GetRecordList( nStyle, nPage )
	local tab = {}
	local a = _C.PageSize * nPage - _C.PageSize
	
	for i = 1, _C.PageSize do
		i = i + a
		if TC[ nStyle ][ i ] then
			tab[ i ] = TC[ nStyle ][ i ]
		end
	end
	
	return tab
end

function Timer:GetRecordCount( nStyle )
	return RC[ nStyle ].Count or 0
end

function Timer:GetAverage( nStyle )
	return GetAverage( nStyle )
end

function Timer:GetMultiplier( nStyle )
	if nStyle == _C.Style.Bonus then return Timer.BonusMultiplier end
	if nStyle != _C.Style.Practice then return Timer.Multiplier end
	
	return 0
end

function Timer:GetPointsForMap( nTime, nStyle )
	if nTime == 0 then return 0 end
	
	local m = Timer:GetMultiplier( nStyle )
	local p = m * (GetAverage( nStyle ) / nTime)
	
	if p > m * 2 then p = m * 2
	elseif p < m / 4 then p = m / 4
	end
	
	return p
end

function Timer:SendWRList( ply, nPage, nStyle, szMap )
	if szMap then
		Player:SendRemoteWRList( ply, szMap, nStyle, nPage, true )
	else
		Core:Send( ply, "GUI_Update", { "WR", { 4, Timer:GetRecordList( nStyle, nPage ), nPage, Timer:GetRecordCount( nStyle ) } } )
	end
end


-- Checkpoints
local function CPGetKeys( ply )
	local szStr = ply:Crouching() and " C" or ""
	if ply:KeyDown( IN_MOVELEFT ) then
		szStr = szStr .. " A"
	elseif ply:KeyDown( IN_MOVERIGHT ) then
		szStr = szStr .. " D"
	end
	
	return szStr
end

function Timer.CPProcess( ply, args )
	if ply.Spectating then
		return Core:Send( ply, "Print", { "General", "You can't use this feature while in spectator" } )
	end

	if ply.Style != _C.Style.Practice then
		Command:RemoveLimit( ply )
		Command.Style( ply, nil, { _C.Style.Practice } )
	end
	
	if not ply.Checkpoints then
		ply.Checkpoints = {}
	end
	
	if args.Key == "cp" or args.Key == "cpmenu" then	
		Core:Send( ply, "Checkpoints", { "Open" } )
	elseif args.Key == "cpload" then
		Timer:CPHandleCallback( ply, 8 )
	elseif args.Key == "cpsave" then
		 Timer:CPHandleCallback( ply, 8, nil, nil, true )
	end
end

function Timer:CPHandleCallback( ply, nID, bDelay, bDelete, bForceSave )
	if ply.Style != _C.Style.Practice or ply.Spectating then return end
	if ply.CPTeleport then return end
	
	if nID == 1 then
		if bDelete then
			return Core:Send( ply, "Print", { "Bhop Timer", "You can't delete the most recent checkpoint like this." } )
		end
	
		if #ply.Checkpoints > 0 then
			local recent = { nil, -1 }
			for _,c in pairs( ply.Checkpoints ) do
				if c[ 4 ] > recent[ 2 ] then
					recent = { c, c[ 4 ] }
				end
			end
				
			if recent[ 1 ] then
				local cp = recent[ 1 ]
				
				if bDelay then
					ply.CPTeleport = true
					Core:Send( ply, "Checkpoints", { "Delay" } )
					timer.Simple( 1.5, function()
						ply.CPTeleport = nil
						if not IsValid( ply ) or not cp then return end
						if ply.Style != _C.Style.Practice then return end
						
						ply:SetPos( cp[ 1 ] )
						ply:SetEyeAngles( cp[ 2 ] )
						ply:SetLocalVelocity( cp[ 3 ] )
					end )
				else
					ply:SetPos( cp[ 1 ] )
					ply:SetEyeAngles( cp[ 2 ] )
					ply:SetLocalVelocity( cp[ 3 ] )
				end
			end
		else
			Core:Send( ply, "Print", { "Bhop Timer", "No checkpoints found. Set one first!" } )
		end
	else
		if not ply.Checkpoints[ nID ] or bForceSave then
			ply.Checkpoints[ nID ] = { ply:GetPos(), ply:EyeAngles(), ply:GetVelocity(), CurTime() }
			Core:Send( ply, "Checkpoints", { "Update", nID, nil, string.format( "%.0f u/s%s", ply.Checkpoints[ nID ][ 3 ]:Length2D(), CPGetKeys( ply ) ) } )
		else
			if bDelete then
				ply.Checkpoints[ nID ] = nil
				Core:Send( ply, "Checkpoints", { "Update", nID, true } )
			else
				if bDelay then
					ply.CPTeleport = true
					ply.Checkpoints[ nID ][ 4 ] = CurTime()
					Core:Send( ply, "Checkpoints", { "Delay" } )
					timer.Simple( 1.5, function()
						ply.CPTeleport = nil
						if not IsValid( ply ) then return end
						if ply.Style != _C.Style.Practice then return end
						
						local cp = ply.Checkpoints[ nID ]
						ply:SetPos( cp[ 1 ] )
						ply:SetEyeAngles( cp[ 2 ] )
						ply:SetLocalVelocity( cp[ 3 ] )
					end )
				else
					local cp = ply.Checkpoints[ nID ]
					ply:SetPos( cp[ 1 ] )
					ply:SetEyeAngles( cp[ 2 ] )
					ply:SetLocalVelocity( cp[ 3 ] )
					ply.Checkpoints[ nID ][ 4 ] = CurTime()
				end
			end
		end
	end
end


-- Conversion

local fl, fo, od, ot = math.floor, string.format, os.date, os.time
function Timer:Convert( ns )
	if ns > 3600 then
		return fo( "%d:%.2d:%.2d.%.3d", fl( ns / 3600 ), fl( ns / 60 % 60 ), fl( ns % 60 ), fl( ns * 1000 % 1000 ) )
	else
		return fo( "%.2d:%.2d.%.3d", fl( ns / 60 % 60 ), fl( ns % 60 ), fl( ns * 1000 % 1000 ) )
	end
end

function Timer:GetDate()
	return od( "%Y-%m-%d %H:%M:%S", ot() )
end


-- Hooking
local LeftBypass
local function BlockLeftRight( ply, data )
	if LeftBypass then return end
	if data:KeyDown( IN_LEFT ) or data:KeyDown( IN_RIGHT ) then
		if ply.Tn or ply.Tb then
			if ply:StopAnyTimer() then
				Core:Send( ply, "Print", { "Bhop Timer", Lang:Get( "StyleLeftRight" ) } )
			end
		end
	end
end
hook.Add( "SetupMove", "BlockLeft", BlockLeftRight )

function Timer:SetLeftBypass( bValue )
	LeftBypass = bValue
end