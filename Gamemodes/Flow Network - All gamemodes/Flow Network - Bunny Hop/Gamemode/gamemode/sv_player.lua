Player = {}
Player.MultiplierNormal = 1
Player.MultiplierAngled = 1
Player.LadderScalar = 1.40 --1.50 -- On 7.12 was 1.50 ~ Noob got Nightmare -> On 7.14 back to 1.5
Player.NormalScalar = 0.0001
Player.AngledScalar = 0.0001


function Player:Spawn( ply )
	if not IsValid( ply ) then return end
	
	ply:SetModel( _C["Player"].DefaultModel )
	ply:SetTeam( _C["Team"].Players )
	ply:SetJumpPower( _C["Player"].JumpPower )
	ply:SetHull( _C["Player"].HullMin, _C["Player"].HullStand )
	ply:SetHullDuck( _C["Player"].HullMin, _C["Player"].HullDuck )
	ply:SetNoCollideWithTeammates( true )
	ply:SetAvoidPlayers( false )
	
	if not ply:IsBot() then
		Stats:InitializePlayer( ply )
		
		if ply.Style == _C.Style.Bonus then
			ply:BonusReset()
		else
			ply:ResetTimer()
		end
		
		Player:SpawnChecks( ply )
	else
		ply:SetMoveType( MOVETYPE_NONE )
		ply:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
		ply:SetFOV( 90, 0 )
		ply:SetGravity( 0 )
		ply:StripWeapons()
		
		if Zones.BotPoint then
			ply:SetPos( Zones.BotPoint )
		end
	end
end

function Player:SpawnChecks( ply )
	Core.Util:SetPlayerJumps( ply, 0 )

	if Zones.StepSize then
		ply:SetStepSize( Zones.StepSize )
	elseif Zones.BonusStepSize and ply.Style == _C.Style.Bonus then
		ply:SetStepSize( Zones.BonusStepSize )
	elseif Zones.BonusStepSize and ply.Style != _C.Style.Bonus then
		ply:SetStepSize( Zones.DefaultStepSize )
	end
	
	if ply.Style == _C.Style.Legit and ply.LegitTopSpeed then
		if ply.LegitTopSpeed != 480 then
			ply:SetLegitSpeed( 480 )
		end
	end
	
	if ply.Style != _C.Style.Bonus and Zones.StartPoint then
		ply:SetPos( Zones:GetSpawnPoint( Zones.StartPoint ) )
	elseif ply.Style == _C.Style.Bonus and Zones.BonusPoint then
		ply:SetPos( Zones:GetSpawnPoint( Zones.BonusPoint ) )
	end
	
	if not ply:IsBot() and ply:GetMoveType() != MOVETYPE_WALK then
		ply:SetMoveType( MOVETYPE_WALK )
	end
end


function Player:Load( ply )
	if Core.Locked then
		return Core:Lock( "Re-lock for player joining" )
	end

	Stats:EnablePlayer( ply )

	if ply:IsBot() then
		Core:Broadcast( "Print", { "General", Lang:Get( "BotEnter", { Bot.Recent and "The " .. Core:StyleName( Bot.Recent ) .. "" or "A multi" } ) } )
	end
	
	ply:SetTeam( _C.Team.Players )
	ply.Style = _C.Style.Normal
	ply.Record = 0
	ply.Rank = -1
	
	if Zones.StyleForce then
		ply.Style = Zones.StyleForce
	end

	ply:SetNWInt( "Style", ply.Style )
	ply:SetNWFloat( "Record", ply.Record )
	
	if not ply:IsBot() then
		if SQL.Use and not SQL.Available and CurTime() - RTV.MapInit > 10 then
			return timer.Simple( 1, function()
				ply.DCReason = "No connection to master server"
				ply:Kick( "No connection to master server. Please try reconnecting!" )
			end )
		end
		
		Player:LoadBest( ply )
		Player:LoadRank( ply )
		
		Timer:SendInitialRecords( ply )
		Admin:CheckPlayerStatus( ply )
		Bot:CheckStatus()
		
		if Bot.RecordAll then
			Bot:AddPlayer( ply )
		else
			local bRank, bEmpty = ply.Rank >= 20, CurTime() - RTV.Initialized > Bot.MinimumTime and #player.GetHumans() < 12
			if bRank or bEmpty then
				Bot:AddPlayer( ply, bRank and " because of your high rank." or " because the server has low player count." )
			end
		end
		
		ply.ConnectedAt = CurTime()
	else
		ply.Temporary = true
		ply.Rank = -2
		
		ply:SetMoveType( MOVETYPE_NONE )
		ply:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
		ply:SetFOV( 90, 0 )
		ply:SetGravity( 0 )
		
		ply:SetNWInt( "Rank", ply.Rank )
	end
