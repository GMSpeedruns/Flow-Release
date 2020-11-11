-- Shared file containing all essential information

GM.Name = "Deathrun"
GM.DisplayName = "Flow Deathrun"
GM.Author = "Gravious"
GM.Email = ""
GM.Website = ""

DeriveGamemode( "base" )
DEFINE_BASECLASS( "gamemode_base" )

_C = _C or {}
_C["Version"] = 1.00
_C["PageSize" ] = 7

_C["Player"] = {
	DefaultModel = "models/player/group01/male_01.mdl",
	JumpPower = 268.4,
	HighJump = 300,
	WalkSpeed = 300,
	FastSpeed = 350,
	BaseLimit = 700,
	HullMin = Vector( -16, -16, 0 ),
	HullDuck = Vector( 16, 16, 45 ),
	HullStand = Vector( 16, 16, 62 ),
	ViewDuck = Vector( 0, 0, 47 ),
	ViewStand = Vector( 0, 0, 64 )
}

_C["Prefixes"] = {
	["Deathrun"] = Color( 52, 73, 94 ),
	["General"] = Color( 52, 152, 219 ),
	["Admin"] = Color( 76, 60, 231 ),
	["Notification"] = Color( 231, 76, 60 ),
	["Flow Network"] = Color( 46, 204, 113 ),
	["Radio"] = Color( 230, 126, 34 ),
	["VIP"] = Color( 174, 0, 255 )
}

_C["Ranks"] = {
	[-1] = { "Retrieving...", Color( 255, 255, 255 ) },
	
	[1] = { "Newcomer", Color( 255, 255, 255 ) },
	[2] = { "Newbie", Color( 255, 255, 98 ) },
	[3] = { "Learning", Color( 255, 192, 203 ) },
	[4] = { "Advanced", Color( 0, 50, 32 ) },
	[5] = { "Impressive", Color( 255, 128, 0 ) },
	
	[20] = { "Rabbit", Color( 166, 166, 166 ) },
	[21] = { "Sonic", Color( 0, 0, 60 ) },
	[22] = { "Faste", Color( 255, 255, 0 ) },
	
	[40] = { "Slave", Color( 101, 67, 33 ) },
	[41] = { "Admired", Color( 30, 166, 48 ) },
	[42] = { "Zombie", Color( 0, 255, 128 ) },
	
	[80] = { "Lunatic", Color( 139, 0, 0 ) },
	[81] = { "Insane", Color( 0, 255, 0 ) },
	[82] = { "Nightmare", Color( 255, 0, 42 ) },
	
	[100] = { "Genius", Color( 170, 0, 0 ) },
	[101] = { "Beast", Color( 0, 0, 255 ) },
	[102] = { "Demon", Color( 255, 0, 0 ) },
}

TEAM_DEATH = 2
TEAM_RUNNER = 3
TEAM_UNDEAD = 4

util.PrecacheModel( _C.Player.DefaultModel )
include( "core_player.lua" )
include( "core_view.lua" )

local lp, ft, ct, cap = LocalPlayer, FrameTime, CurTime
local mc, mr, bn, ba, bo = math.Clamp, math.Round, bit.bnot, bit.band, bit.bor
local PLAYER = FindMetaTable( "Player" )
PLAYER.BaseAlive = PLAYER.BaseAlive or PLAYER.Alive

function PLAYER:Alive()
	if self:Team() == TEAM_SPECTATOR then
		return false
	end
	
	return self:BaseAlive()
end

function GM:PlayerNoClip( ply )
	return false
end

function GM:PlayerUse( ply )
	if not ply:Alive() then
		return false
	end

	return true
end

function GM:CreateTeams()
	team.SetUp( TEAM_DEATH, "Deaths", Color( 192, 57, 43, 255 ), false )
	team.SetUp( TEAM_RUNNER, "Runners", Color( 41, 128, 185, 255 ), false )
	team.SetUp( TEAM_UNDEAD, "Undead Runners", Color( 230, 126, 34, 255 ), false )
	team.SetUp( TEAM_SPECTATOR, "Spectators", Color( 149, 165, 166, 255 ), true )
	
	team.SetSpawnPoint( TEAM_DEATH, "info_player_terrorist" )
	team.SetSpawnPoint( TEAM_RUNNER, "info_player_counterterrorist" )
	team.SetSpawnPoint( TEAM_UNDEAD, "info_player_counterterrorist" )
