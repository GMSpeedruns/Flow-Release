local function SetPlayerView( ply )
	local tracedata = {}
	local maxs = ply:Crouching() and Config.Player.HullDuck or Config.Player.HullStand
	local v = ply:Crouching() and Config.Player.ViewDuck or Config.Player.ViewStand
	local offset = ply:Crouching() and ply:GetViewOffsetDucked() or ply:GetViewOffset()
	local mins = Config.Player.HullMin
	local s = ply:GetPos()
	s.z = s.z + maxs.z
	tracedata.start = s
	local e = Vector(s.x,s.y,s.z)
	e.z = e.z + (12 - maxs.z)
	e.z = e.z + v.z
	tracedata.endpos = e
	tracedata.filter = ply
	tracedata.mask = MASK_PLAYERSOLID
	local trace = util.TraceLine(tracedata)
	if trace.Fraction < 1 then
		local est = s.z + trace.Fraction * (e.z - s.z) - ply:GetPos().z - 12
		if not ply:Crouching() then
			offset.z = est
			ply:SetViewOffset(offset)
		else
			offset.z = math.min(offset.z, est)
			ply:SetViewOffsetDucked(offset)
		end
	else
		ply:SetViewOffset( Config.Player.ViewStand )
		ply:SetViewOffsetDucked( Config.Player.ViewDuck )
	end
end
hook.Add( "Move", "SetPlayerView", SetPlayerView )