end

function Player:LoadStyle( ply, nStyle )
	ply.Style = nStyle
	ply.Record = 0
	
	Command:RemoveLimit( ply )
	Command.Restart( ply )
	
	Player:LoadBest( ply )
	Player:LoadRank( ply, true )
	
	ply:SetNWInt( "Style", ply.Style )
	ply:SetNWFloat( "Record", ply.Record )
	
	Core:Send( ply, "Print", { "Bhop Timer", Lang:Get( "StyleChange", { Core:StyleName( ply.Style ) } ) } )
end


-- RANKING

function Player:LoadRanks()
	local Data = sql.Query( "SELECT SUM(nMultiplier) AS nSum, SUM(nBonusMultiplier) AS nBonus FROM game_map" )
	if Core:Assert( Data, "nSum" ) then
		local Normal, Bonus = tonumber( Data[ 1 ]["nSum"] ) or 1, tonumber( Data[ 1 ]["nBonus"] ) or 1
		Player.MultiplierNormal = Normal + Bonus
		Player.MultiplierAngled = Normal * (1 / 2)
	end

	local OutNormal = Player:FindScalar( Player.MultiplierNormal )
	local OutAngled = Player:FindScalar( Player.MultiplierAngled )
	
	if OutNormal + OutAngled > 0 then
		Player.NormalScalar = OutNormal
		Player.AngledScalar = OutAngled
	else
		Core:Lock( "Couldn't calculate ranking scalar. Make sure you have at least ONE entry in your game_map!" )
	end
	
	for n,data in pairs( _C.Ranks ) do
		if n < 0 then continue end
		_C.Ranks[ n ][ 3 ] = Core:Exp( Player.NormalScalar, n )
		_C.Ranks[ n ][ 4 ] = Core:Exp( Player.AngledScalar, n )
	end
end


function Player:LoadRank( ply, bUpdate )
	local nSum = self:GetPointSum( ply.Style, ply:SteamID() )
	local nRank = self:GetRank( nSum, Player:GetRankType( ply.Style, true ) )
	ply.RankSum = nSum
	
	if nRank != ply.Rank then
		ply.Rank = nRank
		ply:SetNWInt( "Rank", ply.Rank )
	end
	
	self:SetSubRank( ply, nRank, nSum )
	
	if not bUpdate then
		Core:Send( ply, "Timer", { "Ranks", Player.NormalScalar, Player.AngledScalar } )
	end
end

function Player:LoadBest( ply )
	if ply.Style == _C.Style.Practice then
		ply:SetNWFloat( "Record", ply.Record )
		ply.SpecialRank = 0
		ply:SetNWInt( "SpecialRank", ply.SpecialRank )
		return Core:Send( ply, "Timer", { "Record", ply.Record, ply.Style } )
	end

	local Fetch = sql.Query( "SELECT t1.nTime, (SELECT COUNT(*) + 1 FROM game_times AS t2 WHERE szMap = '" .. game.GetMap() .. "' AND t2.nTime < t1.nTime AND nStyle = " .. ply.Style .. ") AS nRank FROM game_times AS t1 WHERE t1.szUID = '" .. ply:SteamID() .. "' AND t1.nStyle = " .. ply.Style .. " AND t1.szMap = '" .. game.GetMap() .. "'" )
	if Core:Assert( Fetch, "nTime" ) then
		ply.Record = tonumber( Fetch[ 1 ]["nTime"] )
		ply:SetNWFloat( "Record", ply.Record )
		
		Core:Send( ply, "Timer", { "Record", ply.Record, ply.Style } )
		Player:SetRankMedal( ply, tonumber( Fetch[ 1 ]["nRank"] ) )
	else
		ply:SetNWFloat( "Record", ply.Record )
		Core:Send( ply, "Timer", { "Record", ply.Record, ply.Style } )
		
		ply.SpecialRank = 0
		ply:SetNWInt( "SpecialRank", ply.SpecialRank )
	end
