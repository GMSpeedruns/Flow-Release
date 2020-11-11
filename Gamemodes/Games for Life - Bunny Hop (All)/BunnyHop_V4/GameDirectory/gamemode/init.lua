AddCSLuaFile( "sh_settings.lua" )
AddCSLuaFile( "sh_player.lua" )
AddCSLuaFile( "sh_movement.lua" )
AddCSLuaFile( "sh_view.lua" )
AddCSLuaFile( "cl_lang.lua" )
AddCSLuaFile( "cl_timer.lua" )
AddCSLuaFile( "cl_datatransfer.lua" )
AddCSLuaFile( "cl_gui.lua" )
AddCSLuaFile( "cl_spectator.lua" )
AddCSLuaFile( "cl_scoreboard.lua" )
AddCSLuaFile( "modules/cl_admin.lua" )

include( "sh_settings.lua" )
include( "sv_filesystem.lua" )
include( "sv_datatransfer.lua" )
include( "sv_player.lua" )
include( "sv_map.lua" )
include( "sv_timer.lua" )
include( "sv_records.lua" )
include( "sv_command.lua" )
include( "sv_rtv.lua" )
include( "sv_bot.lua" )
include( "sv_spectator.lua" )
include( "sv_reporting.lua" )
include( "modules/sv_admin.lua" )
include( "modules/sv_lj.lua" )


function GM:Initialize()
	FS:Init()
	Map:Init()
	Records:Init()
	Player:Init()
	RTV:Init()
	
	Command:Init()
	Admin:Init()
end

function GM:InitPostEntity()
	Map:Setup()
	timer.Simple( 5, function()
		Bot:Setup()
	end )
end

function GM:PlayerSpawn( ply )
	if ply:Team() == TEAM_SPECTATOR then return end

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
function GM:ShouldCollide(a, b) return not a:IsPlayer() and not b:IsPlayer() end

function GM:EntityTakeDamage( ent, dmg )
	if ent:IsPlayer() then return false end
	return self.BaseClass:EntityTakeDamage( ent, dmg )
end

function GM:PlayerCanPickupWeapon( ply, weapon )
	if weapon:GetClass() == "weapon_physgun" or ply.GunBlock then return false end
	if not ply:HasWeapon( weapon:GetClass() ) then
		ply:SetAmmo( 999, weapon:GetPrimaryAmmoType() )
		return true
	else
		return false
	end
end


gameevent.Listen( "player_connect" )
gameevent.Listen( "player_disconnect" )

hook.Add( "player_connect", "ConnectHook", function( data )
	if data.bot == 1 then
		Message:Global( "BotJoin", Config.Prefix.Bot, { Config.ModeNames[ Bot.NewMode ] } )
		Bot.NewMode = nil
	else
		Message:Global( "Connect", Config.Prefix.Game, { data.name } )
	end
end )

hook.Add( "player_disconnect", "LeaveHook", function( data )
	Message:Global( "Disconnect", Config.Prefix.Game, { data.name } )
end )