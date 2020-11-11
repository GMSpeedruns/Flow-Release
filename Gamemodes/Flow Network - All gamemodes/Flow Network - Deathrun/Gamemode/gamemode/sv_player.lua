Player = {}

function Player:Spawn( ply )
	if not IsValid( ply ) then return end
	
	-- To-Do: Load them PointShop models here
	ply:SetModel( _C["Player"].DefaultModel )
	ply:SetJumpPower( _C["Player"].JumpPower )
	ply:SetHull( _C["Player"].HullMin, _C["Player"].HullStand )
	ply:SetHullDuck( _C["Player"].HullMin, _C["Player"].HullDuck )
	ply:SetNoCollideWithTeammates( true )
	ply:SetAvoidPlayers( false )
	
	ply:SetHealth( ply:GetMaxHealth() )
	ply:AllowFlashlight( true )
	ply:SetArmor( 0 )
	
	Player:SpawnChecks( ply )
end

-- Called when the player spawns or exceeds the start zone speed
function Player:SpawnChecks( ply )
	Core.Util:SetPlayerJumps( ply, 0 )
	Core.Util:SetSpeedCap( ply, _C.Player.BaseLimit )
	
	if ply:GetMoveType() != MOVETYPE_WALK then
		ply:SetMoveType( MOVETYPE_WALK )
	end
	
	if ply:Team() == TEAM_SPECTATOR then
		return ply:Spectate( OBS_MODE_ROAMING )
	else
		if ply:Team() == TEAM_DEATH then
			ply:SetWalkSpeed( _C.Player.FastSpeed )
			ply:SetRunSpeed( _C.Player.FastSpeed )
		else
			ply:SetWalkSpeed( _C.Player.WalkSpeed )
			ply:SetRunSpeed( _C.Player.WalkSpeed )
		end
		
		if ply:Team() == TEAM_UNDEAD then
			if #player.GetHumans() > 1 then
				ply:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
			else
				ply:SetCollisionGroup( COLLISION_GROUP_PLAYER )
				
				game.CleanUpMap()
				Zones:Setup()
			end
		end
	end
	
	ply.HasPressedKey = false
	
	local spawnName = ply:Team() == TEAM_DEATH and "info_player_terrorist" or "info_player_counterterrorist"
	local spawns = ents.FindByClass( spawnName )
	if #spawns > 0 then
		ply.SpawnPosition = table.Random( spawns ):GetPos()
		ply:SetPos( ply.SpawnPosition )
	end
	
	if ply.GetLoadout then
		Player:Loadout( ply )
		ply.GetLoadout = nil
		
		if ply.LastWeapon and ply:HasWeapon( ply.LastWeapon ) then
			ply:SelectWeapon( ply.LastWeapon )
		end
		
		ply.LastWeapon = nil
	end
	
	ply:ResetTimer()
end


function Player:Load( ply )
	Core:Broadcast( "Print", { "General", Lang:Get( "Connect", { ply:Name(), ply:SteamID() } ) } )
	
	if not SQL.Available and CurTime() - RTV.MapInit > 10 then
		return timer.Simple( 1, function()
			ply.DCReason = "No connection to master server"
			ply:Kick( "No connection to master server. Please try reconnecting!" )
		end )
	end
	
	ply.SpeedCap = _C.Player.BaseLimit
	
	Player:LoadPlayer( ply )
	
	if Round:GetRound() == Round.PREPARING then
		ply:SetTeam( TEAM_RUNNER )
		ply:Spawn()
	else
		ply:SetTeam( TEAM_RUNNER )
		ply:KillSilent()
		ply:Spectate( OBS_MODE_ROAMING )
		
		local target = Spectator:GetNextPlayer( ply:GetObserverTarget() )
		if IsValid( target ) then
			ply:Spectate( ply.SpectateType or OBS_MODE_CHASE )
			ply:SpectateEntity( target )
		end
	end
	
	Admin:CheckPlayerStatus( ply )
