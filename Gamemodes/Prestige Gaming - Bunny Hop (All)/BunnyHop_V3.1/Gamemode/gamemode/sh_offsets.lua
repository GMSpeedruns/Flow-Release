local function SetPlayerView(ply)
	local tracedata = {}
	local maxs = ply:Crouching() and VEC_HULLDUCK or VEC_HULLSTAND
	local v = ply:Crouching() and VEC_VIEWDUCK or VEC_VIEWSTAND
	local offset = ply:Crouching() and ply:GetViewOffsetDucked() or ply:GetViewOffset()
	local mins = VEC_HULLMIN
	local s = ply:GetPos()
	s.z = s.z + maxs.z
	tracedata.start = s	
	local e = Vector(s.x,s.y,s.z)
	e.z = e.z + (12 - maxs.z)
	e.z = e.z + v.z
	tracedata.endpos = e
	tracedata.filter = ply
	tracedata.mask = MASK_plyAYERSOLID
	local trace = util.TraceLine(tracedata)
	if (trace.Fraction < 1) then
		local est = s.z + trace.Fraction * (e.z - s.z) - ply:GetPos().z - 12
		if not ply:Crouching() then
			offset.z = est
			ply:SetViewOffset(offset)
		else
			offset.z = math.min(offset.z, est)
			ply:SetViewOffsetDucked(offset)
		end
	else
		ply:SetViewOffset(VEC_VIEWSTAND)
		ply:SetViewOffsetDucked(VEC_VIEWDUCK)
	end
end

hook.Add("Move", "SetPlayerView",function(ply, data)
	SetPlayerView(ply)
end)