end

function Player:GetPointSum( nStyle, szUID )
	local Data = sql.Query( "SELECT SUM(nPoints) AS nSum FROM game_times WHERE szUID = '" .. szUID .. "' AND (" .. Player:GetMatchingStyles( nStyle ) .. ")" )
	if Core:Assert( Data, "nSum" ) then
		return tonumber( Data[ 1 ]["nSum"] ) or 0
	end
	
	return 0
end

function Player:GetRank( nPoints, nType )
	local Rank = 1
	
	for RankID, Data in pairs( _C.Ranks ) do
		if RankID > Rank and nPoints >= Data[ nType ] then
			Rank = RankID
		end
	end
	
	return Rank
end

function Player:SetSubRank( ply, nRank, nPoints )
	if nRank >= #_C.Ranks then
		-- To-Do: Make sure the Nightmare rank has 1 extra symbol for true top 1
		local nTarget = 10
		if not ply.SubRank or ply.SubRank != nTarget then
			ply.SubRank = nTarget
			ply:SetNWInt( "SubRank", ply.SubRank )
		end
	else
		local nDifference = _C.Ranks[ nRank + 1 ][ 3 ] - _C.Ranks[ nRank ][ 3 ]
		local nStepSize = nDifference / 10
		local nOut, nStep = 1, 1
		
		for i = _C.Ranks[ nRank ][ 3 ], _C.Ranks[ nRank + 1 ][ 3 ], nStepSize do
			if nPoints >= i then
				nOut = nStep
			end
			
			nStep = nStep + 1
		end
		
		if not ply.SubRank or ply.SubRank != nOut then
			ply.SubRank = nOut
			ply:SetNWInt( "SubRank", ply.SubRank )
		end
	end
end

function Player:ReloadSubRanks( sender, nOld )
	local nMultiplier = Timer:GetMultiplier( sender.Style )
	if not nMultiplier or nMultiplier == 0 then return end
	local nAverage = Timer:GetAverage( sender.Style )
	if not nAverage or not nOld then return end

	for _,p in pairs( player.GetHumans() ) do
		if p == sender or not p.RankSum or not p.Rank or not p.Record or p.Record == 0 or p.Style != sender.Style then continue end
		
		local nCurrent = nMultiplier * (nOld / p.Record)
		local nNew = nMultiplier * (nAverage / p.Record)
		local nPoints = p.RankSum - nCurrent + nNew
		
		local nRank = self:GetRank( nPoints, Player:GetRankType( p.Style, true ) )
		if nRank != p.Rank then
			p.Rank = nRank
			p:SetNWInt( "Rank", p.Rank )
		end
		
		p.RankSum = nPoints
		Player:SetSubRank( p, p.Rank, p.RankSum )
	end
end

function Player:SetRankMedal( ply, nPos )
	local Query = sql.Query( "SELECT t1.szUID, (SELECT COUNT(*) + 1 FROM game_times AS t2 WHERE szMap = '" .. game.GetMap() .. "' AND t2.nTime < t1.nTime AND nStyle = " .. ply.Style .. ") AS nRank FROM game_times AS t1 WHERE t1.szMap = '" .. game.GetMap() .. "' AND t1.nStyle = " .. ply.Style .. " AND nRank < 4 ORDER BY nRank ASC" )
	if Core:Assert( Query, "szUID" ) then
		for _,p in pairs( player.GetHumans() ) do
			if p.Style != ply.Style then continue end
			local bSet = false
			
			for _,d in pairs( Query ) do
				if p:SteamID() == d["szUID"] then
					bSet = true
					
					if tonumber( d["nRank"] ) > 3 then
						if p.SpecialRank then
							p.SpecialRank = 0
							p:SetNWInt( "SpecialRank", p.SpecialRank )
						end
					else
						p.SpecialRank = tonumber( d["nRank"] )
						p:SetNWInt( "SpecialRank", p.SpecialRank )
					end
				end
			end
			
			if not bSet and p.SpecialRank then
				p.SpecialRank = 0
				p:SetNWInt( "SpecialRank", p.SpecialRank )
			end
		end
	end
end

function Player:UpdateRank( ply )
	Player:LoadRank( ply, true )
end

function Player:AddScore( ply )
	ply:AddFrags( 1 )
end