end

function Player:Sort()
	local ar = Player:GetAvailablePlayers()
	local pool = {}
	for _,p in pairs( ar ) do
		if p:Team() == TEAM_DEATH then
			table.insert( pool, p )
		end
		
		p:SetTeam( TEAM_SPECTATOR )
	end
	
	local pool2 = {}
	for _,p in RandomPairs( ar ) do
		local stop = false
		
		if Player:DeathRequired( ar ) then
			if not table.HasValue( pool, p ) then
				p:SetTeam( TEAM_DEATH )
			else
				table.insert( pool2, p )
				stop = true
			end
		else
			p:SetTeam( TEAM_RUNNER )
		end
		
		if not stop then
			p:Spawn()
		end
	end

	if #pool2 > 0 then
		for _,p in RandomPairs( pool2 ) do
			if not IsValid( p ) then continue end
			if Player:DeathRequired( ar ) then
				p:SetTeam( TEAM_DEATH )
				Core:Send( p, "Print", { "Deathrun", Lang:Get( "DeathRequired" ) } )
			else
				p:SetTeam( TEAM_RUNNER )
			end
			
			p:Spawn()
		end
	end
	
	for _,p in pairs( player.GetHumans() ) do
		p:Freeze( true )
	end
end

function Player:Loadout( ply )
	ply:StripWeapons()
	
	ply:Give( "weapon_crowbar" )
	ply:Give( "weapon_knife" )
end

function Player:DeathRequired( ar )
	local count = #ar
	local deaths = #team.GetPlayers( TEAM_DEATH )
	
	local need = math.floor( math.Clamp( count * 0.25, 1, 6 ) )
	if deaths >= need then
		return false
	end
	
	return true
end

function Player:CountAlive( t )
	local c = 0
	
	for _,p in pairs( team.GetPlayers( t ) ) do
		if p:Alive() then
			c = c + 1
		end
	end
	
	return c
end

function Player:GetAvailablePlayers()
	local tab = player.GetHumans()
	local specs = {}
	local nonspecs = {}
	
	for _,p in pairs( tab ) do
		if p:Team() == TEAM_SPECTATOR then
			table.insert( specs, p )
		else
			table.insert( nonspecs, p )
		end
	end
	
	if #nonspecs < 2 then
		for _,p in pairs( specs ) do
			table.insert( nonspecs, p )
		end
	end
	
	return nonspecs
end

function Player:SpawnUndead( ply, spawn )
	ply:SetTeam( TEAM_UNDEAD )
	
	if spawn then
		ply.GetLoadout = true
		ply:Spawn()
	else
		local target = Spectator:GetNextPlayer( ply:GetObserverTarget() )
		if IsValid( target ) then
			ply:Spectate( ply.SpectateType or OBS_MODE_CHASE )
			ply:SpectateEntity( target )
		end
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

function Player:AddScore( ply )
	ply:AddFrags( 1 )
	
	if ply.PS_GivePoints then
		ply:PS_GivePoints( 10 )
	end
end

-- RANKING
function Player:Init()
	if not sql.TableExists( "dr_players" ) then
		sql.Query( "CREATE TABLE dr_players (\"szID\" TEXT NOT NULL, \"nRank\" INTEGER NOT NULL DEFAULT 0, \"nJoins\" INTEGER NOT NULL DEFAULT 1, \"nMinutes\" INTEGER NOT NULL DEFAULT 0, \"szData\" TEXT NULL, PRIMARY KEY (\"szID\"))" )
	end
end

