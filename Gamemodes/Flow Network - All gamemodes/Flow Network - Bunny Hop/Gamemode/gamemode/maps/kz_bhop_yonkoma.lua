-- Set WJ and legit force

__HOOK[ "InitPostEntity" ] = function()
	Zones.StyleForce = _C.Style.Legit
	Zones.StepSize = 16
end