RTV = {}
RTV.VotePossible = false
RTV.DefaultExtend = 15
RTV.Nominations = {}
RTV.LatestList = {}

RTV.MapLength = 120 * 60
RTV.MapInit = 0
RTV.MapEnd = 0
RTV.MapVotes = 0
RTV.MapVoteList = { 0, 0, 0, 0, 0, 0 }

local RTVTempList = {}

function RTV:Init()
	if timer.Exists( "MapCountdown" ) then
		timer.Delete( "MapCountdown" )
	end
	
	timer.Create( "MapCountdown", RTV.MapLength, 1, RTV.StartVote )
	
	RTV.MapInit = CurTime()
	RTV.MapEnd = RTV.MapInit + RTV.MapLength
	RTV:CheckLatest()
end

function RTV:StartVote()
	if RTV.VotePossible then return end
	RTV.VotePossible = true
	RTV.Selections = {}
	Message:Global( "VoteStart", Config.Prefix.Vote )

	RTVTempList = {}
	for map, voters in pairs( RTV.Nominations ) do
		local nCount = #voters
		if not RTVTempList[ nCount ] then
			RTVTempList[ nCount ] = { map }
		else
			table.insert( RTVTempList[ nCount ], map )
		end
	end

	local Added = 0
	for i = 64, 1, -1 do
		if RTVTempList[ i ] then
			for _, map in pairs( RTVTempList[ i ] ) do
				if Added > 4 then break end
				table.insert( RTV.Selections, map )
				Added = Added + 1
			end
		end
	end
	
	if Added < 5 and Map.ServerList and type( Map.ServerList ) == "table" then
		for map, _ in RandomPairs( Map.ServerList ) do
			if Added > 4 then break end
			if table.HasValue( RTV.Selections, map ) then continue end
			if table.HasValue( RTV.LatestList, map ) then continue end
			if map != game.GetMap() then
				table.insert( RTV.Selections, map )
				Added = Added + 1
			end
		end
	end
	
	Data:Global( "VoteList", RTV.Selections )
	timer.Simple( 31, function() RTV:EndVote() end )
end

function RTV:EndVote()
	RTV.VotePossible = false
	FS:Finalize()
	
	local nMax, nWin = 0, -1
	for i = 1, 6 do
		if RTV.MapVoteList[i] > nMax then
			nMax = RTV.MapVoteList[i]
			nWin = i
		end
	end
	
	if nWin <= 0 then
		nWin = math.random(1, 5)
	elseif nWin == 6 then
		Message:Global( "MapExtend", Config.Prefix.Game, { RTV.DefaultExtend } )
		
		RTV.VotePossible = false
		RTV.Nominations = {}
		RTV.Selections = {}
		
		RTV.MapInit = CurTime()
		RTV.MapEnd = RTV.MapInit + (RTV.DefaultExtend * 60)
		RTV.MapVotes = 0
		RTV.MapVoteList = { 0, 0, 0, 0, 0, 0 }
		
		for _, p in pairs( player.GetHumans() ) do
			if p.Rocked then p.Rocked = nil end
			if p.NominatedMap then p.NominatedMap = nil end
		end
		
		timer.Simple( RTV.DefaultExtend * 60, function() RTV:StartVote() end )
		return
	end
	
	local szMap = RTV.Selections[ nWin ]
	if not szMap or not type( szMap ) == "string" then return end
	
	Message:Global( "MapChange", Config.Prefix.Game, { szMap } )
	timer.Simple( 5, function() RunConsoleCommand( "changelevel", szMap ) end )
end


