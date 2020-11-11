-- Shared file containing all essential information

-- Please don't change any of this except for GM.DisplayName and GM.Website, thank you.
GM.Name = "Skill Surf"
GM.DisplayName = "Skill Surf"
GM.Author = "Gravious"
GM.Email = ""
GM.Website = ""
GM.TeamBased = true

DeriveGamemode( "base" )
DEFINE_BASECLASS( "gamemode_base" )

_C = _C or {}
_C["Version"] = 7.26
_C["PageSize" ] = 7
_C["GameType"] = "surf"
_C["ServerName"] = "My Skill Surf"
_C["Identifier"] = "yourservername-" .. _C.GameType -- If you want clientside caching to work (lower player join usage), set this
_C["SteamGroup"] = "" -- Set this to your group URL if you want people to see a pop-up when joining for the first time (cl_init.lua at the bottom)
_C["MaterialID"] = "flow" -- Change this to the name of the folder in content/materials/

_C["Team"] = { Players = 1, Spectator = TEAM_SPECTATOR }
_C["Style"] = { Normal = 1, SW = 2, HSW = 3, Bonus = 4, Practice = 5 }

_C["Player"] = {
	DefaultModel = "models/player/group01/male_01.mdl",
	DefaultWeapon = "weapon_glock",
	JumpPower = math.sqrt( 2 * 800 * 57.0 ),
	HullMin = Vector( -16, -16, 0 ),
	HullDuck = Vector( 16, 16, 45 ),
	HullStand = Vector( 16, 16, 62 ),
	ViewDuck = Vector( 0, 0, 47 ),
	ViewStand = Vector( 0, 0, 64 )
}

_C["Prefixes"] = {
	["Surf Timer"] = Color( 52, 73, 94 ),
	["General"] = Color( 52, 152, 219 ),
	["Admin"] = Color( 76, 60, 231 ),
	["Notification"] = Color( 231, 76, 60 ),
	[_C["ServerName"]] = Color( 46, 204, 113 ),
	["Radio"] = Color( 230, 126, 34 ),
	["VIP"] = Color( 174, 0, 255 )
}

_C["Ranks"] = {
	{ "Starter", Color( 255, 255, 255 ) },
	{ "Slave", Color( 166, 166, 166 ) },
	{ "Grunt", Color( 255, 255, 98 ) },
	{ "Squire", Color( 101, 67, 33 ) },
	{ "Snail", Color( 250, 218, 221 ) },
	{ "Freshman", Color( 80, 80, 80 ) },
	{ "Amateur", Color( 0, 8, 8 ) },
	{ "Crawler", Color( 96, 16, 176 ) },
	{ "Private", Color( 206, 255, 157 ) },
	{ "Peasant", Color( 128, 128, 128 ) },
	{ "Learning", Color( 255, 192, 203 ) },
	{ "Advanced", Color( 0, 50, 32 ) },
	{ "Experienced", Color( 0, 0, 60 ) },
	{ "Mortal", Color( 196, 255, 196 ) },
	{ "Impressive", Color( 255, 128, 0 ) },
	{ "Professional", Color( 0, 0, 139 ) },
	{ "Centurion", Color( 196, 255, 196 ) },
	{ "Admired", Color( 30, 166, 48 ) },
	{ "Executioner", Color( 98, 0, 0 ) },
	{ "Elite", Color( 255, 255, 0 ) },
	{ "Legendary", Color( 128, 0, 128 ) },
	{ "Famous", Color( 0, 168, 255 ) },
	{ "Champion", Color( 255, 101, 0 ) },
	{ "Zombie", Color( 0, 255, 128 ) },
	{ "Genius", Color( 170, 0, 0 ) },
	{ "Brawler", Color( 0, 255, 191 ) },
	{ "Lunatic", Color( 139, 0, 0 ) },
	{ "Bishop", Color( 190, 255, 0 ) },
	{ "Psycho", Color( 255, 0, 255 ) },
	{ "Demon", Color( 255, 0, 0 ) },
	{ "Pharaoh", Color( 92, 196, 207 ) },
	{ "Immortal", Color( 255, 235, 0 ) },
	{ "Insane", Color( 0, 255, 0 ) },
	{ "Beast", Color( 0, 0, 255 ) },
	{ "Colossus", Color( 0, 255, 255 ) },
	{ "Nightmare", Color( 255, 0, 42 ) },
	
	[-1] = { "Retrieving...", Color( 255, 255, 255 ) },
	[-2] = { "Record Bot", Color( 255, 0, 0 ) }
}