end

function GM:Move( ply, data )
	if not IsValid( ply ) then return end
	if lp and ply != lp() then return end
	
	if ply:IsOnGround() or not ply:Alive() then return end
	
	local aim = data:GetMoveAngles()
	local forward, right = aim:Forward(), aim:Right()
	local fmove = data:GetForwardSpeed()
	local smove = data:GetSideSpeed()
	
	if data:KeyDown( IN_MOVERIGHT ) then smove = smove + 500 end
	if data:KeyDown( IN_MOVELEFT ) then smove = smove - 500 end
	
	forward.z, right.z = 0,0
	forward:Normalize()
	right:Normalize()

	local wishvel = forward * fmove + right * smove
	wishvel.z = 0

	local wishspeed = wishvel:Length()
	if wishspeed > data:GetMaxSpeed() then
		wishvel = wishvel * (data:GetMaxSpeed() / wishspeed)
		wishspeed = data:GetMaxSpeed()
	end

	local wishspd = wishspeed
	wishspd = mc( wishspd, 0, 30 )

	local wishdir = wishvel:GetNormal()
	local current = data:GetVelocity():Dot( wishdir )

	local addspeed = wishspd - current
	if addspeed <= 0 then return end

	local accelspeed = 50 * ft() * wishspeed
	if accelspeed > addspeed then
		accelspeed = addspeed
	end
	
	local vel = data:GetVelocity()
	vel = vel + (wishdir * accelspeed)
	
	if ply.SpeedCap and vel:Length2D() > ply.SpeedCap then
		local diff = vel:Length2D() - ply.SpeedCap
		vel:Sub( Vector( vel.x > 0 and diff or -diff, vel.y > 0 and diff or -diff, 0 ) )
	end
	
	data:SetVelocity( vel )
	return false
end

local function AutoHop( ply, data )
	if lp and ply != lp() then return end
	
	local ButtonData = data:GetButtons()
	if ba( ButtonData, IN_JUMP ) > 0 then
		if ply:WaterLevel() < 2 and ply:GetMoveType() != MOVETYPE_LADDER and not ply:IsOnGround() then
			data:SetButtons( ba( ButtonData, bn( IN_JUMP ) ) )
		end
	end
end
hook.Add( "SetupMove", "AutoHop", AutoHop )

-- Core

Core = {}

function Core:Optimize()
	hook.Remove( "PreDrawHalos", "PropertiesHover" )
end


Core.Util = {}

function Core.Util:SetSpeedCap( ply, nSpeed )
	if not IsValid( ply ) then return end
	ply.SpeedCap = nSpeed
end

function Core.Util:StringToTab( szInput )
	local tab = string.Explode( " ", szInput )
	for k,v in pairs( tab ) do
		if tonumber( v ) then
			tab[ k ] = tonumber( v )
		end
	end
	return tab
end

function Core.Util:TabToString( tab )
	for i = 1, #tab do
		if not tab[ i ] then
			tab[ i ] = 0
		end
	end
	return string.Implode( " ", tab )
end

function Core.Util:RandomColor()
	local r = math.random
	return Color( r( 0, 255 ), r( 0, 255 ), r( 0, 255 ) )
end

function Core.Util:VectorToColor( v )
	return Color( v.x, v.y, v.z )
end

function Core.Util:ColorToVector( c )
	return Color( c.r, c.g, c.b )
end

function Core.Util:Count( tab )
	local c = #tab
	if c == 0 then
		for _,v in pairs( tab ) do
			c = c + 1
		end
	end
	
	return c
end

function Core.Util:NoEmpty( tab )
	for k,v in pairs( tab ) do
		if not v or v == "" then
			table.remove( tab, k )
		end
	end
	
	return tab
end

local fl, fo = math.floor, string.format
function Core.Util:Convert( ns )
	return fo( "%.2d:%.2d.%.3d", fl( ns / 60 % 60 ), fl( ns % 60 ), fl( ns * 1000 % 1000 ) )
end