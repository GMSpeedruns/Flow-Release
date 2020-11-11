Player = {}
local PlayerCache = {}
local ConnectionTimes = {}
local TopList = {}

function Player:Init()
	local cached = 0
	
	local files = file.Find( FS.Folders.Players .. "data_*.txt", FS.Main, "datedesc" )
	for _, file in pairs( files ) do
		if cached > 500 then break end
	
		local content = FS:Load( file, FS.Folders.Players )
		local uid = string.sub( string.StripExtension( file ), 6 )

		PlayerCache[ uid ] = FS.Deserialize:Player( content )
		cached = cached + 1
	end

	local TempList = {}
	for _, p in pairs( PlayerCache ) do
		if not p.LastConnectedAs then continue end
		table.insert( TempList, { Name = p.LastConnectedAs, Points = p.Points, Rank = p.Rank, PlayCount = p.PlayCount, ConnectionTime = Timer:LongConvert( p.ConnectionTime or 0 ) } )
	end
	
	table.SortByMember( TempList, "Points" )

	TopList = {}
	local nAdded = 0
	for _, v in pairs( TempList ) do
		if nAdded >= 50 then break end
		table.insert( TopList, v )
		nAdded = nAdded + 1
	end
end

function Player:Save()
	for uid, plyData in pairs( PlayerCache ) do
		if not plyData.Modified then continue end
		plyData.Modified = nil
		
		if plyData.ConnectionTime and plyData.ConnectionTime > 0 then
			local nTime = plyData.ConnectionTime or 0
			local nNewTime = nTime + CurTime() - (ConnectionTimes[ uid ] or CurTime())
			plyData.ConnectionTime = math.floor( nNewTime )
			ConnectionTimes[ uid ] = CurTime()
		end
		
		local szData = FS.Serialize:Player( plyData )
		FS:Write( "data_" .. uid .. ".txt", FS.Folders.Players, szData )
	end
end


function Player:Spawn( ply )
	if not IsValid( ply ) then return end

	ply:SetModel( Config.Player.DefaultModel )
	ply:SetTeam( TEAM_HOP )
	ply:SetJumpPower( Config.Player.JumpPower )
	ply:SetHull( Config.Player.HullMin, Config.Player.HullStand )
	ply:SetHullDuck( Config.Player.HullMin, Config.Player.HullDuck )
	ply:SelectWeapon( Config.Player.DefaultWeapon )
	ply:SetNoCollideWithTeammates( true )
	ply:SetAvoidPlayers( false )
	ply:ResetTimer()
	
	Player:SpawnChecks( ply )
end

function Player:SpawnChecks( ply )
	SetPlayerJumps( ply, 0 )
	
	if Map.StepSize then
		ply:SetStepSize( Map.StepSize )
	end
	
	if Map.Spawn then
		local Variation = Vector( math.random( -50, 50 ), math.random( -50, 50 ), 0 )
		local x, y = math.Clamp( (Map.Current.StartB.x - Map.Current.StartA.x) / 2 - 16, 0, 100 ), math.Clamp( (Map.Current.StartB.y - Map.Current.StartA.y) / 2 - 16, 0, 100 )
		Variation = Vector( math.random( -x, x ), math.random( -y, y ), 0 )
		
		ply:SetPos( Map.Spawn + Variation )
	end
	
	if Map.Bonus and ply.Mode == Config.Modes["Bonus"] then
		local Variation = Vector( math.random( -50, 50 ), math.random( -50, 50 ), 0 )
		ply:SetPos( Map.Bonus + Variation )
		
		if Map.BonusAngles then
			ply:SetEyeAngles( Map.BonusAngles )
		end
	end
	
	if not ply:IsBot() and ply:GetMoveType() != MOVETYPE_WALK  then
		ply:SetMoveType( MOVETYPE_WALK )
	end
end

function Player:Load( ply )
	ply:SetTeam( TEAM_HOP )
	ply.Mode = Config.Modes["Auto"]
	ply.ThirdPerson = 0
	ply.CurrentRecord = 0
	ply.RankID = -2

	ply:SetNWInt( "Rank", ply.RankID )
	ply:SetNWInt( "Mode", ply.Mode )
	ply:SetNWInt( "Record", ply.CurrentRecord )
	
	if not ply:IsBot() then
		Player:GetProfile( ply )
		Bot:TestPlayers()
		
		if Bot.Force.All then
			Bot:CreateHook()
			Bot:RecordRestart( ply, true )
		elseif Player:GetProfileParam( ply, "BotRecord", 0 ) == 1 then
			Bot:CreateHook()
			Bot:RecordRestart( ply, true )
		end
		
		ConnectionTimes[ ply:UniqueID() ] = CurTime()
		
		local nPlays = Player:GetProfileParam( ply, "PlayCount", 0 ) + 1
		Player:SetProfileParam( ply, "PlayCount", nPlays )
		Player:SetProfileParam( ply, "LastConnectedAs", ply:Name() )
		
		Player:SetProfileParam( ply, "AccessFlags", nil )
		Player:SetProfileParam( ply, "SteamID", ply:SteamID() )
		
		Records:SendFirst( ply )
	else
		ply.Mode = Config.Modes["Practice"]
	end