function Player:LoadPlayer( ply )
	ply.ConnectedAt = CurTime()
	ply.Rank = 1
	
	local Fetch = sql.Query( "SELECT * FROM dr_players WHERE szID = '" .. ply:SteamID() .. "'" )
	if Core:Assert( Fetch, "nRank" ) then
		ply.Rank = tonumber( Fetch[ 1 ]["nRank"] )
		ply.PlayTime = tonumber( Fetch[ 1 ]["nMinutes"] )
		ply.JoinAmount = tonumber( Fetch[ 1 ]["nJoins"] ) + 1
		
		sql.Query( "UPDATE dr_players SET nJoins = nJoins + 1 WHERE szID = '" .. ply:SteamID() .. "'" )
	else
		ply.Rank = 1
		ply.PlayTime = 0
		ply.JoinAmount = 1
	
		sql.Query( "INSERT INTO dr_players (szID, nRank, nJoins, nMinutes) VALUES ('" .. ply:SteamID() .. "', " .. ply.Rank .. ", " .. ply.JoinAmount .. ", " .. ply.PlayTime .. ")" )
		Core:Broadcast( "Print", { "General", Lang:Get( "ConnectFirst", { ply:Name() } ) } )
	end
	
	ply:SetNWInt( "Rank", ply.Rank )
end


Spectator = {}

local function GetAlivePlayers()
	local pool = {}
	
	for _,p in pairs( player.GetHumans() ) do
		if not p:Alive() then continue end
		table.insert( pool, p )
	end
	
	return pool
end