function RTV:Vote( ply )
	if ply.RTVLimit and CurTime() - ply.RTVLimit < 60 then
		return Message:Single( ply, "VoteLimit", Config.Prefix.Vote, { math.ceil( 60 - (CurTime() - ply.RTVLimit) ) } )
	elseif ply.Rocked then
		return Message:Single( ply, "Voted", Config.Prefix.Vote )
	elseif RTV.VotePossible then
		return Message:Single( ply, "VotePeriod", Config.Prefix.Vote )
	end
	
	ply.RTVLimit = CurTime()
	ply.Rocked = true
	
	RTV.MapVotes = RTV.MapVotes + 1
	RTV.Required = math.ceil( #player.GetHumans() * ( 2 / 3 ) )
	Message:Global( "Vote", Config.Prefix.Vote, { ply:Name(), RTV.Required - RTV.MapVotes } )
	
	if RTV.MapVotes >= RTV.Required then
		RTV:StartVote()
	end
end

function RTV:Revoke( ply )
	if RTV.VotePossible then
		return Message:Single( ply, "VotePeriod", Config.Prefix.Vote )
	end

	if ply.Rocked then
		ply.Rocked = false
		
		RTV.MapVotes = RTV.MapVotes - 1
		RTV.Required = math.ceil( #player.GetHumans() * ( 2 / 3 ) )
		Message:Global( "Revoke", Config.Prefix.Vote, { ply:Name(), RTV.Required - RTV.MapVotes } )
	else
		Message:Single( ply, "RevokeFail", Config.Prefix.Vote )
	end
end

function RTV:Nominate( ply, szMap )
	local szIdentifier = "Nominate"
	local varArgs = { ply:Name(), szMap }
	
	if table.HasValue( RTV.LatestList, szMap ) then
		Message:Single( ply, "RecentlyPlayed", Config.Prefix.Vote )
		return
	end
	
	if ply.NominatedMap and ply.NominatedMap != szMap then
		if RTV.Nominations[ ply.NominatedMap ] then
			for id, p in pairs( RTV.Nominations[ ply.NominatedMap ] ) do
				if p == ply then
					table.remove( RTV.Nominations[ ply.NominatedMap ], id )
					if #RTV.Nominations[ ply.NominatedMap ] == 0 then
						RTV.Nominations[ ply.NominatedMap ] = nil
					end
					
					szIdentifier = "NominateChange"
					varArgs = { ply:Name(), ply.NominatedMap, szMap }
					break
				end
			end
		end
	elseif ply.NominatedMap and ply.NominatedMap == szMap then
		return Message:Single( ply, "AlreadyNominate", Config.Prefix.Vote )
	end

	if not RTV.Nominations[ szMap ] then
		RTV.Nominations[ szMap ] = { ply }
		ply.NominatedMap = szMap
		Message:Global( szIdentifier, Config.Prefix.Vote, varArgs )
	elseif type( RTV.Nominations ) == "table" then
		local Included = false
		for _, p in pairs( RTV.Nominations[ szMap ] ) do
			if p == ply then Included = true break end
		end
		
		if not Included then
			table.insert( RTV.Nominations[ szMap ], ply )
			ply.NominatedMap = szMap
			Message:Global( szIdentifier, Config.Prefix.Vote, varArgs )
		else
			return Message:Single( ply, "AlreadyNominate", Config.Prefix.Vote )
		end
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
	Message:Single( ply, "VoteWho", Config.Prefix.Vote, { RTV.Required, #Voted, string.Implode( ", ", Voted ), #NotVoted, string.Implode( ", ", NotVoted ) } )
end

function RTV:Check( ply )
	RTV.Required = math.ceil( #player.GetHumans() * ( 2 / 3 ) )
	Message:Single( ply, "VoteCheck", Config.Prefix.Vote, { RTV.Required - RTV.MapVotes } )
end

function RTV:CheckLatest()
	if not file.Exists( FS.Folders.Log .. "LatestMaps.txt", FS.Main ) then
		file.Write( FS.Folders.Log .. "LatestMaps.txt", "A;B;C" )
	end
	
	local szLatest = file.Read( FS.Folders.Log .. "LatestMaps.txt", FS.Main )
	if not szLatest or szLatest == "" then return end
	local Split = string.Explode( ";", szLatest )
	if #Split != 3 then return end
	RTV.LatestList = Split
	table.insert( Split, 1, game.GetMap() )
	table.remove( Split, 4 )
	file.Write( FS.Folders.Log .. "LatestMaps.txt", string.Implode( ";", Split ) )
end