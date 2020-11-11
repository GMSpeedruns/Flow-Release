hook.Add("Initialize","InfogHook",function()
	if(game.GetMap() == "bhop_infog") then
		hook.Add( "RenderScreenspaceEffects", "BHNBPG0123", function()
			cam.Start3D( EyePos(), EyeAngles() )
				render.SetMaterial(Material("RYAN_DEV/DEV_BLACK"))
				render.DrawQuad(Vector(2751,-3081,-757),Vector(2751,-2843,-757),Vector(2825,-2843,-757),Vector(2825,-3081,-757))
			cam.End3D()
		end)
	end
end)