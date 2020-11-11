RTV = {}

RTV.Initialized = 0
RTV.VotePossible = false
RTV.DefaultExtend = 15
RTV.MaxSlots = 64
RTV.Extends = 0
RTV.Nominations = {}
RTV.LatestList = {}

RTV.MapLength = 90 * 60
RTV.MapInit = CurTime()
RTV.MapEnd = 0
RTV.MapVotes = 0
RTV.MapVoteList = { 0, 0, 0, 0, 0, 0, 0 }

RTV.MapListVersion = 1
local MapList = {}

function RTV:Init()
	if timer.Exists( "MapCountdown" ) then
		timer.Destroy( "MapCountdown" )
	end
	
	timer.Create( "MapCountdown", RTV.MapLength, 1, function() RTV:StartVote() end )
	
	RTV.Initialized = CurTime()
	RTV.MapInit = CurTime()
	RTV.MapEnd = RTV.MapInit + RTV.MapLength
	
	RTV:LoadData()
	RTV:TrueRandom( 1, 5 )
end

function RTV:StartVote()
	if RTV.VotePossible then return end
	
	RTV.VotePossible = true
	RTV.Selections = {}
	Core:Broadcast( "Print", { "Notification", Lang:Get( "VoteStart" ) } )

	local RTVTempList = {}
	for map, voters in pairs( RTV.Nominations ) do
		local nCount = #voters
		if not RTVTempList[ nCount ] then
			RTVTempList[ nCount ] = { map }
		else
			table.insert( RTVTempList[ nCount ], map )
		end
	end

	local Added = 0
	for i = RTV.MaxSlots, 1, -1 do
		if RTVTempList[ i ] then
			for _, map in pairs( RTVTempList[ i ] ) do
				if Added >= 5 then break end
				table.insert( RTV.Selections, map )
				Added = Added + 1
			end
		end
	end
	
	if Added < 5 and MapList and #MapList > 0 then
		for _,data in RandomPairs( MapList ) do
			if Added > 4 then break end
			if table.HasValue( RTV.Selections, data[ 1 ] ) or data[ 1 ] == game.GetMap() then continue end
			
			table.insert( RTV.Selections, data[ 1 ] )
			Added = Added + 1
		end
	end
	
	local RTVSend = {}
	for _,map in pairs( RTV.Selections ) do
		table.insert( RTVSend, RTV:GetMapData( map ) )
	end
	
	local tabVIPs = Player:GetOnlineVIPs()
	if RTV.Extends >= 2 and #tabVIPs > 0 then
		table.insert( RTVSend, { "__NO_EXTEND__" } )
		
		RTV.VIPRequired = true
		Core:Send( tabVIPs, "Print", { "Notification", Lang:Get( "VoteVIPExtend" ) } )
	end
	
	Core:Broadcast( "RTV", { "GetList", RTVSend } )
	timer.Simple( 31, function() if not RTV.VIPTriggered then RTV:EndVote() end end )
	
	timer.Simple( 0.1, function()
		for map, voters in pairs( RTV.Nominations ) do
			for id,data in pairs( RTVSend ) do
				if data[ 1 ] == map then
					Core:Send( voters, "RTV", { "InstantVote", id } )
				end
			end
		end
	end )
end