function Player:GetMatchingStyles( nStyle )
	local tab = { _C.Style.Normal, _C.Style["Easy Scroll"], _C.Style.Legit, _C.Style.Bonus }
	
	if nStyle >= _C.Style.SW and nStyle <= _C.Style["A-Only"] then
		tab = { _C.Style.SW, _C.Style.HSW, _C.Style["W-Only"], _C.Style["A-Only"] }
	end

	local t = {}
	for _,s in pairs( tab ) do
		table.insert( t, "nStyle = " .. s )
	end
	
	return string.Implode( " OR ", t )
end

function Player:FindScalar( nMultiplier )
	local Count, Sum, Out = #_C.Ranks, nMultiplier * Player.LadderScalar, 0
	for i = 0, 50, 0.00001 do
		if Core:Exp( i, Count ) > Sum then
			Out = i
			break
		end
	end
	
	return Out
end

function Player:GetRankType( nStyle, bNumber )
	if nStyle >= _C.Style.SW and nStyle <= _C.Style["A-Only"] then
		if bNumber then return 4 else return true end
	else
		if bNumber then return 3 else return false end
	end
end

function Player:GetOnlineVIPs()
	local tabVIP = {}
	
	for _,p in pairs( player.GetHumans() ) do
		if p.IsVIP then
			table.insert( tabVIP, p )
		end
	end
	
	return tabVIP
end


-- TOTAL STATISTICS

local TopCache = {}
local TopLimit = 15 * _C.PageSize

function Player:LoadTop()
	local nNormal = Player:GetRankType( _C.Style.Normal, true )
	local nAngled = Player:GetRankType( _C.Style.SW, true )
	
	TopCache[ nNormal ] = {}
	TopCache[ nAngled ] = {}

	local Normal = sql.Query( "SELECT szPlayer, SUM(nPoints) as nSum FROM game_times WHERE (nStyle = " .. _C.Style.Normal .. " OR nStyle = " .. _C.Style.Bonus .. ") GROUP BY szUID ORDER BY nSum DESC LIMIT " .. TopLimit )
	if Core:Assert( Normal, "nSum" ) then
		for i,d in pairs( Normal ) do
			TopCache[ nNormal ][ i ] = { string.sub( d["szPlayer"], 1, 20 ), math.floor( tonumber( d["nSum"] ) ) }
		end
	end
	
	local Angled = sql.Query( "SELECT szPlayer, SUM(nPoints) as nSum FROM game_times WHERE (nStyle = " .. _C.Style.SW .. " OR nStyle = " .. _C.Style.HSW .. ") GROUP BY szUID ORDER BY nSum DESC LIMIT " .. TopLimit )
	if Core:Assert( Angled, "nSum" ) then
		for i,d in pairs( Angled ) do
			TopCache[ nAngled ][ i ] = { string.sub( d["szPlayer"], 1, 20 ), math.floor( tonumber( d["nSum"] ) ) }
		end
	end
end

function Player:GetTopPage( nPage, nStyle )
	local tab = {}
	local Index = _C.PageSize * nPage - _C.PageSize
	local Number = Player:GetRankType( nStyle, true )

	for i = 1, _C.PageSize do
		i = i + Index
		if TopCache[ Number ][ i ] then
			tab[ i ] = TopCache[ Number ][ i ]
		end
	end

	return tab
end

function Player:GetTopCount( nStyle )
	local Number = Player:GetRankType( nStyle, true )
	return #TopCache[ Number ]
end

function Player:SendTopList( ply, nPage, nType )
	local nStyle = nType == 4 and _C.Style.SW or _C.Style.Normal
	Core:Send( ply, "GUI_Update", { "Top", { 4, Player:GetTopPage( nPage, nStyle ), nPage, Player:GetTopCount( nStyle ), nType } } )
end


function Player:GetMapsBeat( ply )
	if ply.BeatReceived and ply.BeatReceived == ply.Style then
		return nil
	else
		ply.BeatReceived = ply.Style
	end
	
	local List = sql.Query( "SELECT szMap, nTime, nPoints FROM game_times WHERE szUID = '" .. ply:SteamID() .. "' AND nStyle = " .. ply.Style .. " ORDER BY nPoints ASC" )
	if Core:Assert( List, "szMap" ) then
		local tab = {}
		for _,d in pairs( List ) do
			table.insert( tab, { d["szMap"], tonumber( d["nTime"] ), tonumber( d["nPoints"] ) } )
		end
		return tab
	end
	
	return {}
