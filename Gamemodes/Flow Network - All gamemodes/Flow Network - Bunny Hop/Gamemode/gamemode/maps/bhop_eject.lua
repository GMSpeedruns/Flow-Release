-- Eject nosound +left

__HOOK[ "InitPostEntity" ] = function()
	Timer:SetLeftBypass( true )
	
	for _,ent in pairs( ents.FindByClass( "ambient_generic" ) ) do
		ent:Remove()
	end
end