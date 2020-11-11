-- Fixes for doors on Trikz Caverns

__HOOK[ "InitPostEntity" ] = function()
	for k,v in pairs(ents.FindByClass("func_breakable")) do
		v:Remove()
	end
	
	timer.Simple(1,function() --cause other code runs helping us use these variables
		for k,v in pairs(ents.FindByClass("func_door")) do
			if tonumber(v:GetNWInt("Platform", 0)) == 0 then
				v:Fire("Open")
				v:Remove()
			end
			if v.BHSp > 100 then
				v:Fire("Unlock")
				v:SetKeyValue("speed",v.BHSp)
				v:Fire("Open")
				v:Remove() --only condition where we would guess its a booster but in this map its not
			end
			if v:GetPos() == Vector(1567, 4270, 418) then
				v:Fire("Unlock")
				v:SetKeyValue("speed",v.BHSp)
				v:Fire("Open")
				v:Remove()
			end
		end
		for k,v in pairs(ents.FindByClass("func_areaportal")) do
			v:Fire("Open","",0)
		end
	end)
end