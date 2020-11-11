-- Catalyst Hullsize Zones

local mi = Vector( -9968, 5196, -377 )
local ma = Vector( -9789, 5652, -256 )

__HOOK[ "InitPostEntity" ] = function()
	local hullsize = ents.Create( "HullSizeZone" )
	local mid = (mi + ma) / 2
	hullsize:SetPos( mid )
	hullsize.min = mi
	hullsize.max = ma
	hullsize.height = 28
	hullsize:Spawn()
end