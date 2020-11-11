LIST_DOORMAPS = {["bhop_monster_jam"] = true, ["bhop_bkz_goldhop"] = true, ["bhop_aoki_final"] = true}
LIST_BOOSTERS = {["bhop_dan"] = 2.4}

function GroundHook( ply )
	local ent = ply:GetGroundEntity()
	if tonumber(ent:GetNWInt("Platform", 0)) == 0 then return end
	
    if (ent:GetClass() == "func_door" or ent:GetClass() == "func_button") and not LIST_DOORMAPS[game.GetMap()] and ent.BHSp and ent.BHSp > 100 then
		if LIST_BOOSTERS[game.GetMap()] then
			ply:SetVelocity(Vector(0, 0, ent.BHSp * LIST_BOOSTERS[game.GetMap()]))
		else
			ply:SetVelocity(Vector(0, 0, ent.BHSp * 1.9))
		end
	elseif ent:GetClass() == "func_door" || ent:GetClass() == "func_button" then
		timer.Simple(0.04, function()
			ent:SetOwner(ply)
			if CLIENT then
				ent:SetColor(Color(255, 255, 255, 125))
			end
		end)
		timer.Simple(0.7, function() ent:SetOwner(nil) end)
		timer.Simple(0.7, function() if CLIENT then ent:SetColor(Color(255, 255, 255, 255)) end end)
	end
end
hook.Add( "OnPlayerHitGround", "GroundHook", GroundHook )

function KeyValueHook( ent, key, value )
	if ent:GetClass() == "func_door" then
		if LIST_DOORMAPS[game.GetMap()] then
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
		if LIST_DOORMAPS[game.GetMap()] then
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
end
hook.Add( "EntityKeyValue", "KeyValueHook", KeyValueHook )