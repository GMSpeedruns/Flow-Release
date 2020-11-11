
local hud_deathnotice_time = CreateConVar( "hud_deathnotice_time", "6", FCVAR_REPLICATED, "Amount of time to show death notice" )

-- These are our kill icons
local Color_Icon = Color( 255, 80, 0, 255 )
local NPC_Color = Color( 250, 50, 50, 255 )

killicon.AddFont( "prop_physics",		"HL2MPTypeDeath",	"9",	Color_Icon )
killicon.AddFont( "weapon_smg1",		"HL2MPTypeDeath",	"/",	Color_Icon )
killicon.AddFont( "weapon_357",			"HL2MPTypeDeath",	".",	Color_Icon )
killicon.AddFont( "weapon_ar2",			"HL2MPTypeDeath",	"2",	Color_Icon )
killicon.AddFont( "crossbow_bolt",		"HL2MPTypeDeath",	"1",	Color_Icon )
killicon.AddFont( "weapon_shotgun",		"HL2MPTypeDeath",	"0",	Color_Icon )
killicon.AddFont( "rpg_missile",		"HL2MPTypeDeath",	"3",	Color_Icon )
killicon.AddFont( "npc_grenade_frag",	"HL2MPTypeDeath",	"4",	Color_Icon )
killicon.AddFont( "weapon_pistol",		"HL2MPTypeDeath",	"-",	Color_Icon )
killicon.AddFont( "prop_combine_ball",	"HL2MPTypeDeath",	"8",	Color_Icon )
killicon.AddFont( "grenade_ar2",		"HL2MPTypeDeath",	"7",	Color_Icon )
killicon.AddFont( "weapon_stunstick",	"HL2MPTypeDeath",	"!",	Color_Icon )
killicon.AddFont( "npc_satchel",		"HL2MPTypeDeath",	"*",	Color_Icon )
killicon.AddFont( "npc_tripmine",		"HL2MPTypeDeath",	"*",	Color_Icon )
killicon.AddFont( "weapon_crowbar",		"HL2MPTypeDeath",	"6",	Color_Icon )
killicon.AddFont( "weapon_physcannon",	"HL2MPTypeDeath",	",",	Color_Icon )

local Deaths = {}

local function PlayerIDOrNameToString( var )

	if ( type( var ) == "string" ) then
		if ( var == "" ) then return "" end
		return "#" .. var
	end
	
	local ply = Entity( var )
	
	if ( !IsValid( ply ) ) then return "NULL!" end
	
	return ply:Name()

end


local function RecvPlayerKilledByPlayer()

	local victim	= net.ReadEntity()
	local inflictor	= net.ReadString()
	local attacker	= net.ReadEntity()

	if ( !IsValid( attacker ) ) then return end
	if ( !IsValid( victim ) ) then return end
	
	GAMEMODE:AddDeathNotice( attacker:Name(), attacker:Team(), inflictor, victim:Name(), victim:Team() )

end
net.Receive( "PlayerKilledByPlayer", RecvPlayerKilledByPlayer )

local function RecvPlayerKilledSelf()

	local victim = net.ReadEntity()
	if ( !IsValid( victim ) ) then return end
	GAMEMODE:AddDeathNotice( nil, 0, "suicide", victim:Name(), victim:Team() )

end
net.Receive( "PlayerKilledSelf", RecvPlayerKilledSelf )

local function RecvPlayerKilled()

	local victim	= net.ReadEntity()
	if ( !IsValid( victim ) ) then return end
	local inflictor	= net.ReadString()
	local attacker	= "#" .. net.ReadString()
	
	GAMEMODE:AddDeathNotice( attacker, -1, inflictor, victim:Name(), victim:Team() )

end
net.Receive( "PlayerKilled", RecvPlayerKilled )

local function RecvPlayerKilledNPC()

	local victimtype = net.ReadString()
	local victim	= "#" .. victimtype
	local inflictor	= net.ReadString()
	local attacker	= net.ReadEntity()

	--
	-- For some reason the killer isn't known to us, so don't proceed.
	--
	if ( !IsValid( attacker ) ) then return end
	
	GAMEMODE:AddDeathNotice( attacker:Name(), attacker:Team(), inflictor, victim, -1 )
	
	local bIsLocalPlayer = ( IsValid(attacker) && attacker == LocalPlayer() )
	
	local bIsEnemy = IsEnemyEntityName( victimtype )
	local bIsFriend = IsFriendEntityName( victimtype )
	
	if ( bIsLocalPlayer && bIsEnemy ) then
		achievements.IncBaddies()
	end
	
	if ( bIsLocalPlayer && bIsFriend ) then
		achievements.IncGoodies()
	end
	
	if ( bIsLocalPlayer && ( !bIsFriend && !bIsEnemy ) ) then
		achievements.IncBystander()
	end

end
net.Receive( "PlayerKilledNPC", RecvPlayerKilledNPC )

local function RecvNPCKilledNPC()

	local victim	= "#" .. net.ReadString()
	local inflictor	= net.ReadString()
	local attacker	= "#" .. net.ReadString()

	GAMEMODE:AddDeathNotice( attacker, -1, inflictor, victim, -1 )

end
net.Receive( "NPCKilledNPC", RecvNPCKilledNPC )

