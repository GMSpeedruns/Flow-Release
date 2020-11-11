local function PlayerHullMax(ply)
	if( ply:Crouching() ) then
		return Vector(16, 16, 45)
	else
		return Vector(16, 16, 62)
	end
end

local function PlayerViewOffset(ply)
	if( ply:Crouching() ) then
		return Vector(0, 0, 47)
	else
		return Vector(0, 0, 64)
	end
end

local function PlayerRealViewOffset(ply)
	if( ply:Crouching() ) then
		return ply:GetViewOffsetDucked()
	else
		return ply:GetViewOffset()
	end
end
	
local function FixView(ply)
	local downbelow = 12
	local tracedata = {}
	local maxs = PlayerHullMax(ply)
	local v = PlayerViewOffset(ply)
	local offset = PlayerRealViewOffset(ply)
	local mins = Vector(-16,-16,0) --will always be this
	local s = ply:GetPos()
	s.z = s.z + maxs.z
	tracedata.start = s
	local e = Vector(s.x,s.y,s.z)
	e.z = e.z + (downbelow - maxs.z)
	e.z = e.z + v.z
	tracedata.endpos = e
	tracedata.filter = ply
	tracedata.mask = MASK_PLAYERSOLID
	local trace = util.TraceLine(tracedata)
	if(trace.Fraction < 1) then
		local est = s.z + trace.Fraction * (e.z - s.z) - ply:GetPos().z - downbelow
		if(!ply:Crouching()) then
			offset.z = est
			ply:SetViewOffset(offset)
		else
			offset.z = math.min(offset.z, est)
			ply:SetViewOffsetDucked(offset)
		end
	else
		ply:SetViewOffset(Vector(0, 0, 64))
		ply:SetViewOffsetDucked(Vector(0, 0, 47))
	end
end

hook.Add("Move","FixView",function(ply, data)
	FixView(ply)
end)