end


local RemoteWRCache = {}
function Player:SendRemoteWRList( ply, szMap, nStyle, nPage, bUpdate )
	if not szMap or type( szMap ) != "string" then return end
	if szMap == game.GetMap() then
		return Core:Send( ply, "GUI_Open", { "WR", { 2, Timer:GetRecordList( nStyle, nPage ), nStyle, nPage, Timer:GetRecordCount( nStyle ) } } )
	end
	
	local SendData = {}
	local SendCount = 0
	
	local RWRC = RemoteWRCache[ szMap ]
	
	if not RWRC or (type( RWRC ) == "table" and not RWRC[ nStyle ]) then
		if RTV:MapExists( szMap ) then
			local List = sql.Query( "SELECT * FROM game_times WHERE szMap = '" .. szMap .. "' AND nStyle = " .. nStyle .. " ORDER BY nTime ASC" )
			if not RWRC then
				RemoteWRCache[ szMap ] = {}
			end
			
			RemoteWRCache[ szMap ][ nStyle ] = {}
			
			if Core:Assert( List, "szUID" ) then
				for _,data in pairs( List ) do
					table.insert( RemoteWRCache[ szMap ][ nStyle ], { data["szUID"], data["szPlayer"], tonumber( data["nTime"] ), Core:Null( data["szDate"] ), Core:Null( data["vData"] ) } )
				end
			end
			
			local a = nPage * _C.PageSize - _C.PageSize
			for i = 1, _C.PageSize do
				i = i + a
				if RemoteWRCache[ szMap ][ nStyle ][ i ] then
					SendData[ i ] = RemoteWRCache[ szMap ][ nStyle ][ i ]
				end
			end
			
			SendCount = #RemoteWRCache[ szMap ][ nStyle ]
		else
			return Core:Send( ply, "Print", { "General", Lang:Get( "MapInavailable", { szMap } ) } )
		end
	else
		local a = nPage * _C.PageSize - _C.PageSize
		for i = 1, _C.PageSize do
			i = i + a
			if RemoteWRCache[ szMap ][ nStyle ][ i ] then
				SendData[ i ] = RemoteWRCache[ szMap ][ nStyle ][ i ]
			end
		end
		
		SendCount = #RemoteWRCache[ szMap ][ nStyle ]
	end
	
	local bZero = true
	for i,data in pairs( SendData ) do
		if i and data then bZero = false break end
	end
	
	if bZero or SendCount == 0 then
		if bUpdate then return end
		Core:Send( ply, "Print", { "Bhop Timer", "No WR data found for " .. szMap .. " on style " .. Core:StyleName( nStyle ) } )
	else
		if bUpdate then
			Core:Send( ply, "GUI_Update", { "WR", { 4, SendData, nPage, SendCount } } )
		else
			Core:Send( ply, "GUI_Open", { "WR", { 2, SendData, nStyle, nPage, SendCount, szMap } } )
		end
	end
end


-- CONNECTION
local function PlayerDisconnect( ply )
	if not ply.DCReason or (ply.DCReason and ply.DCReason != "Banned permanently") then
		Core:Broadcast( "Print", { "General", Lang:Get( "Disconnect", { ply:Name(), ply:SteamID(), ply.DCReason or "Player left" } ) } )
	end
	
	if #player.GetHumans() - 1 < 1 then
		Core:Unload()
	end
	
	if ply.Spectating then
		Spectator:End( ply, ply:GetObserverTarget() )
		ply.Spectating = nil
	end
	
	SMgrAPI:RemovePlayer( ply )
	
	if RTV.VotePossible then return end
	if ply.Rocked then
		RTV.MapVotes = RTV.MapVotes - 1
	end
	
	local Count = #player.GetHumans()
	if Count > 1 then
		RTV.Required = math.ceil( (Count - 1) * ( 2 / 3 ) )
		if RTV.MapVotes >= RTV.Required then
			RTV:StartVote()
		end
	end
end
hook.Add( "PlayerDisconnected", "PlayerDisconnect", PlayerDisconnect )

local function PlayerConnect( data )
	if data.bot != 1 then
		if not SQL.Available and not SQL.Busy then
			Core:StartSQL()
		end
	end
end
hook.Add( "player_connect", "PlayerConnect", PlayerConnect )