local TriggerList = { "trigger_hurt", "env_explosion", "env_beam", "env_fire", "env_physexplosion", "worldspawn", "func_movelinear", "func_physbox", "func_rotating", "func_door", "entityflame", "prop_physics", "suicide" }
local KillerList = { "was struck by karma", "was banished by Obama", "was stabbed by a serial killer", "was eaten alive by a zombie", "was impaled by spikes", "was taken by Grim Reaper", "slipped on a banana", "wasn't fireproof", "has an explosive personality", "forgot about gravity", "bit the dust", "was a brave lad", "... will be back", "let his body hit the floor", "didn't care at all", "should have had a parachute", "forgot to crouch", "pressed the wrong button", "fell for the cake's lies", "had nothing to lose", "says he lagged out", "forgot to jump", "wasn't paying attention", "doesn't bounce", "was just waiting for a mate", "found the source of the ticking", "'s mom is going to be mad", "went full retard", ", never go full retard", "sees dead people", "couldn't handle the truth" }
local MessageList = table.Copy( KillerList )

--[[---------------------------------------------------------
   Name: gamemode:AddDeathNotice( Victim, Attacker, Weapon )
   Desc: Adds an death notice entry
-----------------------------------------------------------]]
function GM:AddDeathNotice( Victim, team1, Inflictor, Attacker, team2 )
	
	local Death = {}
	Death.victim	= Victim
	Death.attacker	= Attacker
	Death.time		= CurTime()

	Death.left		= Victim
	Death.right		= Attacker
	Death.icon		= Inflictor
	
	if table.HasValue( TriggerList, Inflictor ) then
		if #MessageList == 0 then
			MessageList = table.Copy( KillerList )
		end
	
		local msg = table.Random( MessageList )
		table.RemoveByValue( MessageList, msg )
		
		if not msg[ 1 ]:match("%W") then
			msg = " " .. msg
		end
		
		Death.right = Death.right .. msg
		Death.message = Death.right .. " (" .. (Death.left and string.sub( Death.left, 2 ) or "unknown") .. ")\n"
		Death.left = nil
		team1 = -1
		
		if Inflictor != "suicide" then
			team2 = -1
		end
		
		MsgC( Color( 255, 255, 255 ), "[Player death] ", Death.message )
	end

	if ( team1 == -1 ) then Death.color1 = table.Copy( NPC_Color )
	else Death.color1 = table.Copy( team.GetColor( team1 ) ) end
	
	if ( team2 == -1 ) then Death.color2 = table.Copy( NPC_Color )
	else Death.color2 = table.Copy( team.GetColor( team2 ) ) end
	
	if (Death.left == Death.right) then
		Death.left = nil
		Death.icon = "suicide"
	end
	
	table.insert( Deaths, Death )

end

local function DrawDeath( x, y, death, hud_deathnotice_time )

	local w, h = killicon.GetSize( death.icon )
	if ( !w || !h ) then return end
	
	local fadeout = ( death.time + hud_deathnotice_time ) - CurTime()
	
	local alpha = math.Clamp( fadeout * 255, 0, 255 )
	death.color1.a = alpha
	death.color2.a = alpha
	
	-- Draw Icon
	killicon.Draw( x, y, death.icon, alpha )
	
	-- Draw KILLER
	if ( death.left ) then
		draw.SimpleText( death.left,	"ChatFont", x - ( w / 2 ) - 16, y, death.color1, TEXT_ALIGN_RIGHT )
	end
	
	-- Draw VICTIM
	draw.SimpleText( death.right,		"ChatFont", x + ( w / 2 ) + 16, y, death.color2, TEXT_ALIGN_LEFT )
	
	return ( y + h * 0.70 )

end

local drawingAt
function GM:DrawDeathNotice( x, y )

	if ( GetConVarNumber( "cl_drawhud" ) == 0 ) then return end

	local hud_deathnotice_time = hud_deathnotice_time:GetFloat()

	x = x * ScrW()
	y = y * ScrH()
	
	-- Draw
	for k, Death in pairs( Deaths ) do

		if ( Death.time + hud_deathnotice_time > CurTime() ) then
	
			if ( Death.lerp ) then
				x = x * 0.3 + Death.lerp.x * 0.7
				y = y * 0.3 + Death.lerp.y * 0.7
			end
			
			Death.lerp = Death.lerp or {}
			Death.lerp.x = x
			Death.lerp.y = y
			
			if ( !Death.left && Death.right ) then
				local l = string.len( Death.right )
				if l > 28 then x = x - 60
				elseif l > 25 then x = x - 54
				elseif l > 20 then x = x - 40
				elseif l > 18 then x = x - 24 end
			end
			
			if not drawingAt or x < drawingAt then
				drawingAt = x
			end
			
			y = DrawDeath( drawingAt, y, Death, hud_deathnotice_time )
		
		end
		
	end
	
	-- We want to maintain the order of the table so instead of removing
	-- expired entries one by one we will just clear the entire table
	-- once everything is expired.
	for k, Death in pairs( Deaths ) do
		if ( Death.time + hud_deathnotice_time > CurTime() ) then
			return
		end
	end
	
	drawingAt = nil
	Deaths = {}

end
