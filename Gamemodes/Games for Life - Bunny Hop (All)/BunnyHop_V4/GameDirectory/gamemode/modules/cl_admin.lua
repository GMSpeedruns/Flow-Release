Admin = {}
Admin.Protocol = "Admin"

Admin.Access = 0


function Admin:Init()
	if not Admin.Opened then
		return RunConsoleCommand("adminopen")
	end
	
	
end

function Admin.Receive()
	local szIdentifier = net.ReadString()
	local bArgs = net.ReadBit() == 1
	local varArgs = bArgs and net.ReadTable() or {}
	
	if not szIdentifier then return end
	Admin:Analyze( szIdentifier, varArgs )
end
net.Receive( Admin.Protocol, Admin.Receive )

function Admin:Analyze( szIdentifier, varArgs )
	--print( "Admin Captured " .. szIdentifier )
end


function Admin:AreaEdit( nID, vecStart )
	Admin.AreaEditor = {}
	Admin.AreaEditor.Start = vecStart
	Admin.AreaEditor.Type = nID
	Admin.AreaEditor.Opened = true
end

function Admin:AreaStop()
	Admin.AreaEditor = {}
end


local DrawLaser = Material( "bhop/timer.png" )
local DrawColor = Color( 50, 0, 255, 255 )

function Admin.DrawAreaEditor()
	if Admin.AreaEditor and Admin.AreaEditor.Opened then
		local Width = 5
		local Start = Admin.AreaEditor.Start
		local End = LocalPlayer():GetPos()
		local Min = Vector(math.min(Start.x, End.x), math.min(Start.y, End.y), math.min(Start.z, End.z))
		local Max = Vector(math.max(Start.x, End.x), math.max(Start.y, End.y), math.max(Start.z + 128, End.z + 128))
		local B1, B2, B3, B4 = Vector(Min.x, Min.y, Min.z), Vector(Min.x, Max.y, Min.z), Vector(Max.x, Max.y, Min.z), Vector(Max.x, Min.y, Min.z)
		local T1, T2, T3, T4 = Vector(Min.x, Min.y, Max.z), Vector(Min.x, Max.y, Max.z), Vector(Max.x, Max.y, Max.z), Vector(Max.x, Min.y, Max.z)
	
		render.SetMaterial( DrawLaser )
		render.DrawBeam( B1, B2, Width, 0, 1, DrawColor )
		render.DrawBeam( B2, B3, Width, 0, 1, DrawColor )
		render.DrawBeam( B3, B4, Width, 0, 1, DrawColor )
		render.DrawBeam( B4, B1, Width, 0, 1, DrawColor )
			
		render.DrawBeam( T1, T2, Width, 0, 1, DrawColor )
		render.DrawBeam( T2, T3, Width, 0, 1, DrawColor )
		render.DrawBeam( T3, T4, Width, 0, 1, DrawColor )
		render.DrawBeam( T4, T1, Width, 0, 1, DrawColor )
		
		render.DrawBeam( B1, T1, Width, 0, 1, DrawColor )
		render.DrawBeam( B2, T2, Width, 0, 1, DrawColor )
		render.DrawBeam( B3, T3, Width, 0, 1, DrawColor )
		render.DrawBeam( B4, T4, Width, 0, 1, DrawColor )
	end
end
hook.Add( "PostDrawOpaqueRenderables", "PreviewAreas", Admin.DrawAreaEditor )