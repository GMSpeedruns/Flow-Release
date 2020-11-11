include( "core.lua" )
include( "core_lang.lua" )
include( "core_data.lua" )
include( "sv_player.lua" )
include( "sv_command.lua" )
include( "sv_timer.lua" )
include( "sv_zones.lua" )
include( "modules/sv_rtv.lua" )
include( "modules/sv_admin.lua" )
include( "modules/sv_bot.lua" )
include( "modules/sv_spectator.lua" )
include( "modules/sv_radio.lua" )
include( "modules/sv_smgr.lua" )
include( "modules/sv_stats.lua" )

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
	player_manager.SetPlayerClass( ply, "player_bhop" )
	self.BaseClass:PlayerSpawn( ply )
	
	Player:Spawn( ply )
end

function GM:PlayerInitialSpawn( ply )
	Player:Load( ply )
end

function GM:CanPlayerSuicide() return false end
function GM:PlayerShouldTakeDamage() return false end
function GM:GetFallDamage() return false end
function GM:PlayerCanHearPlayersVoice() return true end
function GM:IsSpawnpointSuitable() return true end
function GM:PlayerDeathThink( ply ) end

function GM:PlayerCanPickupWeapon( ply, weapon )
	if ply.WeaponStripped then return false end
	if ply:HasWeapon( weapon:GetClass() ) then return false end
	if ply:IsBot() then return false end
	
	timer.Simple( 0.1, function()
		if IsValid( ply ) and IsValid( weapon ) then
			ply:SetAmmo( 999, weapon:GetPrimaryAmmoType() )
		end
	end )
	
	return true
end

function GM:EntityTakeDamage( ent, dmg )
	if ent:IsPlayer() then return false end
	return self.BaseClass:EntityTakeDamage( ent, dmg )
end