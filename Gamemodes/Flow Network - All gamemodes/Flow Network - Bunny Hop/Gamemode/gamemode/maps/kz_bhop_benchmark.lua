-- Highen WJ triggers on Benchmark

__HOOK[ "InitPostEntity" ] = function()
	Zones.StyleForce = _C.Style.Legit
	Zones.StepSize = 16

	for _,ent in pairs( ents.FindByClass("trigger_teleport") ) do
		if ent:GetPos() == Vector(5592, 11296, 7120) or ent:GetPos() == Vector(5536, 11172, 7120) or ent:GetPos() == Vector(-832.02, 1039.94, 3128) then
			ent:SetPos( ent:GetPos() + Vector(0, 0, 8) )
			ent:Spawn()
		end
	end
end