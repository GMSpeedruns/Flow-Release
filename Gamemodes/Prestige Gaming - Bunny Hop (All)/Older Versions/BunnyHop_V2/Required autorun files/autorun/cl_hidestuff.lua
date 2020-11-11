if SERVER then
	util.AddNetworkString("TrailBlock")
	
	hook.Add("OnEntityCreated","TrailBlock",function(ent)
		if(ent:GetClass() == "env_spritetrail") then
			if(ent:GetParent() && ent:GetParent():IsValid() && ent:GetParent():IsPlayer()) then
				net.Start("TrailBlock")
				net.WriteEntity(ent)
				net.Broadcast()
			end
		end
	end)
	return
end
local st = CreateClientConVar("cl_showothers", "1", true, true)

local function stCallback(CVar, PreviousValue, NewValue)
	if(tonumber(NewValue) == 1) then
		for k,v in pairs(ents.FindByClass("env_spritetrail")) do
			if(v:IsValid()) then
				if(v:GetParent() && v:GetParent():IsValid() && v:GetParent():IsPlayer()) then
					v:SetColor(v.mColor)
				end
			end
		end
	else
		for k,v in pairs(ents.FindByClass("env_spritetrail")) do
			if(v:IsValid()) then
				if(v:GetParent() && v:GetParent():IsValid() && v:GetParent():IsPlayer()) then
					v.mColor = v:GetColor()
					v:SetColor(Color(255,255,255,0))
				end
			end
		end
	end
end
cvars.AddChangeCallback("cl_showothers", stCallback)

net.Receive("TrailBlock",function(len)
	local ent = net.ReadEntity()
	if(!st:GetBool()) then
		timer.Simple(1, function()
			if(ent:IsValid()) then
				ent.mColor = ent:GetColor()
				ent:SetColor(Color(255,255,255,0))
			end
		end)
	end
end)

hook.Add("PrePlayerDraw", "BlockPlayerPre", function(ply)
	if(!st:GetBool()) then
		return true
	end
end)

hook.Add("PostPlayerDraw", "BlockPlayerPost", function(ply)
	if(!st:GetBool()) then
		return true
	end
end)