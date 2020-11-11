include( "core.lua" )
include( "core_lang.lua" )
include( "core_data.lua" )
include( "sv_round.lua" )
include( "sv_player.lua" )
include( "sv_command.lua" )
include( "sv_timer.lua" )
include( "sv_zones.lua" )
include( "modules/sv_rtv.lua" )
include( "modules/sv_admin.lua" )
include( "modules/sv_radio.lua" )

gameevent.Listen( "player_connect" )
Core:AddResources()

local function Startup()
	Core:Boot()
end
hook.Add( "Initialize", "Startup", Startup )

local function LoadEntities()
	Core:AwaitLoad()
end
hook.Add( "InitPostEntity", "LoadEntities", LoadEntities )

function GM:PlayerSpawn( ply )
	player_manager.SetPlayerClass( ply, "player_deathrun" )
	self.BaseClass:PlayerSpawn( ply )
	
	Player:Spawn( ply )
end

function GM:PlayerInitialSpawn( ply )
	Player:Load( ply )
end

function GM:PlayerCanHearPlayersVoice() return true end
function GM:IsSpawnpointSuitable() return true end
function GM:PlayerDeathThink() return false end
function GM:PhysgunPickup() return false end
function GM:AllowPlayerPickup() return false end

local NoDeathPickup
function GM:PlayerCanPickupWeapon( ply, weapon )
	if ply:HasWeapon( weapon:GetClass() ) then return false end
	if NoDeathPickup and ply:Team() == TEAM_DEATH then return false end
	if ply:Team() == TEAM_UNDEAD then return false end
	timer.Simple( 0.1, function()
		if IsValid( ply ) and IsValid( weapon ) then
			if isfunction( ply.SetAmmo ) and isfunction( weapon.GetPrimaryAmmoType ) then
				ply:SetAmmo( 999, weapon:GetPrimaryAmmoType() )
			end
		end
	end )
	
	return true
end

function Core:SetDeathPickup( bValue )
	NoDeathPickup = bValue
end

local rt, mr = RealTime, math.random
function GM:Tick()
	if Round:GetRound() != Round.ACTIVE then return end

	for _,p in pairs( player.GetHumans() ) do
		if p:WaterLevel() >= 3 then
			if not p.DrownTime then
				p.DrownTime = rt() + 10
				continue
			elseif p.DrownTime <= rt() then
				local dmg = DamageInfo()
				dmg:SetDamageType( DMG_DROWN )
				dmg:SetDamage( 15 )
				dmg:SetAttacker( game.GetWorld() )
				dmg:SetInflictor( game.GetWorld() )
				dmg:SetDamageForce( Vector( mr( -5, 5 ), mr( -2, 3 ), mr( -10, 9 ) ) )

				p:TakeDamageInfo( dmg )
				p.DrownTime = rt() + 3
			end
		elseif p.DrownTime then
			p.DrownTime = nil
		end
	end
end

function GM:EntityTakeDamage( target, dmg )
	if not IsValid( target ) then return end
	if target:Team() == TEAM_UNDEAD then return dmg:ScaleDamage( 0 ) end
	
	local attacker  = dmg:GetAttacker()
	local targetPlayer = target:IsPlayer()
	if not IsValid( attacker ) then
		local fall = (attacker and attacker.GetClass) and attacker:GetClass() == "worldspawn"
		if targetPlayer and target.DamageMultiplier and (fall and target.DamageType == 0) then
			dmg:ScaleDamage( target.DamageMultiplier )
		end
		
		return
	end
	
	local attackPlayer = attacker:IsPlayer()
	if attackPlayer and targetPlayer and target:Team() == attacker:Team() then
		dmg:ScaleDamage( 0 )
	elseif targetPlayer and not attackPlayer and target.DamageMultiplier then
		local fall = attacker:GetClass() == "suicide"
		if fall and target.DamageType == 0 then
			dmg:ScaleDamage( target.DamageMultiplier )
		end
	end
end

function GM:CanPlayerSuicide( ply )
	if not IsValid( ply ) or not ply:Alive() then return false end
	
	if ply:Team() == TEAM_DEATH or ply:Team() == TEAM_SPECTATOR then return false end
	if Round:GetRound() == Round.PREPARING or Round:GetRound() == Round.WAITING then return false end
	
	return self.BaseClass:CanPlayerSuicide( ply )
end

function GM:GetFallDamage( ply, speed )
	-- To-Do: Find the right balance here - On public DR gamemode it's 8
	return speed / 8
end

function GM:DoPlayerDeath( ply, attacker, cinfo )
	if not IsValid( ply ) then return end
	self.BaseClass:DoPlayerDeath( ply, attacker, cinfo )
	
	local wep = ply:GetActiveWeapon()
	if IsValid( wep ) then
		ply.LastWeapon = wep:GetClass()
	else
		ply.LastWeapon = nil
	end
	
	local num = 0
	local last = nil
	
	for _,p in pairs( player.GetHumans() ) do
		if ply == p then continue end
		local ob = p:GetObserverTarget()
		if IsValid( ob ) and ob == ply then
--			p:SetTeam( TEAM_SPECTATOR )
			p:Spectate( OBS_MODE_ROAMING )
			p:SpectateEntity()
			p:SetPos( ply:EyePos() )
		end
		
		if p:Team() == ply:Team() and p:Alive() then
			num = num + 1
			
			if not p.HasPressedKey then
				last = p
			end
		end
	end
	
	if num == 1 and IsValid( last ) and Round:GetRoundTime() < Round.ROUND_TIME - 20 then
		local t = last:Team()
		timer.Simple( 1, function()
			if not IsValid( last ) or not last:Alive() or last:Team() != t then return end
			
			last:Kill()
			Core:Broadcast( "Print", { "Deathrun", Lang:Get( "AFKKill", { last:Name(), " as last player" } ) } )
		end )
	end

	ply.DeathUnspec = CurTime() + 2
end

local SpectatorKeys = { [IN_ATTACK] = true, [IN_ATTACK2] = true, [IN_RELOAD] = true, [IN_DUCK] = true }
function GM:KeyPress( ply, key )
	if not IsValid( ply ) then return end
	
	if not ply.HasPressedKey then
		ply.HasPressedKey = true
	end
	
	if ply:Alive() then return end
	if SpectatorKeys[ key ] then
		Spectator:Trigger( ply, key )
	end
end