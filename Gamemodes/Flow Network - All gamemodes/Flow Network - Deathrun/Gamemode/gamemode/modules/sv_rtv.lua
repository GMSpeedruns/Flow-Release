RTV = {}
RTV.Gamemode = "deathrun" -- This must be the same as the name of the folder of the gamemode or this will NOT WORK

RTV.Initialized = 0
RTV.VotePossible = false
RTV.DefaultExtend = 20
RTV.DefaultExtendRounds = 5
RTV.MaxSlots = 64
RTV.Extends = 0
RTV.Votes = 0
RTV.VotePossibleAt = CurTime() + (15 * 60)
RTV.Nominations = {}

RTV.MapLength = 60 * 60
RTV.MapInit = CurTime()
RTV.MapEnd = 0
RTV.MapListVersion = 1
RTV.MapVotes = { 0, 0, 0, 0, 0, 0 }

local MapList = {}
local MapCount = 0

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
	
	if timer.Exists( "MapCountdown" ) then
		timer.Destroy( "MapCountdown" )
	end
	
	RTV.VotePossible = true
	RTV.Selections = {}
	RTV:Message( Lang:Get( "VoteStart" ) )

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
	
	if Added < 5 and MapList and MapCount > 0 then
		for real,data in RandomPairs( MapList ) do
			if Added > 4 then break end
			if table.HasValue( RTV.Selections, real ) or real == game.GetMap() then continue end
			
			table.insert( RTV.Selections, real )
			Added = Added + 1
		end
	end
	
	local RTVSend = {}
	for _,map in pairs( RTV.Selections ) do
		table.insert( RTVSend, MapList[ map ] and MapList[ map ][ 1 ] or "Unknown map" )
	end
	
	local tabVIPs = Player:GetOnlineVIPs()
	if RTV.Extends >= 1 then
		table.insert( RTVSend, { "__NO_EXTEND__" } )
		
		RTV.VIPRequired = true
		Core:Send( tabVIPs, "Print", { "Notification", Lang:Get( "VoteVIPExtend" ) } )
	end
	
	Core:Broadcast( "RTV", { "List", RTVSend } )
	timer.Simple( 31, function() if not RTV.VIPTriggered then RTV:EndVote() end end )
	
	timer.Simple( 0.1, function()
		for map, voters in pairs( RTV.Nominations ) do
			for id,real in pairs( RTV.Selections ) do
				if real == map then
					Core:Send( voters, "RTV", { "InstantVote", id } )
				end
			end
		end
	end )
end

function RTV:EndVote()
	if RTV.CancelVote then
		return RTV:ResetVote( false, Lang:Get( "VoteCancelled" ), false )
	end
	
	local nMax, nWin = 0, -1
	for i = 1, 6 do
		if RTV.MapVotes[ i ] > nMax then
			nMax = RTV.MapVotes[ i ]
			nWin = i
		end
	end
	
	if nWin <= 0 then
		nWin = RTV:TrueRandom( 1, 5 )
	elseif nWin == 6 then
		Round:Extend( RTV.DefaultExtendRounds )
		return RTV:ResetVote( true, Lang:Get( "VoteExtend", { RTV.DefaultExtendRounds } ), true )
	end
	
	local szMap = RTV.Selections[ nWin ]
	if not szMap or not type( szMap ) == "string" then return end
	local name = MapList[ szMap ] and MapList[ szMap ][ 1 ] or "Unknown map"
	
	Core:Broadcast( "Print", { "Notification", Lang:Get( "VoteChange", { name } ) } )
	Core:Broadcast( "Radio", { "Save" } )
	
	RTV:Change( szMap, name, true )
	if #player.GetHumans() < 3 then
		RTV:Change()
		timer.Simple( 10, function()
			RTV:ResetVote( false, "Something went wrong while changing maps to: " .. name, false )
		end )
	else
		timer.Simple( 5 * 60, function()
			RTV:Change()
			RTV:ResetVote( false, "Something went wrong while changing maps to: " .. name, false )
		end )
	end
end