end

function Player:LoadMode( ply )
	ply.CurrentRecord = 0

	ply:SetNWInt( "Mode", ply.Mode )
	ply:SetNWInt( "Record", ply.CurrentRecord )
	
	Command.Restart( ply )
	Records:LoadPlayer( ply )
end

function GM:PlayerDisconnected( ply )
	Message:Global( "Disconnect", Config.Prefix.Game, { ply:Name() } )
	
	local nTime = Player:GetProfileParam( ply, "ConnectionTime", 0 )
	local nNewTime = nTime + CurTime() - (ConnectionTimes[ ply:UniqueID() ] or CurTime())
	Player:SetProfileParam( ply, "ConnectionTime", math.floor( nNewTime ) )
	ConnectionTimes[ ply:UniqueID() ] = nil
	
	if #player.GetAll() - 1 == 1 then
		Bot:Save()
	end

	if ply.Spectating then
		Spectator:End( ply, ply:GetObserverTarget() )
		ply.Spectating = false
	end

	if RTV.VotePossible then return end
	if ply.Rocked then
		RTV.MapVotes = RTV.MapVotes - 1
	end
	
	local Count = #player.GetHumans()
	if Count <= 1 then return else Count = Count - 1 end
	
	RTV.Required = math.ceil( Count * ( 2 / 3 ) )
	if RTV.MapVotes >= RTV.Required then
		RTV:StartVote()
	end
end

function Player:GetProfile( ply )
	local uid = ply:UniqueID()

	if not PlayerCache[ uid ] then
		local szFile = FS:Load( "data_" .. uid .. ".txt", FS.Folders.Players )
		if not szFile or szFile == "" then
			local DefaultTable = { Rank = 1, Points = 0, PlayCount = 0, BotRecord = 0, LastConnectedAs = ply:Name() }
			FS:Write( "data_" .. uid .. ".txt", FS.Folders.Players, FS.Serialize:Player( DefaultTable ) )
			PlayerCache[ uid ] = DefaultTable
		else
			PlayerCache[ uid ] = FS.Deserialize:Player( szFile )
		end
	end

	ply.RankID = PlayerCache[ uid ].Rank
	ply:SetNWInt( "Rank", ply.RankID )
	
	local plyRecord = Records:GetPlayer( uid, ply.Mode )
	if plyRecord then
		ply.CurrentRecord = plyRecord.Time
		ply:SetNWInt( "Record", ply.CurrentRecord )
		ply:SendLua( "Timer:SetRecord(" .. ply.CurrentRecord .. ")" )
	end
end

function Player:GetProfileParam( ply, szParam, varDefault )
	if not PlayerCache[ ply:UniqueID() ] then
		Player:GetProfile( ply )
	end
	
	return PlayerCache[ ply:UniqueID() ][ szParam ] or varDefault
end

function Player:SetProfileParam( ply, szParam, varValue )
	if not PlayerCache[ ply:UniqueID() ] then
		Player:GetProfile( ply )
	end

	PlayerCache[ ply:UniqueID() ][ szParam ] = varValue
	PlayerCache[ ply:UniqueID() ].Modified = true
end


function Player:AddRankPoints( ply, nPoints )
	local nCurrent = Player:GetProfileParam( ply, "Points", 0 )
	local nUpdated = nCurrent + (nPoints or 0)
	Player:SetProfileParam( ply, "Points", nUpdated )
	
	local nCurrentRank = Player:GetProfileParam( ply, "Rank", 1 )
	local nNewRank = Player:CalculateRank( nUpdated )

	if nCurrentRank != nNewRank then
		Player:SetProfileParam( ply, "Rank", nNewRank )
		
		ply.RankID = nNewRank
		ply:SetNWInt( "Rank", ply.RankID )
	end
end

function Player:CalculateRank( nPoints )
	local Rank = 1
	
	for RankID, Data in pairs( Config.Ranks ) do
		if RankID > Rank and nPoints >= Data[3] then
			Rank = RankID
		end
	end
	
	return Rank
end


local HasTopList = {}
function Player:GetTop( ply )
	if not HasTopList[ ply ] then
		HasTopList[ ply ] = true
		return TopList
	else
		return nil
	end
end