function RTV:EndVote()
	RTV.VIPTriggered = nil

	if RTV.CancelVote then
		return RTV:ResetVote( "Yes", 2, false, "VoteCancelled" )
	end
	
	Core:Unload()
	
	local nMax, nWin = 0, -1
	for i = 1, 7 do
		if RTV.MapVoteList[ i ] > nMax then
			nMax = RTV.MapVoteList[ i ]
			nWin = i
		end
	end
	
	if nWin <= 0 then
		nWin = RTV:TrueRandom( 1, 5 )
	elseif nWin == 6 then
		Core:Broadcast( "Print", { "Notification", Lang:Get( "VoteExtend", { RTV.DefaultExtend } ) } )
		return RTV:ResetVote( nil, 1, true, nil, true )
	elseif nWin == 7 then
		RTV.VotePossible = false
		
		if MapList and #MapList > 0 then
			local nValue = RTV:TrueRandom( 1, #MapList )
			local tabWin = MapList[ nValue ]
			local szMap = tabWin[ 1 ]
			
			Core:Broadcast( "Print", { "Notification", Lang:Get( "VoteChange", { szMap } ) } )
			timer.Simple( 5, function() RunConsoleCommand( "changelevel", szMap ) end )
		else
			nWin = RTV:TrueRandom( 1, 5 )
		end
	end
	
	local szMap = RTV.Selections[ nWin ]
	if not szMap or not type( szMap ) == "string" then return end
	
	Core:Broadcast( "Print", { "Notification", Lang:Get( "VoteChange", { szMap } ) } )
	if not RTV:IsAvailable( szMap ) then
		Core:Broadcast( "Print", { "Notification", Lang:Get( "VoteMissing", { szMap } ) } )
	end
	
	timer.Simple( 10, function()
		RTV:ResetVote( "Yes", 1, false, "VoteFailure" )
	end )
	
	Core:Broadcast( "Radio", { "Save" } )
	timer.Simple( 5, function() RunConsoleCommand( "changelevel", szMap ) end )
end

function RTV:ResetVote( szCancel, nMult, bExtend, szMsg, bNominate )
	if not nMult then
		nMult = 1
	end

	if szCancel and szCancel == "Yes" then
		RTV.CancelVote = nil
	end
	
	RTV.VotePossible = false
	RTV.Selections = {}
	
	if bNominate then
		RTV.Nominations = {}
	end
	
	RTV.MapInit = CurTime()
	RTV.MapEnd = RTV.MapInit + (nMult * RTV.DefaultExtend * 60)
	RTV.MapVotes = 0
	RTV.MapVoteList = { 0, 0, 0, 0, 0, 0, 0 }
	
	if bExtend then
		RTV.Extends = RTV.Extends + 1
	end
	
	for _, p in pairs( player.GetHumans() ) do
		if p.Rocked then p.Rocked = nil end
		if bNominate and p.NominatedMap then p.NominatedMap = nil end
	end
	
	if timer.Exists( "MapCountdown" ) then
		timer.Destroy( "MapCountdown" )
	end
	
	timer.Create( "MapCountdown", nMult * RTV.DefaultExtend * 60, 1, function() RTV:StartVote() end )
	if szMsg then
		Core:Broadcast( "Print", { "Notification", Lang:Get( szMsg ) } )
	end
end


function RTV:Vote( ply )
	if ply.RTVLimit and CurTime() - ply.RTVLimit < 60 then
		return Core:Send( ply, "Print", { "Notification", Lang:Get( "VoteLimit", { math.ceil( 60 - (CurTime() - ply.RTVLimit) ) } ) } )
	elseif ply.Rocked then
		return Core:Send( ply, "Print", { "Notification", Lang:Get( "VoteAlready" ) } )
	elseif RTV.VotePossible then
		return Core:Send( ply, "Print", { "Notification", Lang:Get( "VotePeriod" ) } )
	end
	
	ply.RTVLimit = CurTime()
	ply.Rocked = true
	
	RTV.MapVotes = RTV.MapVotes + 1
	RTV.Required = math.ceil( #player.GetHumans() * ( 2 / 3 ) )
	local nVotes = RTV.Required - RTV.MapVotes
	Core:Broadcast( "Print", { "Notification", Lang:Get( "VotePlayer", { ply:Name(), nVotes, nVotes == 1 and "vote" or "votes" } ) } )
	
	if RTV.MapVotes >= RTV.Required then
		RTV:StartVote()
	end
end

function RTV:Revoke( ply )
	if RTV.VotePossible then
		return Core:Send( ply, "Print", { "Notification", Lang:Get( "VotePeriod" ) } )
	end

	if ply.Rocked then
		ply.Rocked = false
		
		RTV.MapVotes = RTV.MapVotes - 1
		RTV.Required = math.ceil( #player.GetHumans() * ( 2 / 3 ) )
		local nVotes = RTV.Required - RTV.MapVotes
		Core:Broadcast( "Print", { "Notification", Lang:Get( "VoteRevoke", { ply:Name(), nVotes, nVotes == 1 and "vote" or "votes" } ) } )
	else
		Core:Send( ply, "Print", { "Notification", Lang:Get( "RevokeFail" ) } )
	end
end

function RTV:Nominate( ply, szMap )
	local szIdentifier = "Nomination"
	local varArgs = { ply:Name(), szMap }

	if ply.NominatedMap and ply.NominatedMap != szMap then
		if RTV.Nominations[ ply.NominatedMap ] then
			for id, p in pairs( RTV.Nominations[ ply.NominatedMap ] ) do
				if p == ply then
					table.remove( RTV.Nominations[ ply.NominatedMap ], id )
					if #RTV.Nominations[ ply.NominatedMap ] == 0 then
						RTV.Nominations[ ply.NominatedMap ] = nil
					end
					
					szIdentifier = "NominationChange"
					varArgs = { ply:Name(), ply.NominatedMap, szMap }
					break
				end
			end
		end
	elseif ply.NominatedMap and ply.NominatedMap == szMap then
		return Core:Send( ply, "Print", { "Notification", Lang:Get( "NominationAlready" ) } )
	end

	if not RTV.Nominations[ szMap ] then
		RTV.Nominations[ szMap ] = { ply }
		ply.NominatedMap = szMap
		Core:Broadcast( "Print", { "Notification", Lang:Get( szIdentifier, varArgs ) } )
	elseif type( RTV.Nominations ) == "table" then
		local Included = false
		for _, p in pairs( RTV.Nominations[ szMap ] ) do
			if p == ply then Included = true break end
		end
		
		if not Included then
			table.insert( RTV.Nominations[ szMap ], ply )
			ply.NominatedMap = szMap
			Core:Broadcast( "Print", { "Notification", Lang:Get( szIdentifier, varArgs ) } )
		else
			return Core:Send( ply, "Print", { "Notification", Lang:Get( "NominationAlready" ) } )
		end
	end
end

function RTV:ReceiveVote( ply, nVote, nOld )
	if not RTV.VotePossible or not nVote then return end
	
	local nAdd = 1
	if ply.IsVIP and ply.VIPLevel and ply.VIPLevel >= Admin.Level.Elevated then
		nAdd = 2
	end
	
	if not nOld then
		if nVote < 1 or nVote > 7 then return end
		RTV.MapVoteList[ nVote ] = RTV.MapVoteList[ nVote ] + nAdd
		Core:Broadcast( "RTV", { "VoteList", RTV.MapVoteList } )
	else
		if nVote < 1 or nVote > 7 or nOld < 1 or nOld > 7 then return end
		RTV.MapVoteList[ nVote ] = RTV.MapVoteList[ nVote ] + nAdd
		RTV.MapVoteList[ nOld ] = RTV.MapVoteList[ nOld ] - nAdd
		if RTV.MapVoteList[ nOld ] < 0 then RTV.MapVoteList[ nOld ] = 0 end
		Core:Broadcast( "RTV", { "VoteList", RTV.MapVoteList } )
	end
end

function RTV:IsAvailable( szMap )
	return file.Exists( "maps/" .. szMap .. ".bsp", "GAME" )
end

function RTV:Who( ply )
	local Voted = {}
	local NotVoted = {}
	
	for _,p in pairs( player.GetHumans() ) do
		if p.Rocked then
			table.insert( Voted, p:Name() )
		else
			table.insert( NotVoted, p:Name() )
		end
	end
	
	RTV.Required = math.ceil( #player.GetHumans() * ( 2 / 3 ) )
	Core:Send( ply, "Print", { "Notification", Lang:Get( "VoteList", { RTV.Required, #Voted, string.Implode( ", ", Voted ), #NotVoted, string.Implode( ", ", NotVoted ) } ) } )
end

function RTV:Check( ply )
	RTV.Required = math.ceil( #player.GetHumans() * ( 2 / 3 ) )
	local nVotes = RTV.Required - RTV.MapVotes
	Core:Send( ply, "Print", { "Notification", Lang:Get( "VoteCheck", { nVotes, nVotes == 1 and "vote" or "votes" } ) } )
end

function RTV:VIPExtend( ply )
	if RTV.VotePossible then
		if RTV.VIPRequired then
			Core:Broadcast( "RTV", { "VIPExtend" } )
			timer.Simple( 31, function() RTV:EndVote() end )
			
			RTV.VIPTriggered = ply
			RTV.VIPRequired = nil
		else
			if not RTV.VIPTriggered then
				Core:Send( ply, "Print", { "Notification", "You can only use this command when people want to extend the map more than 2 times." } )
			elseif ply != RTV.VIPTriggered then
				Core:Send( ply, "Print", { "Notification", "Your fellow VIP " .. RTV.VIPTriggered:Name() .. " has already triggered the extend vote." } )
			else
				Core:Send( ply, "Print", { "Notification", "You cannot use this command again in the same session." } )
			end
		end
	else
		Core:Send( ply, "Print", { "Notification", "You can only use this command while a vote is active!" } )
	end
end


function RTV:LoadData()
	MapList = {}
	
	local Unique = sql.Query( "SELECT szMap, nMultiplier FROM game_map" )
	if Core:Assert( Unique, "szMap" ) then
		for _,data in pairs( Unique ) do
			table.insert( MapList, { data["szMap"], Core:Null( data["nMultiplier"], 1 ) } )
		end
	end
	
	file.CreateDir( _C.GameType .. "/" )
	
	if not file.Exists( _C.GameType .. "/settings.txt", "DATA" ) then
		file.Write( _C.GameType .. "/settings.txt", tostring( RTV.MapListVersion ) )
	else
		local data = file.Read( _C.GameType .. "/settings.txt", "DATA" )
		RTV.MapListVersion = tonumber( data )
	end
end

function RTV:UpdateMapListVersion()
	RTV.MapListVersion = RTV.MapListVersion + 1
	file.Write( _C.GameType .. "/settings.txt", tostring( RTV.MapListVersion ) )
end

local EncodedData, EncodedLength
function RTV:GetMapList( ply, nVersion )
	if nVersion != RTV.MapListVersion then
		if not EncodedData or not EncodedLength then
			EncodedData = util.Compress( util.TableToJSON( { MapList, RTV.MapListVersion } ) )
			EncodedLength = #EncodedData
		end
		
		if not EncodedData or not EncodedLength then
			Core:Send( ply, "Print", { "Notification", "Couldn't obtain map list, please reconnect!" } )
		else
			net.Start( Core.Protocol2 )
			net.WriteString( "List" )
			net.WriteUInt( EncodedLength, 32 )
			net.WriteData( EncodedData, EncodedLength )
			net.Send( ply )
		end
	end
end

function RTV:MapExists( szMap )
	for _,data in pairs( MapList ) do
		if data[ 1 ] == szMap then
			return true
		end
	end
	
	return false
end

function RTV:GetMapData( szMap )
	for _,data in pairs( MapList ) do
		if data[ 1 ] == szMap then
			return data
		end
	end
	
	return { szMap, 1 }
end

function RTV:TrueRandom( nUp, nDown )
	if not RTV.RandomInit then
		math.random()
		math.random()
		math.random()
		
		RTV.RandomInit = true
	end
	
	return math.random( nUp, nDown )
end