function RTV:ResetVote( bExtend, szMsg, bNominate )
	RTV.VotePossible = false
	RTV.Selections = {}
	
	if bNominate then
		RTV.Nominations = {}
	end
	
	RTV.MapInit = CurTime()
	RTV.MapEnd = RTV.MapInit
	RTV.MapVotes = { 0, 0, 0, 0, 0, 0 }
	RTV.Votes = 0
	
	if bExtend then
		RTV.Extends = RTV.Extends + 1
		RTV.MapEnd = RTV.MapEnd + (RTV.DefaultExtend * 60)
	end
	
	for _, p in pairs( player.GetHumans() ) do
		if p.Rocked then p.Rocked = nil end
		if bNominate and p.NominatedMap then p.NominatedMap = nil end
	end
	
	for _, p in pairs( player.GetHumans() ) do
		if bNominate and p.NominatedMap then p.NominatedMap = nil end
	end
	
	if timer.Exists( "MapCountdown" ) then
		timer.Destroy( "MapCountdown" )
	end
	
	timer.Create( "MapCountdown", RTV.DefaultExtend * 60, 1, function() RTV:StartVote() end )
	if szMsg then
		RTV:Message( szMsg )
	end
end

-- To-Do: Check if this works now
function RTV:Change( szMap, szFriendly, bWait )
	if szMap then
		RTV.ChangeMap = { szMap, szFriendly }
		if bWait then return end
	end
	
	if RTV.ChangeMap then
		Core:Unload()
		Core:Broadcast( "Print", { "General", Lang:Get( "MapChange", { RTV.ChangeMap[ 2 ] } ) } )
		timer.Simple( 3, function()
			RunConsoleCommand( "changelevel", RTV.ChangeMap[ 1 ] )
		end )
	end
end


local function AddMap( tabMap, current )
	MapList[ tabMap.RealName ] = { tabMap.Name }
	MapCount = MapCount + 1
	
	if tabMap.RealName == current then
		if tabMap.DeathSpeed then
			_C.Player.FastSpeed = tabMap.DeathSpeed
		end
		
		if tabMap.NoDeathGun then
			Core:SetDeathPickup( true )
		end
		
		if tabMap.Tracker then
			-- To-Do: Implement when DR gamemode is ready
			print( "This is not finished yet!" )
		end
		
		if tabMap.Hooks then
			for hook,data in pairs( tabMap.Hooks ) do
				local name = hook
				if hook:match( "%W" ) then
					name = string.Explode( "_", hook )[ 1 ]
				end
				
				if Zones.Type[ name ] then
					local zone = {
						Type = Zones.Type[ name ],
						P1 = data.Start,
						P2 = data.End,
					}
					
					data.Start, data.End = nil, nil
					zone.Data = data
					
					table.insert( Zones.Cache, zone )
				end
			end
		end
	end
end

function RTV:LoadData()
	MapList = {}
	MapCount = 0
	
	local map = game.GetMap()
	local files = file.Find( RTV.Gamemode .. "/gamemode/maps/*", "LUA" )
	for _,file in pairs( files ) do
		__MAP = "NEW"
		include( RTV.Gamemode .. "/gamemode/maps/" .. file )
		
		if __MAP and type( __MAP ) == "table" then
			AddMap( __MAP, map )
		else
			print( "Map couldn't be loaded!", "File 'maps/" .. file .. "' contains invalid map data!" )
		end
	end
	
	if not MapList[ game.GetMap() ] then
		local data,key = table.Random( MapList )
		if key then
			RTV:Change( key, data[ 1 ] )
		else
			print( "There are no available maps to change to!" )
		end
	end
	
	file.CreateDir( "deathrun/" )
	
	if not file.Exists( "deathrun/settings.txt", "DATA" ) then
		file.Write( "deathrun/settings.txt", tostring( RTV.MapListVersion ) )
	else
		local data = file.Read( "deathrun/settings.txt", "DATA" )
		RTV.MapListVersion = tonumber( data )
	end
end


function RTV:Nominate( ply, szMap, szName )
	local szIdentifier = "Nomination"
	local varArgs = { ply:Name(), szName }
	
	if ply.NominatedMap and ply.NominatedMap != szMap then
		if RTV.Nominations[ ply.NominatedMap ] then
			for id, p in pairs( RTV.Nominations[ ply.NominatedMap ] ) do
				if p == ply then
					table.remove( RTV.Nominations[ ply.NominatedMap ], id )
					if #RTV.Nominations[ ply.NominatedMap ] == 0 then
						RTV.Nominations[ ply.NominatedMap ] = nil
					end
					
					szIdentifier = "NominationChange"
					varArgs = { ply:Name(), MapList[ ply.NominatedMap ][ 1 ], szName }
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

