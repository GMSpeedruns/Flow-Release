Admin = {}
Admin.Protocol = "Admin"

local AL = 0
local LData = nil


function Admin.Receive()
	local szIdentifier = net.ReadString()
	local bArgs = net.ReadBit() == 1
	local varArgs = bArgs and net.ReadTable() or {}
	
	if not szIdentifier then return end
	Admin:Analyze( szIdentifier, varArgs )
end
net.Receive( Admin.Protocol, Admin.Receive )

function Admin:Analyze( szIdentifier, varArgs )
	if szIdentifier == "Open" then
		if AL < 1 then return end
		LData = varArgs
		
		if LData and #LData > 0 then
			Window.List.Admin.Dim[2] = (#LData + 2) * 20 + 32
			Window:Open( "Admin" )
		end
	elseif szIdentifier == "TimeList" then
		PrintTable( varArgs )
		Message:Print( Config.Prefix.Admin, "Generic", { "A list of data has been printed in your console!" } )
	end
end

function Admin:SetAL( nA )
	AL = nA
end


function Admin:CreateWindow( wnd )
	local ActiveWindow = Window:GetActive()
	if IsValid( ActiveWindow ) then
		for i, data in pairs( LData ) do
			wnd.Labels[ i ] = Window.MakeLabel{ parent = ActiveWindow, x = 15, y = wnd.Offset, font = "HUDLabel", color = GUIColor.White, text = i .. ". " .. data[2] }
			wnd.Offset = wnd.Offset + 20
		end
		
		wnd.Labels[ #LData + 1 ] = Window.MakeLabel{ parent = ActiveWindow, x = 15, y = wnd.Offset, font = "HUDLabel", color = GUIColor.White, text = "0. Exit" }
	end
end

function Admin:WindowProcess( wnd, nKey )
	local Data = LData[ nKey ]
	if Data then
		local nID = Data[3]
		LocalPlayer():ConCommand( "admincmd " .. nID )
	end
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