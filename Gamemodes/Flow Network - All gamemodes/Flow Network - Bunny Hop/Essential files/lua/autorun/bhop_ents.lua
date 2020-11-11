local Doors = {
	["bhop_monster_jam"] = true,
	["bhop_bkz_goldbhop"] = true,
	["bhop_aoki_final"] = true,
	["bhop_areaportal_v1"] = true,
	["bhop_ytt_space"] = true
}

local NoDoors = {
	["bhop_hive"] = true,
	["bhop_fury"] = true,
	["bhop_mcginis_fix"] = true
}

local Specials = {
	["bhop_lost_world"] = true,
	["bhop_lego2"] = true
}

local Boosters = {
	["bhop_challenge2"] = 1,
	["bhop_ytt_space"] = 1.1,
	["bhop_dan"] = 1.5
}

local function GroundHook( ply )
	local ent = ply:GetGroundEntity()
	if tonumber( ent:GetNWInt("Platform", 0) ) != 0 then
		if (ent:GetClass() == "func_door" or ent:GetClass() == "func_button") and ent.BHSp and ent.BHSp > 100 then
			timer.Simple( 0.02, function() ply:SetVelocity( Vector( 0, 0, ent.BHSp * (Boosters[ game.GetMap() ] or 1.3) ) ) end )
		elseif ent:GetClass() == "func_door" or ent:GetClass() == "func_button" then
			if CLIENT then
				timer.Simple( 0.04, function()
					ent:SetOwner( ply )
					ent:SetColor( Color( 255, 255, 255, 125 ) )
				end )
				timer.Simple( 0.9, function()
					ent:SetOwner( nil )
					ent:SetColor( Color( 255, 255, 255, 255 ) )
				end )
			else
				timer.Simple( 0.04, function() ent:SetOwner( ply ) end )
				timer.Simple( 0.9, function() ent:SetOwner( nil ) end )
			end
		end
	end
end
hook.Add( "OnPlayerHitGround", "GroundHook", GroundHook )

local function KeyValueHook( ent, key, value )
	local map = game.GetMap()
	if NoDoors[ map ] then return end
	if string.find( value,"modelindex" ) and string.find( value,"AddOutput" ) then return "" end
	
	if ent:GetClass() == "func_door" then
		if Doors[ map ] then
			ent.IsP = true
		end
		if string.find(string.lower(key), "movedir") then
			if value == "90 0 0" then
				ent.IsP = true
			end
		end
		if string.find(string.lower(key), "noise1") then
			ent.BHS = value
		end
		if string.find(string.lower(key), "speed") then
			if tonumber(value) > 100 then
				ent.IsP = true
			end
			ent.BHSp = tonumber(value)
		end
	end
	
	if ent:GetClass() == "func_button" then
		if Doors[ map ] then
			ent.IsP = true
		end
		if string.find(string.lower(key), "movedir") then
			if value == "90 0 0" then
				ent.IsP = true
			end
		end
		if key == "spawnflags" then ent.SpawnFlags = value end
		if string.find(string.lower(key), "sounds") then
			ent.BHS = value
		end
		if string.find(string.lower(key), "speed") then
			if tonumber(value) > 100 then
				ent.IsP = true
			end
			ent.BHSp = tonumber(value)
		end
	end
	
	if not Specials[ map ] then return end
	if map == "bhop_lost_world" then
		if ent:GetClass() == "trigger_push" then
			if string.find(string.lower(key), "speed") then
				if tonumber(value) == 1200 then
					return "1500"
				end
			end
		end
	elseif map == "bhop_lego2" then
		if ent:GetClass() == "trigger_push" then
			if string.find(string.lower(key), "speed") then
				return tostring( tonumber( value ) + 80 )
			end
		end
	end
end
hook.Add( "EntityKeyValue", "KeyValueHook", KeyValueHook )