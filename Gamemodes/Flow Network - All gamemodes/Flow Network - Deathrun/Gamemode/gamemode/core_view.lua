local ut, mm = util.TraceLine, math.min
local HullDuck = _C["Player"].HullDuck
local HullStand = _C["Player"].HullStand
local ViewDuck = _C["Player"].ViewDuck
local ViewStand = _C["Player"].ViewStand

local function InstallView( ply )
	if not IsValid( ply ) then return end
	local maxs = ply:Crouching() and HullDuck or HullStand
	local v = ply:Crouching() and ViewDuck or ViewStand
	local offset = ply:Crouching() and ply:GetViewOffsetDucked() or ply:GetViewOffset()

	local tracedata = {}
	local s = ply:GetPos()
	s.z = s.z + maxs.z
	tracedata.start = s
	
	local e = Vector( s.x, s.y, s.z )
	e.z = e.z + (12 - maxs.z)
	e.z = e.z + v.z
	tracedata.endpos = e
	tracedata.filter = ply
	tracedata.mask = MASK_PLAYERSOLID
	
	local trace = ut( tracedata )
	if trace.Fraction < 1 then
		local est = s.z + trace.Fraction * (e.z - s.z) - ply:GetPos().z - 12
		if not ply:Crouching() then
			offset.z = est
			ply:SetViewOffset( offset )
		else
			offset.z = mm( offset.z, est )
			ply:SetViewOffsetDucked( offset )
		end
	else
		ply:SetViewOffset( ViewStand )
		ply:SetViewOffsetDucked( ViewDuck )
	end
end
hook.Add( "Move", "InstallView", InstallView )