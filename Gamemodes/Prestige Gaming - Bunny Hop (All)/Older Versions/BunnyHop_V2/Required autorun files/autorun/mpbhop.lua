function EKV_BH(ent, key, value)
	if(ent:GetClass() == "func_door") then
		if(string.find(string.lower(key),"movedir")) then
			if(value == "90 0 0") then
				ent.IsP = true
			end
		end
		if(string.find(string.lower(key),"noise1")) then
			ent.BHS = value
		end
		if(string.find(string.lower(key),"speed")) then
			if(tonumber(value) > 100) then
				ent.IsP = true
			end
			ent.BHSp = tonumber(value)
		end
	end
	if(ent:GetClass() == "func_button") then
		if(string.find(string.lower(key),"movedir")) then
			if(value == "90 0 0") then
				ent.IsP = true
			end
		end
		if(key == "spawnflags") then ent.SpawnFlags = value end
		if(string.find(string.lower(key),"sounds")) then
			ent.BHS = value
		end
		if(string.find(string.lower(key),"speed")) then
			if(tonumber(value) > 100) then
				ent.IsP = true
			end
			ent.BHSp = tonumber(value)
		end
	end
end
hook.Add("EntityKeyValue", "EKV_BH", EKV_BH)

function PHG_BH(ply)
	--multiplayer bhops implementation
	local ent = ply:GetGroundEntity()
	if(tonumber(ent:GetNWInt("Platform",0)) == 0) then return end
    if (ent:GetClass() == "func_door" || ent:GetClass() == "func_button") && ent.BHSp && ent.BHSp > 100 then
		ply:SetVelocity( Vector( 0, 0, ent.BHSp*2 ) )
	elseif ent:GetClass() == "func_door" || ent:GetClass() == "func_button" then
		timer.Simple( 0.08, function()
			-- setting owner stops collision between two entities
			ent:SetOwner(ply)
			if(CLIENT)then
				ent:SetColor(Color(255,255,255,125))
			end
		end)
		timer.Simple( 0.7, function()  ent:SetOwner(nil) end)
		timer.Simple( 0.7, function()  if(CLIENT)then ent:SetColor(Color (255,255,255,255)) end end)
	end
end
hook.Add("OnPlayerHitGround", "PHG_BH", PHG_BH)

if !SERVER then return end

function MPBHOP()
	if game.GetMap() == "bhop_fury" then return end
	if game.GetMap() == "bhop_hive" then return end
	if game.GetMap() == "bhop_timbuktu_beta" then return end
	for k,v in pairs(ents.FindByClass("func_door")) do
		if(!v.IsP) then continue end
		local mins = v:OBBMins()
		local maxs = v:OBBMaxs()
		local h = maxs.z - mins.z
		if(h > 80 && (game.GetMap() != "bhop_monster_jam" || game.GetMap() != "bhop_bkz_goldhop" || game.GetMap() != "bhop_aoki_final")) then continue end
		local tab = ents.FindInBox( v:LocalToWorld(mins)-Vector(0,0,10), v:LocalToWorld(maxs)+Vector(0,0,5) )
		if(tab) then
			for _,v2 in pairs(tab) do if(v2 && v2:IsValid() && v2:GetClass() == "trigger_teleport") then tele = v2 end end
			if(tele) then
				v:Fire("Lock")
				v:SetKeyValue("spawnflags","1024")
				v:SetKeyValue("speed","0")
				v:SetRenderMode(RENDERMODE_TRANSALPHA)
				if(v.BHS) then
					v:SetKeyValue("locked_sound",v.BHS)
				else
					v:SetKeyValue("locked_sound","DoorSound.DefaultMove")
				end
				v:SetNWInt("Platform",1)
			end
		end
	end
	
	for k,v in pairs(ents.FindByClass("func_button")) do
		if(!v.IsP) then continue end
		if(v.SpawnFlags == "256") then 
			local mins = v:OBBMins()
			local maxs = v:OBBMaxs()
			local tab = ents.FindInBox( v:LocalToWorld(mins)-Vector(0,0,10), v:LocalToWorld(maxs)+Vector(0,0,5) )
			if(tab) then
				for _,v2 in pairs(tab) do if(v2 && v2:IsValid() && v2:GetClass() == "trigger_teleport") then tele = v2 end end
				if(tele) then
					v:Fire("Lock")
					v:SetKeyValue("spawnflags","257")
					v:SetKeyValue("speed","0")
					v:SetRenderMode(RENDERMODE_TRANSALPHA)
					if(v.BHS) then
						v:SetKeyValue("locked_sound",v.BHS)
					else
						v:SetKeyValue("locked_sound","None (Silent)")
					end
					v:SetNWInt("Platform",1)
				end
			end
		end
	end
end
hook.Add("InitPostEntity","IPE_BH",MPBHOP)