_C["MapTypes"] = {
	[ 0 ] = "Linear",
	[ 1 ] = "Staged"
}

util.PrecacheModel( _C.Player.DefaultModel )

include( "core_player.lua" )
include( "core_view.lua" )


local mc, mp = math.Clamp, math.pow
local bn, ba, bo = bit.bnot, bit.band, bit.bor
local sl, ls = string.lower, {}
local lp, ft, ct, gf = LocalPlayer, FrameTime, CurTime, {}

function GM:PlayerNoClip( ply )
	local nStyle = SERVER and ply.Style or Timer.Style
	return nStyle == _C.Style.Practice
end

function GM:PlayerUse( ply )
	if not ply:Alive() then return false end
	if ply:Team() == TEAM_SPECTATOR then return false end
	if ply:GetMoveType() != MOVETYPE_WALK then return false end
	
	return true
end

function GM:CreateTeams()
	team.SetUp( _C.Team.Players, "Players", Color( 255, 50, 50, 255 ), false )
	team.SetUp( _C.Team.Spectator, "Spectators", Color( 50, 255, 50, 255 ), true )
	team.SetSpawnPoint( _C.Team.Players, { "info_player_terrorist", "info_player_counterterrorist" } )
end

function GM:Move( ply, data )
	if not IsValid( ply ) then return end
	if lp and ply != lp() then return end
	if ply:IsOnGround() or not ply:Alive() then return end
	
	local aim = data:GetMoveAngles()
	local forward, right = aim:Forward(), aim:Right()
	local fmove = data:GetForwardSpeed()
	local smove = data:GetSideSpeed()
	
	local st = ply.Style
	if st == 1 then
		if data:KeyDown( IN_MOVERIGHT ) then smove = smove + 500 end
		if data:KeyDown( IN_MOVELEFT ) then smove = smove - 500 end
	elseif st == 2 then
		if data:KeyDown( IN_FORWARD ) then fmove = fmove + 500 end
		if data:KeyDown( IN_BACK ) then fmove = fmove - 500 end
	end
	
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
	wishspd = mc( wishspd, 0, 32.8 )

	local wishdir = wishvel:GetNormal()
	local current = data:GetVelocity():Dot( wishdir )

	local addspeed = wishspd - current
	if addspeed <= 0 then return end
	
	local accelspeed = 120 * ft() * wishspeed
	if accelspeed > addspeed then
		accelspeed = addspeed
	end
	
	local vel = data:GetVelocity()
	vel = vel + (wishdir * accelspeed)
	
	data:SetVelocity( vel )
	return false
end

local function AutoHop( ply, data )
	if lp and ply != lp() then return end
	
	local ButtonData = data:GetButtons()
	if ba( ButtonData, IN_JUMP ) > 0 then
		if ply:WaterLevel() < 2 and not ply:IsOnGround() then
			data:SetButtons( ba( ButtonData, bn( IN_JUMP ) ) )
		end
	end
end
hook.Add( "SetupMove", "AutoHop", AutoHop )

local function StripMovements( ply, data )
	if lp and ply != lp() then return end
	
	local st = ply.Style
	if st and st > 1 and st < 4 and ply:GetMoveType() != MOVETYPE_NOCLIP then
		if ply:OnGround() then return end
		
		if st == 2 then
			data:SetSideSpeed( 0 )
		elseif st == 3 and (data:GetForwardSpeed() == 0 or data:GetSideSpeed() == 0) then
			data:SetForwardSpeed( 0 )
			data:SetSideSpeed( 0 )
		end
	end
end
hook.Add( "SetupMove", "StripIllegal", StripMovements )

-- Core

Core = {}

local StyleNames = {}
for name,id in pairs( _C.Style ) do
	StyleNames[ id ] = name
end

function Core:StyleName( nID )
	return StyleNames[ nID ] or "Unknown"
end

function Core:IsValidStyle( nStyle )
	return not not StyleNames[ nStyle ]
end

function Core:GetStyleID( szStyle )
	for s,id in pairs( _C.Style ) do
		if sl( s ) == sl( szStyle ) then
			return id
		end
	end
	
	return 0
end

function Core:Exp( c, n )
	return c * mp( n, 2.9 )
end

function Core:Optimize()
	hook.Remove( "PlayerTick", "TickWidgets" )
	hook.Remove( "PreDrawHalos", "PropertiesHover" )
end


Core.Util = {}
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

function Core.Util:NoEmpty( tab )
	for k,v in pairs( tab ) do
		if not v or v == "" then
			table.remove( tab, k )
		end
	end
	
	return tab
end