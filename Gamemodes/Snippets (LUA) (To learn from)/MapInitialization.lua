-- This file describes the full call chain starting from GM:PostInitEntity()
-- IMPORTANT: ALL THE WAY AT THE BOTTOM IS CODE THAT GOES IN LUA/AUTORUN AS A SHARED FILE CALLED bhop_ents.lua

local NoTrigger = {
	["bhop_fury"] = true,
	["bhop_hive"] = true
}

local Doors = {
	["bhop_monster_jam"] = true, 
	["bhop_bkz_goldhop"] = true,
	["bhop_aoki_final"] = true
}


function GM:PostInitEntity()
	Setup()
end

function Setup()
	local map = game.GetMap()
	-- Load start / finish zones here
	-- Load custom parameters for map here
	
	CustomFixes( map )
	GlobalFixes()
	
	if NoTrigger[ map ] then return end
	
	for _,ent in pairs( ents.FindByClass("func_door") ) do
		if not ent.IsP then continue end
		local mins = ent:OBBMins()
		local maxs = ent:OBBMaxs()
		local h = maxs.z - mins.z

		if h > 80 and not Doors[ map ] then continue end
		local tab = ents.FindInBox( ent:LocalToWorld( mins ) - Vector( 0, 0, 10 ), ent:LocalToWorld( maxs ) + Vector( 0, 0, 5 ) )
		if tab then
			local teleport = nil
			for _,v2 in pairs( tab ) do
				if v2 and v2:IsValid() and v2:GetClass() == "trigger_teleport" then 
					teleport = v2
				end
			end
			if teleport then
				ent:Fire( "Lock" )
				ent:SetKeyValue( "spawnflags", "1024" )
				ent:SetKeyValue( "speed", "0" )
				ent:SetRenderMode( RENDERMODE_TRANSALPHA )
				if ent.BHS then
					ent:SetKeyValue( "locked_sound", ent.BHS )
				else
					ent:SetKeyValue( "locked_sound", "DoorSound.DefaultMove" )
				end
				ent:SetNWInt( "Platform", 1 )
			end
		end
	end
	
	for _,ent in pairs( ents.FindByClass("func_button") ) do
		if not ent.IsP then continue end
		if ent.SpawnFlags == "256" then
			local mins = ent:OBBMins()
			local maxs = ent:OBBMaxs()
			local tab = ents.FindInBox( ent:LocalToWorld( mins ) - Vector(0, 0, 10), ent:LocalToWorld( maxs ) + Vector(0, 0, 5) )
			if tab then
				local teleport = nil
				for _,v2 in pairs( tab ) do
					if v2 and v2:IsValid() and v2:GetClass() == "trigger_teleport" then
						teleport = v2
					end
				end
				if teleport then
					ent:Fire( "Lock" )
					ent:SetKeyValue( "spawnflags", "257" )
					ent:SetKeyValue( "speed", "0" )
					ent:SetRenderMode( RENDERMODE_TRANSALPHA )
					if ent.BHS then
						ent:SetKeyValue( "locked_sound", ent.BHS )
					else
						ent:SetKeyValue( "locked_sound", "None (Silent)" )
					end
					ent:SetNWInt( "Platform", 1 )
				end
			end
		end
	end
end

