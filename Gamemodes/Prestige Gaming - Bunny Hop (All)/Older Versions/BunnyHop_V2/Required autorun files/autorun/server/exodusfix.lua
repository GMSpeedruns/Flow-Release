local tv = {Vector(2416,8553,5701), Vector(2969,9120,5819)}
local st = {Vector(872,157,-295), Vector(1373,670,116)}
local cb = {Vector(-8944,-1731,-7964), Vector(-8770,-1617,-7798)}
local an = {Vector(5948,-3972,576), Vector(6098,-3900,787)}
local jar = {Vector(15175,6853,640),Vector(15311,7023,725)}
local wj = {Vector(-40,549,-2763),Vector(222,1154,-2364)}
local miniwj = {Vector(4132,4037,-4300),Vector(4492,4221,-4060)}
local guly = {Vector(2144.5, -1012, -84),"level8"}
local guly2 = {Vector(-2541,-792,-157),Vector(-2001,-329,179)}

local tp = {Vector(1995,8145,5031),Vector(3251,9390,5346),Vector(3207,8061,5072)}

local blox = {
	["bhop_cartoons"] = {{Vector(2947,12856,167),Vector(3032,13862,297)},{Vector(7315, 4713, -2545),Vector(7375, 5116, -2439)},{Vector(6666, 4705, -2552),Vector(6730, 5179, -2452)}},
	["bhop_badges_ausbhop"] = {{Vector(8000,-171,152),Vector(8314,492,214)},{Vector(1958,-3649,152),Vector(2514,-2004,252)},{Vector(-4794,-6579,152),Vector(-4151,-5531,267)}},
	["bhop_miku_v2"] = {{Vector(-2900,874,-444),Vector(-2791,1006,-109)},{Vector(-2895,28,-444),Vector(-2799,123,-116)}},
	["bhop_choice"] = {{Vector(11,-840,128), Vector(471,-685,668)}},
}

local catafix = {
	Vector(7156.240234, 704.713989, -7585),
	Vector(7130.129883, 702.512024, -7585),
	Vector(7102.5, 700.283997, -7585),
	Vector(7069.850098, 700.505005, -7585),
	Vector(7036.589844, 700.119019, -7585),
}

local function IsInArea(ent,vec,vec2)
	local vec3 = ent:GetPos()
	if((vec3.x > vec.x && vec3.x < vec2.x) && (vec3.y > vec.y && vec3.y < vec2.y) && (vec3.z > vec.z && vec3.z < vec2.z)) then
		return true
	else
		return false
	end
end

local function JourneyFix()
	for k,v in pairs(player.GetAll()) do
		if(IsInArea(v,jar[1],jar[2])) then
			v:SetPos(Vector(12924, 3997, 624))
		end
	end
end

local function Indianaaa()
	for k,v in pairs(player.GetAll()) do
		if(IsInArea(v,wj[1],wj[2])) then
			v:SetStepSize(16)
		elseif(IsInArea(v,miniwj[1],miniwj[2])) then
			v:SetStepSize(1)
		else
			v:SetStepSize(18)
		end
	end
end

local function GollyGuly()
	for k,v in pairs(ents.FindByClass("trigger_teleport")) do
		if(v:GetPos() == guly[1]) then
			v:SetKeyValue("target",guly[2])
		end
	end
end

local function GollyFink()
	for k,v in pairs(player.GetAll()) do
		if(IsInArea(v,guly2[1],guly2[2])) then
			if(v.Started) then
				v.HasFinished = true
				v.Started = false
				v:SendLua("StopTime("..CurTime()-v.StartTime..")")
			end
		end
	end
end

local function EditTeles()
	for k,v in pairs(ents.FindByClass("trigger_teleport")) do
		if(v:GetPos() == Vector(-1032, -2696.5, -455)) then
			v:SetKeyValue("target","level_redcorridor7")
		elseif(v:GetPos() == Vector(-6947, -3655.5, -455)) then
			v:SetKeyValue("target","level_greencorridor3")
		end
	end
end

local function ExquisiteFix()
	for k,v in pairs(ents.FindByClass("trigger_multiple")) do
		if(v:GetPos() == Vector(3264, -704.02, -974.49)) then
			v:Remove()
		end
	end
end

local function MakeBlox()
	if blox[game.GetMap()] then
		for k,v in pairs(blox[game.GetMap()]) do
			local x = (v[1].x+v[2].x)/2
			local y = (v[1].y+v[2].y)/2
			local z = (v[1].z+v[2].z)/2
			local midpoint = Vector(x,y,z)
			x = v[2].x-x
			y = v[2].y-y
			z = v[2].z-z
			
			local p = ents.Create("bhop_spike")
			p:SetPos(midpoint)
			p.max = Vector(x,y,z)
			p.min = Vector(x*-1,y*-1,z*-1)
			p:Spawn()
		end
	end
end

local tmax = nil
local tmin = nil
local function GetPush()
	local push = nil
	for k,v in pairs(ents.FindByClass("trigger_push")) do if(v:GetPos() == Vector(5864, 4808, -128)) then push = v end end
	push:SetKeyValue("spawnflags","0")
	push:Spawn()
	tmax = push:LocalToWorld(push:OBBMaxs())
	tmin = push:LocalToWorld(push:OBBMins())
end

local function PushThink()
	if !tmin then return end
	for k,v in pairs(player.GetAll()) do
		if(IsInArea(v,tmin,tmax)) then
			v:SetVelocity(Vector(0,0,60))
		end
	end
end

local function AnTeles()
	for k,v in pairs(player.GetAll()) do
		if(IsInArea(v,an[1],an[2])) then
			v:SetPos(Vector(8429, -5231, 1179))
		end
	end
