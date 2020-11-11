local origin = Vector(2280, 3776, -7751)
local width = Vector(446, 446, 5)

local EmanOn_ar = {Vector(-4772,-12546,-3265),Vector(-4611,-12392,-3039),Vector(-5309, -11812, -1696)}
local Strafe_ar1 = {Vector(-3700,-5050,382),Vector(-3655,-4968,574), Vector(-4044,-4290,734)}
local Strafe_ar2 = {Vector(-50,-2358,655),Vector(14,-2296,847),Vector(-626,-2393,2014)}
local Strafe_ar3 = {Vector(-1050,3030,4350),Vector(-963,3510,4542),Vector(-209,3259,4446)}
local Greenroom_ar = {Vector(-10790, -4578, -2328),Vector(-10506,-3410,-2000),Vector(3767,-396,-1685)}
local Indiana_ar = {Vector(4288,3370,-3872),Vector(4336,3460,-3680),Vector(4314,3814,-3870)}

local function IsInArea(ent,vec,vec2)
	local vec3 = ent:GetPos()
	if((vec3.x > vec.x && vec3.x < vec2.x) && (vec3.y > vec.y && vec3.y < vec2.y) && (vec3.z > vec.z && vec3.z < vec2.z)) then
		return true
	else
		return false
	end
end

local function TPFix()
	for k,v in pairs(player.GetAll()) do
		if(IsInArea(v,EmanOn_ar[1],EmanOn_ar[2])) then
			v:SetPos(EmanOn_ar[3])
		end
	end
end

local function StrafeFix()
	for k,v in pairs(player.GetAll()) do
		if(IsInArea(v,Strafe_ar1[1],Strafe_ar1[2])) then
			v:SetPos(Strafe_ar1[3])
		end
		if(IsInArea(v,Strafe_ar2[1],Strafe_ar2[2])) then
			v:SetPos(Strafe_ar2[3])
		end
		if(IsInArea(v,Strafe_ar3[1],Strafe_ar3[2])) then
			v:SetPos(Strafe_ar3[3])
		end
	end
end

local function GreenroomFix()
	for k,v in pairs(player.GetAll()) do
		if(IsInArea(v,Greenroom_ar[1],Greenroom_ar[2])) then
			v:SetPos(Greenroom_ar[3])
		end
	end
end

local function IndianaFix()
	for k,v in pairs(player.GetAll()) do
		if(IsInArea(v,Indiana_ar[1],Indiana_ar[2])) then
			v:SetPos(Indiana_ar[3])
		end
	end
end

local function MakeSqeeSpike()
	local p = ents.Create("bhop_spike");
	p:SetPos(origin)
	p.min = Vector(0,0,0)
	p.max = width
	p:Spawn()
end

if(game.GetMap() == "bhop_sqee") then --Sqee
	hook.Add("InitPostEntity","SqeeFix",MakeSqeeSpike)
end

if(game.GetMap() == "bhop_eman_on") then --Eman On
	hook.Add("Think","EmanOnFix",TPFix)
end

if(game.GetMap() == "bhop_strafe_fix") then --Strafe
	hook.Add("Think","StrafeFix",StrafeFix)
end

if(game.GetMap() == "bhop_greenroom_final") then --Greenroom
	hook.Add("Think","GreenroomSurfFix",GreenroomFix)
end

if(game.GetMap() == "kz_bhop_indiana") then --Indiana
	hook.Add("Think","IndianaFix",IndianaFix)
end