function CustomFixes( map )
	if map == "bhop_lost_world" then -- Fix for a low gravity part on Lost World
		local entPush = nil
		for _, ent in pairs( ents.FindByClass("trigger_push") ) do
			if ent:GetPos() == Vector(5864, 4808, -128) then
				entPush = ent
				break
			end
		end
		if not entPush then return end

		entPush:SetKeyValue( "spawnflags", "0" )
		entPush:Spawn()
		
		-- SNIP - I had my own new gravity entity that replaced this one, I assume you don't want this though
	elseif map == "bhop_catalyst" then -- Fix for wrong spawns on catalyst
		local tab = {
			Vector(7156.240234, 704.713989, -7585),
			Vector(7130.129883, 702.512024, -7585),
			Vector(7102.5, 700.283997, -7585),
			Vector(7069.850098, 700.505005, -7585),
			Vector(7036.589844, 700.119019, -7585)
		}
		
		for _,ent in pairs( ents.FindByClass("info_player_terrorist") ) do
			if table.HasValue( tab, ent:GetPos() ) then
				ent:Remove()
			end
		end
	elseif map == "bhop_exquisite" then -- Fix for glitched trigger
		for _,ent in pairs( ents.FindByClass("trigger_multiple") ) do
			if ent:GetPos() == Vector( 3264, -704.02, -974.49 ) then
				ent:Remove()
				break
			end
		end
	elseif map == "bhop_exodus" then -- Fix for glitch part and server crash part
		for _,ent in pairs( ents.FindByClass("trigger_teleport") ) do
			if ent:GetPos() == Vector(6560, 5112, 7412) then
				ent:SetKeyValue( "target", "13" )
			end
		end
		for _,ent in pairs( ents.FindByClass("func_brush") ) do
			if ent:GetName() == "aokilv6" then
				ent:SetName( "disabled" )
			end
		end
	elseif map == "bhop_strafe_fix" then -- Fixes for nojump parts
		for _,ent in pairs(ents.FindByClass("trigger_teleport")) do
			if ent:GetPos() == Vector(-3946.5, -4732.5, 459) or ent:GetPos() == Vector(-624.5, 3270, 4428) or ent:GetPos() == Vector(681.5, 3138, 3941.5) then
				ent:Remove()
			end
		end
	elseif map == "bhop_eman_on" then -- Optimization for Garry's Mod crouch fuckiness (started messing up with higher jump height, this works)
		for _,ent in pairs( ents.FindByClass("trigger_teleport") ) do
			local vPos = ent:GetPos()
			if vPos.x == -1316 and (pos.y > -10975 and pos.y < -10841) then
				ent:SetPos( vPos + Vector( 0, 0, 14.5 ) )
				local Min, Max = ent:GetCollisionBounds()
				Min.y, Max.y = Min.y + 64, Max.y - 64
				ent:SetCollisionBounds( ent:GetPos(), Min, Max )
				ent:Spawn()
			end
		end
	elseif map == "bhop_inmomentum_gfl_final" then -- Fix for rendering mode
		-- Rendering mode moved to global map scale (Not only applies to inmomentum)
	elseif map == "bhop_impulse" then -- 2-way portal removal (speedrun)
		local tab = {
			Vector( 10368, -532, -192 ),
			Vector( 10368, -556, -192 )
		}
		
		for _,ent in pairs( ents.FindByClass("trigger_teleport") ) do
			if table.HasValue( tab, ent:GetPos() ) then
				ent:Remove()
			end
		end
		
		for _,ent in pairs( ents.FindByClass("func_wall_toggle") ) do
			ent:Remove()
		end
	elseif map == "bhop_stronghold" then -- WJ / Crouch part fix
		for _,ent in pairs( ents.FindByClass("trigger_teleport") ) do
			if ent:GetPos() == Vector(-912, -2880, 4510) then
				ent:Remove()
			end
		end
	elseif map == "bhop_voyage" then -- Airport level fix
		for _,ent in pairs( ents.FindByClass("trigger_teleport") ) do
			if ent:GetPos() == Vector(0, -404.5, -136) then
				ent:Remove()
			end
		end
	elseif map == "bhop_badges2" then -- Crouch parts fixes
		for _,ent in pairs( ents.FindByClass("trigger_multiple") ) do
			if ent:GetPos() == Vector(-12543.9, -8448, 4319.96) then
				ent:Remove()
			end
		end
		
		for _,ent in pairs( ents.FindByClass("trigger_teleport") ) do
			if ent:GetPos() == Vector(-3840, -4832, -468) or ent:GetPos() == Vector(-9216, -2168, -1732) then
				ent:Remove()
			end
		end
	elseif map == "kz_bhop_benchmark" then -- WJ / SWJ fixes
		for _,ent in pairs( ents.FindByClass("trigger_teleport") ) do
			if ent:GetPos() == Vector(5592, 11296, 7120) or ent:GetPos() == Vector(5536, 11172, 7120) or ent:GetPos() == Vector(-832.02, 1039.94, 3128) then
				ent:SetPos( ent:GetPos() + Vector(0, 0, 8) )
				ent:Spawn()
			end
		end
	elseif map == "kz_bhop_lucid" then -- Crouch part fixes
		for _,ent in pairs( ents.FindByClass("trigger_teleport") ) do
			if ent:GetPos() == Vector(880, 2432, 100) or ent:GetPos() == Vector(-1248, 1384.01, 268) then
				ent:Remove()
			end
		end
	elseif map == "bhop_harmony" then -- Lag fixes
		for _,v in pairs(ents.FindByClass("logic_*")) do
			v:Remove()
		end
		for _,v in pairs(ents.FindByClass("func_wall_toggle")) do
			v:Remove()
		end
		for _,v in pairs(ents.FindByClass("func_illusionary")) do
			v:Remove()
		end
		for _,v in pairs(ents.FindByClass("point_clientcommand")) do
			v:Remove()
		end
		for _,v in pairs(ents.FindByClass("shadow_control")) do
			v:Remove()
		end
		for _,v in pairs(ents.FindByClass("func_brush")) do
			v:Remove()
		end
		for _,v in pairs(ents.FindByClass("env_smokestack")) do
			v:Remove()
		end
	end