end

local sa = {Vector(-1004,-965,14400),Vector(-716, 920, 14725)}
local function ArcaneStop()
	for k,v in pairs(player.GetAll()) do
		if(IsInArea(v,sa[1],sa[2])) then
			if(v.Started) then
				v.HasFinished = true
				v.Started = false
				v:SendLua("StopTime("..CurTime()-v.StartTime..")")
			end
		end
	end
end

local function ExodusFix()
	for k,v in pairs(player.GetAll()) do
		if(IsInArea(v,tv[1],tv[2])) then
			v:SetPos(Vector(-11027, 6770, 2496))
		end
		if(IsInArea(v,tp[1],tp[2])) then
			v:SetPos(tp[3])
		end
		if(IsInArea(v,st[1],st[2])) then
			v.HasFinished = true
			v:SendLua("StopTime("..CurTime()-v.StartTime..")")
		end
		if(!v.HasCBar && IsInArea(v,cb[1],cb[2])) then
			v.HasCBar = true
			v:Give("weapon_crowbar")
		end
		if(v:GetPos() == Vector(-6368, -4992, 4048)) then
			v:SetPos(Vector(-6368, -4992, 4040.23))
		end
	end
end

hook.Add("Initialize","ExodusHook",function()
	if(blox[game.GetMap()]) then
		hook.Add("InitPostEntity","Bloxxxx",MakeBlox)
	end
	if(game.GetMap() == "bhop_catalyst") then
		hook.Add("PlayerSpawn","CatFix",function(ply) timer.Simple(0, function() ply:SetPos(Vector(-8438, -58, 5353.03125)) end) end)
		hook.Add("InitPostEntity","RemoveBadSpawns",function()
			timer.Simple(0.5, function()
			for k,v in pairs(ents.FindByClass("info_player_terrorist")) do
				if(table.HasValue(catafix,v:GetPos())) then
					v:Remove()
				end
			end
			end)
		end)
	end
	if(game.GetMap() == "bhop_areaportal_v1") then
		hook.Add("InitPostEntity","EditTeles",EditTeles)
	end
	if(game.GetMap() == "bhop_exquisite") then
		hook.Add("InitPostEntity","ExquisiteFix",ExquisiteFix)
	end
	if(game.GetMap() == "bhop_arcane_v1") then
		hook.Add("Think","StopArcane",ArcaneStop)
	end
	if(game.GetMap() == "bhop_lost_world") then
		hook.Add("InitPostEntity","EditPush",GetPush)
		hook.Add("Think","PushThink",PushThink)
	end
	if(game.GetMap() == "bhop_ananas") then
		hook.Add("Think","AnTeles",AnTeles)
	end
	if(game.GetMap() == "bhop_infog") then
		hook.Add("InitPostEntity","BoxClimb",function()
			local p = ents.Create("bhop_spike")
			p:SetPos(Vector(-2127.5,5608.5,39.5))
			p.min = Vector(-25.5,-6.5,-16.5)
			p.max = Vector(25.5,6.5,16.5)
			p:Spawn()

			p = ents.Create("bhop_spike")
			p:SetPos(Vector(2788,-2926,-757.5))
			p.min = Vector(-37,-119,-0.5)
			p.max = Vector(37,119,0.5)
			p:Spawn()
		end)
	end
	if(game.GetMap() == "bhop_cw_journey") then
		hook.Add("Think","JourneyFix",JourneyFix)
	end
	if(game.GetMap() == "kz_bhop_indiana") then
		hook.Add("Think","Indianaaa",Indianaaa)
	end
	if(game.GetMap() == "bhop_guly") then
		hook.Add("InitPostEntity","Golly1",GollyGully)
		hook.Add("Think","Golly2",GollyFink)
	end
	if(game.GetMap() == "bhop_exodus") then
		hook.Add("Think","ExodusFix",ExodusFix)
		hook.Add("PlayerSpawn","HasCBar",function(ply) timer.Simple(0, function() ply.HasCBar = false end) end)
		hook.Add("InitPostEntity","ExodusSpikes",function()
			local p = ents.Create("bhop_spike");
			p:SetPos(Vector(-328, 11992, 4703))
			p.min = Vector(-2,-2,-1.5)
			p.max = Vector(2,2,1)
			p:Spawn()
			
			p = ents.Create("bhop_spike");
			p:SetPos(Vector(-296, 12095, 4703))
			p.min = Vector(-2,-2,-1.5)
			p.max = Vector(2,2,1)
			p:Spawn()
			
			p = ents.Create("bhop_spike");
			p:SetPos(Vector(-655, 12151, 4703))
			p.min = Vector(-2,-2,-1.5)
			p.max = Vector(2,2,1)
			p:Spawn()
			
			p = ents.Create("bhop_spike");
			p:SetPos(Vector(-815, 11920, 4703))
			p.min = Vector(-2,-2,-1.5)
			p.max = Vector(2,2,1)
			p:Spawn()
			
			p = ents.Create("bhop_spike");
			p:SetPos(Vector(-815, 11808, 4703))
			p.min = Vector(-2,-2,-1.5)
			p.max = Vector(2,2,1)
			p:Spawn()
			
			p = ents.Create("bhop_spike");
			p:SetPos(Vector(-911, 11840, 4703))
			p.min = Vector(-2,-2,-1.5)
			p.max = Vector(2,2,1)
			p:Spawn()
			
			p = ents.Create("bhop_spike");
			p:SetPos(Vector(-1071, 11840, 4703))
			p.min = Vector(-2,-2,-1.5)
			p.max = Vector(2,2,1)
			p:Spawn()
		end)
	end
end)