local function GetPreviousPlayer( ob )
	local ar = GetAlivePlayers()
	if #ar == 0 then return end
	if not IsValid( ob ) then return ar[ 1 ] end
	
	local last
	for _,p in pairs( ar ) do
		if p == ob then
			return last or ar[ #ar ]
		end
		
		last = p
	end
	
	if not IsValid( last ) then
		return ar[ #ar ]
	end
	
	return last
end

local function GetNextPlayer( ob )
	local ar = GetAlivePlayers()
	if #ar == 0 then return end
	if not IsValid( ob ) then return ar[ 1 ] end
	
	local last, new
	for _,p in pairs( ar ) do
		if last == ob then
			new = p
		end
		
		last = p
	end
	
	if not IsValid( new ) then
		return ar[ 1 ]
	end
	
	return new
end

function Spectator:Trigger( ply, key )
	local ob = ply:GetObserverTarget()
	if not ply.DeathUnspec then
		return Spectator:Function( ply, key )
	end
	
	if ply.DeathUnspec >= CurTime() then return end
	ply.DeathUnspec = nil
	
	if key == IN_ATTACK and ply:Team() == TEAM_UNDEAD then
		ply.GetLoadout = true
		ply:Spawn()
	else
		ply:Spectate( OBS_MODE_ROAMING )
		ply:SpectateEntity( nil )
	end
end

function Spectator:Function( ply, key )
	if key == IN_ATTACK then
		if ply:Team() == TEAM_UNDEAD then
			ply.GetLoadout = true
			return ply:Spawn()
		end
		
		local target = GetNextPlayer( ply:GetObserverTarget() )
		if IsValid( target ) then
			ply:Spectate( ply.SpectateType or OBS_MODE_CHASE )
			ply:SpectateEntity( target )
		end
	elseif key == IN_ATTACK2 then
		local target = GetPreviousPlayer( ply:GetObserverTarget() )
		if IsValid( target ) then
			ply:Spectate( ply.SpectateType or OBS_MODE_CHASE )
			ply:SpectateEntity( target )
		end
	elseif key == IN_RELOAD then
		local target = ply:GetObserverTarget()
		if not IsValid( target ) or not target:IsPlayer() then return end
		
		if not ply.SpectateType or ply.SpectateType == OBS_MODE_CHASE then
			ply.SpectateType = OBS_MODE_IN_EYE
		elseif ply.SpectateType == OBS_MODE_IN_EYE then
			ply.SpectateType = OBS_MODE_CHASE
		end
		
		ply:Spectate( ply.SpectateType )
		ply:SpectateEntity( target )
	elseif key == IN_DUCK then
		local pos = ply:GetPos()
		local target = ply:GetObserverTarget()
		
		if IsValid( target ) and target:IsPlayer() then
			pos = target:EyePos()
		end
		
		ply:Spectate( OBS_MODE_ROAMING )
		ply:SpectateEntity()
		ply:SetPos( pos )
	end
end

function Spectator:SpawnAs( ply )
	ply:KillSilent()
	GAMEMODE:PlayerSpawnAsSpectator( ply )
	
	ply.Spectating = true
	ply:SetTeam( TEAM_SPECTATOR )
end

function Spectator:GetNextPlayer( ply )
	return GetNextPlayer( ply )
end

function Spectator:Command( ply, arg, confirm )
	if not IsValid( ply ) then return end	
	if ply:Alive() and ply:Team() == TEAM_DEATH then
		return Core:Send( ply, "Print", { "Deathrun", Lang:Get( "SpectateAsDeath" ) } )
	elseif ply:Team() == TEAM_RUNNER and Player:CountAlive( TEAM_RUNNER ) < 2 then
		return Core:Send( ply, "Print", { "Deathrun", Lang:Get( "SpectateAsLast" ) } )
	end

	if not arg then
		if confirm then
			return Core:Send( ply, "GUI_Open", { "Spectate" } )
		end
		
		if ply:Team() != TEAM_SPECTATOR then
			Spectator:SpawnAs( ply )
			
			local target = GetNextPlayer( ply:GetObserverTarget() )
			if IsValid( target ) then
				ply:Spectate( ply.SpectateType or OBS_MODE_CHASE )
				ply:SpectateEntity( target )
			end
		else
			local r, spawn = Round:GetRound(), false
			if r != Round.ACTIVE and r != Round.ENDING then spawn = true end
			Player:SpawnUndead( ply, spawn )
		end
	else
		local ar, target, tname = GetAlivePlayers()
		for _,p in pairs( ar ) do
			if string.find( string.lower( p:Name() ), string.lower( arg ), 1, true ) then
				target = p:SteamID()
				tname = p:Name()
				break
			end
		end
		
		if IsValid( target ) and target:Team() != TEAM_SPECTATOR then
			Spectator:SpawnAs( ply )
			ply:Spectate( ply.SpectateType or OBS_MODE_CHASE )
			ply:SpectateEntity( target )
		else
			Core:Send( ply, "Print", { "General", Lang:Get( "SpectateTargetInvalid" ) } )
		end
	end
end


local PlayerJumps, J1, J2 = {}, _C.Player.JumpPower, _C.Player.HighJump
local function PlayerGround( ply, bWater )
	if not IsValid( ply ) then return end
	
	ply:SetJumpPower( J1 )
	timer.Simple( 0.3, function() if IsValid( ply ) and isfunction( ply.SetJumpPower ) and J2 then ply:SetJumpPower( J2 ) end end )
	
	if PlayerJumps[ ply ] then
		PlayerJumps[ ply ] = PlayerJumps[ ply ] + 1
	end
end
hook.Add( "OnPlayerHitGround", "HitGround", PlayerGround )

function Core.Util:GetPlayerJumps( ply )
	return PlayerJumps[ ply ] or 0
end

function Core.Util:SetPlayerJumps( ply, nValue )
	PlayerJumps[ ply ] = nValue
end


-- CONNECTION
local function PlayerDisconnect( ply )
	Core:Broadcast( "Print", { "General", Lang:Get( "Disconnect", { ply:Name(), ply:SteamID(), ply.DCReason or "Player left" } ) } )
	
	if ply.ConnectedAt then
		local dt = math.Round( (CurTime() - ply.ConnectedAt) / 60 )
		sql.Query( "UPDATE dr_players SET nMinutes = nMinutes + " .. dt .. " WHERE szID = '" .. ply:SteamID() .. "'" )
	end
	
	if #player.GetHumans() - 1 < 1 then
		Core:Unload()
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