end

function GlobalFixes()
	for _,ent in pairs( ents.FindByClass("func_lod") ) do
		ent:SetRenderMode( RENDERMODE_TRANSALPHA )
	end
		
	for _,ent in pairs( ents.GetAll() ) do
		if ent:GetRenderFX() != 0 and ent:GetRenderMode() == 0 then
			ent:SetRenderMode( RENDERMODE_TRANSALPHA )
		end
	end
end


----
-- AUTORUN FILE STARTS HERE
----

local Doors = {
	["bhop_monster_jam"] = true,
	["bhop_bkz_goldhop"] = true,
	["bhop_aoki_final"] = true
}

local Boosters = {
	["bhop_dan"] = 2.4 -- Because they're weak as fuck (Default is 1.9 - Add map if required / you feel boosters are too weak)
}

function GroundHook( ply )
	local ent = ply:GetGroundEntity()
	if tonumber( ent:GetNWInt("Platform", 0) ) == 0 then return end
	
    if (ent:GetClass() == "func_door" or ent:GetClass() == "func_button") and not Doors[ game.GetMap() ] and ent.BHSp and ent.BHSp > 100 then
		-- Make sure those boosters work like they fucking should (This causes some ping-related issues sometimes, but they're no fix for that really)
		ply:SetVelocity( Vector( 0, 0, ent.BHSp * (Boosters[ game.GetMap() ] or 1.9) ) )
	elseif ent:GetClass() == "func_door" or ent:GetClass() == "func_button" then
		-- This is for CS:S like platform fading
		timer.Simple( 0.04, function()
			ent:SetOwner( ply )
			if CLIENT then
				ent:SetColor(Color(255, 255, 255, 125))
			end
		end )
		timer.Simple( 0.7, function() ent:SetOwner( nil ) end )
		timer.Simple( 0.7, function() if CLIENT then ent:SetColor( Color( 255, 255, 255, 255 ) ) end end )
	end
end
hook.Add( "OnPlayerHitGround", "GroundHook", GroundHook )

function KeyValueHook( ent, key, value )
	if ent:GetClass() == "func_door" then
		if Doors[ game.GetMap() ] then
			ent.IsP = true
		end
		if string.find( string.lower( key ), "movedir" ) then
			if value == "90 0 0" then
				ent.IsP = true
			end
		end
		if string.find( string.lower( key ), "noise1" ) then
			ent.BHS = value
		end
		if string.find( string.lower( key ), "speed" ) then
			if tonumber( value ) > 100 then
				ent.IsP = true
			end
			ent.BHSp = tonumber( value )
		end
	end
	
	if ent:GetClass() == "func_button" then
		if Doors[ game.GetMap() ] then
			ent.IsP = true
		end
		if string.find( string.lower( key ), "movedir" ) then
			if value == "90 0 0" then
				ent.IsP = true
			end
		end
		if key == "spawnflags" then ent.SpawnFlags = value end
		if string.find( string.lower( key ), "sounds" ) then
			ent.BHS = value
		end
		if string.find( string.lower( key ), "speed" ) then
			if tonumber( value ) > 100 then
				ent.IsP = true
			end
			ent.BHSp = tonumber( value )
		end
	end
end
hook.Add( "EntityKeyValue", "KeyValueHook", KeyValueHook )