function RTV:Vote( ply )
	if CurTime() <= RTV.VotePossibleAt then
		local t,s = math.Round( (RTV.VotePossibleAt - CurTime()) / 60 ), "minutes"
		if t < 1 then t,s = math.Round( RTV.VotePossibleAt - CurTime() ), "seconds" end
		if t == 1 then s = "second" end
		return Core:Send( ply, "Print", { "Notification", Lang:Get( "VoteNotPossible", { t .. " " .. s } ) } )
	elseif ply.RTVLimit and CurTime() - ply.RTVLimit < 60 then
		return Core:Send( ply, "Print", { "Notification", Lang:Get( "VoteLimit", { math.ceil( 60 - (CurTime() - ply.RTVLimit) ) } ) } )
	elseif ply.Rocked then
		return Core:Send( ply, "Print", { "Notification", Lang:Get( "VoteAlready" ) } )
	elseif RTV.VotePossible then
		return Core:Send( ply, "Print", { "Notification", Lang:Get( "VotePeriod" ) } )
	end
	
	ply.RTVLimit = CurTime()
	ply.Rocked = true
	
	RTV.Votes = RTV.Votes + 1
	RTV.Required = math.ceil( #player.GetHumans() * ( 2 / 3 ) )
	local nVotes = RTV.Required - RTV.Votes
	Core:Broadcast( "Print", { "Notification", Lang:Get( "VotePlayer", { ply:Name(), nVotes, nVotes == 1 and "vote" or "votes" } ) } )
	
	if RTV.Votes >= RTV.Required then
		RTV:StartVote()
	end
end

function RTV:Revoke( ply )
	if RTV.VotePossible then
		return Core:Send( ply, "Print", { "Notification", Lang:Get( "VotePeriod" ) } )
	end

	if ply.Rocked then
		ply.Rocked = false
		
		RTV.Votes = RTV.Votes - 1
		RTV.Required = math.ceil( #player.GetHumans() * ( 2 / 3 ) )
		local nVotes = RTV.Required - RTV.Votes
		Core:Broadcast( "Print", { "Notification", Lang:Get( "VoteRevoke", { ply:Name(), nVotes, nVotes == 1 and "vote" or "votes" } ) } )
	else
		Core:Send( ply, "Print", { "Notification", Lang:Get( "RevokeFail" ) } )
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
		RTV.MapVotes[ nVote ] = RTV.MapVotes[ nVote ] + nAdd
		Core:Broadcast( "RTV", { "VoteList", RTV.MapVotes } )
	else
		if nVote < 1 or nVote > 7 or nOld < 1 or nOld > 7 then return end
		RTV.MapVotes[ nVote ] = RTV.MapVotes[ nVote ] + nAdd
		RTV.MapVotes[ nOld ] = RTV.MapVotes[ nOld ] - nAdd
		if RTV.MapVotes[ nOld ] < 0 then RTV.MapVotes[ nOld ] = 0 end
		Core:Broadcast( "RTV", { "VoteList", RTV.MapVotes } )
	end
end

function RTV:Check( ply )
	RTV.Required = math.ceil( #player.GetHumans() * ( 2 / 3 ) )
	local nVotes = RTV.Required - RTV.MapVotes
	Core:Send( ply, "Print", { "Notification", Lang:Get( "VoteCheck", { nVotes, nVotes == 1 and "vote" or "votes" } ) } )
end

function RTV:CheckTime( ply )
	local left = string.ToMinutesSeconds( RTV.MapEnd - CurTime() )
	RTV:Message( "Time remaining for the current map: " .. left, ply )
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


function RTV:Message( szText, ply )
	if IsValid( ply ) then
		Core:Send( ply, "Print", { "Notification", szText } )
	else
		Core:Broadcast( "Print", { "Notification", szText } )
	end
end

local EncodedData, EncodedLength
function RTV:GetMapList( ply, nVersion )
	if nVersion != RTV.MapListVersion then
		if not EncodedData or not EncodedLength then
			local TempList = {}
			for real,data in pairs( MapList ) do
				table.insert( TempList, { data[ 1 ] } ) -- Note / To-Do: Add more details here if necessary
			end
			
			EncodedData = util.Compress( util.TableToJSON( { TempList, RTV.MapListVersion } ) )
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

function RTV:MapExists( szName, szMap, bSoft )
	for real,data in pairs( MapList ) do
		if (bSoft and string.find( string.lower( data[ 1 ] ), string.lower( szName ), 1, true ) or data[ 1 ] == szName) or (szMap and real == szMap) then
			return real,data
		end
	end
end

function RTV:GetMapData( szMap )
	local exist = RTV:MapExists( nil, szMap, false )
	if not exist then
		return "", "Unknown map"
	else
		return exist
	end
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