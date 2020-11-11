-----------
-- ADMIN --
-----------
-- Beware, this was not made by a flat-out retard and you won't be able to find a way to exploit access.
-- Congratulations, you have come here, but much further this will not take you. It's a really boring Derma admin panel, very functional though.
-----------

Admin = {}
Admin.SelfAccess = 0
Admin.Functions = {
	{3, "Maximum Access", 500},
	{2, "[Map] Reload", 101},
	{2, "[Map] Area Editor", 102},
	{2, "[Map] Times", 103},
	{2, "[Map] Change", 104},
	{2, "[Map] Specials", 105},
	{2, "[Players] Times", 201},
	{2, "[Players] Teleport", 202},
	{1, "[Players] Manage", 203},
	{1, "[Players] Scripting", 204},
	{1, "[Bot] Manage", 301}
}
Admin.Items = {}
Admin.ItemsInit = false
Admin.ItemInsert = -1

Admin.Strings = {
	["Specials"] = {
		[1] = {"AREA_BLOCK", "Start;End"},
		[2] = {"AREA_TELEPORT", "Start;End;Target Position"},
		[3] = {"TPTRIGGER", "Trigger Position;Target Trigger Name"},
		[4] = {"ENTSPIKE", "Position;Min;Max"},
		[5] = {"ENT_BLOCK", "Class Name"},
		[6] = {"NOBOT", "Unknown"},
		[7] = {"STEPSIZE", "Number Value"},
		[8] = {"AREA_STEPSIZE", "Start;End;Number Value"},
		[9] = {"SPAWN", "Position"},
		[10] = {"AREA_BONUS1", "Start;End"},
		[11] = {"AREA_BONUS2", "Start;End"},
		[100] = {"CUSTOM_LOSTWORLD", "custom"},
		[101] = {"CUSTOM_EXQUISITE", "custom"},
		[102] = {"CUSTOM_STRAFE", "custom"}
	}
}

Admin.SelectedData = nil

function AdminLoad(window, identifier)
	local list = vgui.Create("DListView", window)
	list:SetPos(5, 5)
	list:SetSize(195, 340)
	list:SetMultiSelect(false)
	list:SetHeaderHeight(20)
	
	list:AddColumn("Select Function")
	for k,v in pairs(Admin.Functions) do
		if Admin.SelfAccess >= v[1] then
			list:AddLine(v[2])
		end
	end
	
	Admin.ItemsInit = true

	list.OnRowSelected = function(parent, line)
		local line = list:GetLine(line)
		for k,v in pairs(Admin.Functions) do
			if v[2] == line:GetValue(1) then
				AdminDisplay(v[3], window)
				break
			end
		end
	end
	
	StoreWindow(window, identifier)
end

function AdminDisplay(id, window)
	if Admin.ItemsInit then
		Admin.Items = {}
		Admin.ItemsInit = false
	end
	
	for k,v in pairs(Admin.Items) do
		if v then v:SetVisible(false) end
	end
	Admin.Items = {}

	if window:GetWide() != wnd["Visible"]["Dimension"][1] or window:GetTall() != wnd["Visible"]["Dimension"][2] then
		window:SetSize(wnd["Visible"]["Dimension"][1], wnd["Visible"]["Dimension"][2])
		window:Center()
	end
	
	local sx,sy = 200, 25
	if id == 101 then
		table.insert(Admin.Items, wnd.MakeButton{ parent = window, w = 130, h = 30, x = sx + 10, y = sy + 10, text = "Reload Areas", id = 1010, onclick = AdminExecute })
		table.insert(Admin.Items, wnd.MakeButton{ parent = window, w = 130, h = 30, x = sx + 15 + 130, y = sy + 10, text = "Reload Data (WRs)", id = 1011, onclick = AdminExecute })
		table.insert(Admin.Items, wnd.MakeButton{ parent = window, w = 130, h = 30, x = sx + 10, y = sy + 45, text = "Recache Maps", id = 1012, onclick = AdminExecute })
	elseif id == 102 then
		table.insert(Admin.Items, wnd.MakeLabel{ parent = window, x = sx + 10, y = sy + 10, font = "HUDLabel", color = HUD_DGRAY, text = "Start Area" })
		table.insert(Admin.Items, wnd.MakeLabel{ parent = window, x = sx + 210, y = sy + 10, font = "HUDLabel", color = HUD_DGRAY, text = "End Area" })
		
		table.insert(Admin.Items, wnd.MakeButton{ parent = window, w = 80, h = 30, x = sx + 10, y = sy + 35, text = "Remove", id = 1021, onclick = AdminExecute })
		table.insert(Admin.Items, wnd.MakeButton{ parent = window, w = 80, h = 30, x = sx + 10, y = sy + 70, text = "Add", id = 1020, onclick = AdminExecute })
		if Admin.AreaEditor and Admin.AreaEditor.Opened and Admin.AreaEditor.Type == AREA_START then
			table.insert(Admin.Items, wnd.MakeButton{ parent = window, w = 80, h = 30, x = sx + 10, y = sy + 105, text = "Add Stop", id = 1024, onclick = AdminExecute })
			table.insert(Admin.Items, wnd.MakeButton{ parent = window, w = 80, h = 30, x = sx + 10, y = sy + 140, text = "Add Cancel", id = 1026, onclick = AdminExecute })
		end
		table.insert(Admin.Items, wnd.MakeButton{ parent = window, w = 80, h = 30, x = sx + 210, y = sy + 35, text = "Remove", id = 1023, onclick = AdminExecute })
		table.insert(Admin.Items, wnd.MakeButton{ parent = window, w = 80, h = 30, x = sx + 210, y = sy + 70, text = "Add", id = 1022, onclick = AdminExecute })
		if Admin.AreaEditor and Admin.AreaEditor.Opened and Admin.AreaEditor.Type == AREA_FINISH then
			table.insert(Admin.Items, wnd.MakeButton{ parent = window, w = 80, h = 30, x = sx + 210, y = sy + 105, text = "Add Stop", id = 1025, onclick = AdminExecute })
			table.insert(Admin.Items, wnd.MakeButton{ parent = window, w = 80, h = 30, x = sx + 210, y = sy + 140, text = "Add Cancel", id = 1027, onclick = AdminExecute })
		end
	elseif id == 103 then
		window:SetSize(wnd["Visible"]["Dimension"][1] + 150, wnd["Visible"]["Dimension"][2])
		window:Center()
	
		map = wnd.MakeTextBox{ parent = window, w = 120, h = 22, x = sx + 10, y = sy + 170, text = game.GetMap() or "" }
		table.insert(Admin.Items, map)
		
		local count = wnd.MakeTextBox{ parent = window, w = 35, h = 22, x = sx + 10, y = sy + 200, text = "25" }
		table.insert(Admin.Items, count)
		
		local list = vgui.Create("DListView", window)
		list:SetPos(sx + 10, sy + 10)
		list:SetSize(120, 150)
		list:SetMultiSelect(false)
		list:SetHeaderHeight(20)
		list:AddColumn("ID"):SetFixedWidth(30)
		list:AddColumn("Name"):SetFixedWidth(90)
		for k,v in pairs(MODE_NAME) do
			if k == MODE_PRACTICE then continue end
			list:AddLine(k, v)
		end

		list.OnRowSelected = function(parent, line)
			local line = list:GetLine(line)
			Admin.SelectedData = line:GetValue(1)
			AdminCommand(1030, {map:GetValue(), tonumber(Admin.SelectedData), count:GetValue() and (tonumber(count:GetValue()) or 25) or 25})
		end
		table.insert(Admin.Items, list)
		
		local data = vgui.Create("DListView", window)
		data:SetPos(sx + 140, sy + 10)
		data:SetSize(350, 310)
		data:SetMultiSelect(false)
		data:SetHeaderHeight(20)

		data.OnRowSelected = function(parent, line)
			local line = data:GetLine(line)
			if Admin.SelectedData and type(Admin.SelectedData) == "number" then
				Admin.SelectedData = {Admin.SelectedData, line:GetValue(2)}
			elseif Admin.SelectedData and type(Admin.SelectedData) == "table" then
				Admin.SelectedData = {Admin.SelectedData[1], line:GetValue(2)}
			else
				AddText(TEXT_ADMIN, "Please select a mode first!")
			end
		end
		
		Admin.ItemInsert = table.insert(Admin.Items, data)
		table.insert(Admin.Items, wnd.MakeButton{ parent = window, w = 80, h = 30, x = sx + 10, y = sy + 230, text = "Remove", id = 1031, onclick = AdminExecute })
	elseif id == 104 then
		map = wnd.MakeTextBox{ parent = window, w = 120, h = 22, x = sx + 100, y = sy + 14, text = game.GetMap() or "" }
		table.insert(Admin.Items, map)
		table.insert(Admin.Items, wnd.MakeButton{ parent = window, w = 80, h = 30, x = sx + 10, y = sy + 10, text = "Change Map", id = 1040, onclick = AdminExecute })
		extend = wnd.MakeTextBox{ parent = window, w = 120, h = 22, x = sx + 100, y = sy + 49, text = "Time (In Mins)" }
		table.insert(Admin.Items, extend)
		table.insert(Admin.Items, wnd.MakeButton{ parent = window, w = 80, h = 30, x = sx + 10, y = sy + 45, text = "Force Extend", id = 1041, onclick = AdminExecute })
		points = wnd.MakeTextBox{ parent = window, w = 120, h = 22, x = sx + 100, y = sy + 84, text = MapPointList[game.GetMap()] or "Points" }
		table.insert(Admin.Items, points)
		table.insert(Admin.Items, wnd.MakeButton{ parent = window, w = 80, h = 30, x = sx + 10, y = sy + 80, text = "Set Points", id = 1042, onclick = AdminExecute })
		boxstart = wnd.MakeTextBox{ parent = window, w = 55, h = 22, x = sx + 100, y = sy + 119, text = "128" }
		boxend = wnd.MakeTextBox{ parent = window, w = 55, h = 22, x = sx + 165, y = sy + 119, text = "128" }
		table.insert(Admin.Items, boxstart)
		table.insert(Admin.Items, boxend)
		table.insert(Admin.Items, wnd.MakeButton{ parent = window, w = 80, h = 30, x = sx + 10, y = sy + 115, text = "Set Height", id = 1043, onclick = AdminExecute })
	elseif id == 105 then
		window:SetSize(wnd["Visible"]["Dimension"][1] + 150, wnd["Visible"]["Dimension"][2])
		window:Center()
	
		local list = vgui.Create("DListView", window)
		list:SetPos(sx + 10, sy + 10)
		list:SetSize(400, 310)
		list:SetMultiSelect(false)
		list:SetHeaderHeight(20)

		list.OnRowSelected = function(parent, line)
			local line = list:GetLine(line)
			Admin.SelectedData = {line:GetValue(1), line:GetValue(3)}
		end
		
		Admin.ItemInsert = table.insert(Admin.Items, list)
		
		table.insert(Admin.Items, wnd.MakeButton{ parent = window, w = 80, h = 30, x = sx + 400 + 15, y = sy + 10, text = "Load", id = 1050, onclick = AdminExecute })
		table.insert(Admin.Items, wnd.MakeButton{ parent = window, w = 80, h = 30, x = sx + 400 + 15, y = sy + 45, text = "Add", id = 1051, onclick = AdminExecute })
		table.insert(Admin.Items, wnd.MakeButton{ parent = window, w = 80, h = 30, x = sx + 400 + 15, y = sy + 80, text = "Edit", id = 1052, onclick = AdminExecute })
		table.insert(Admin.Items, wnd.MakeButton{ parent = window, w = 80, h = 30, x = sx + 400 + 15, y = sy + 115, text = "Remove", id = 1053, onclick = AdminExecute })
	elseif id == 201 then
		window:SetSize(wnd["Visible"]["Dimension"][1] + 150 + 120, wnd["Visible"]["Dimension"][2])
		window:Center()
	
		txtplayer = wnd.MakeTextBox{ parent = window, w = 120, h = 22, x = sx + 10, y = sy + 170, text = LocalPlayer():Name() or "Player" }
		table.insert(Admin.Items, txtplayer)
		local map = wnd.MakeTextBox{ parent = window, w = 120, h = 22, x = sx + 10, y = sy + 200, text = game.GetMap() or "Map" }
		table.insert(Admin.Items, map)
		local count = wnd.MakeTextBox{ parent = window, w = 35, h = 22, x = sx + 10, y = sy + 230, text = "25" }
		table.insert(Admin.Items, count)
		
		local list = vgui.Create("DListView", window)
		list:SetPos(sx + 10, sy + 10)
		list:SetSize(120, 150)
		list:SetMultiSelect(false)
		list:SetHeaderHeight(20)
		list:AddColumn("ID"):SetFixedWidth(30)
		list:AddColumn("Name"):SetFixedWidth(90)
		for k,v in pairs(MODE_NAME) do
			if k == MODE_PRACTICE then continue end
			list:AddLine(k, v)
		end

		list.OnRowSelected = function(parent, line)
			local line = list:GetLine(line)
			Admin.SelectedData = line:GetValue(1)
			AdminCommand(2010, {txtplayer:GetValue(), map:GetValue(), tonumber(Admin.SelectedData), count:GetValue() and (tonumber(count:GetValue()) or 25) or 25})
		end
		table.insert(Admin.Items, list)
		
		local data = vgui.Create("DListView", window)
		data:SetPos(sx + 140, sy + 10)
		data:SetSize(350 + 120, 310)
		data:SetMultiSelect(false)
		data:SetHeaderHeight(20)

		data.OnRowSelected = function(parent, line)
			local line = data:GetLine(line)
			if Admin.SelectedData and type(Admin.SelectedData) == "number" then
				Admin.SelectedData = {line:GetValue(4), Admin.SelectedData, line:GetValue(2)}
			elseif Admin.SelectedData and type(Admin.SelectedData) == "table" then
				Admin.SelectedData = {line:GetValue(4), Admin.SelectedData[2], line:GetValue(2)}
			else
				AddText(TEXT_ADMIN, "Please select a mode first!")
			end
		end
		
		Admin.ItemInsert = table.insert(Admin.Items, data)
		
		table.insert(Admin.Items, wnd.MakeButton{ parent = window, w = 80, h = 30, x = sx + 10, y = sy + 260, text = "Remove", id = 2011, onclick = AdminExecute })
	elseif id == 202 then
		from = wnd.MakeTextBox{ parent = window, w = 120, h = 22, x = sx + 10, y = sy + 10, text = "From - " .. LocalPlayer():Name() }
		table.insert(Admin.Items, from)
		to = wnd.MakeTextBox{ parent = window, w = 120, h = 22, x = sx + 140, y = sy + 10, text = "To - " .. LocalPlayer():Name() }
		table.insert(Admin.Items, to)
		topos = wnd.MakeTextBox{ parent = window, w = 120, h = 22, x = sx + 140, y = sy + 45, text = "Pos - " .. GetVectorString(LocalPlayer():GetPos(), true) }
		table.insert(Admin.Items, topos)
		table.insert(Admin.Items, wnd.MakeButton{ parent = window, w = 80, h = 30, x = sx + 10, y = sy + 45, text = "Teleport", id = 2020, onclick = AdminExecute })
		if LocalPlayer() and LocalPlayer():Team() == TEAM_SPECTATOR and PlayerMode == MODE_PRACTICE then
			table.insert(Admin.Items, wnd.MakeButton{ parent = window, w = 80, h = 30, x = sx + 10, y = sy + 80, text = "Spawn Self", id = 2021, onclick = AdminExecute })
		end
	elseif id == 203 then
		txtplayer = wnd.MakeTextBox{ parent = window, w = 120, h = 22, x = sx + 10, y = sy + 10, text = LocalPlayer():Name() }
		table.insert(Admin.Items, txtplayer)
		power = wnd.MakeTextBox{ parent = window, w = 100, h = 22, x = sx + 140, y = sy + 10, text = "10000" }
		table.insert(Admin.Items, power)
		table.insert(Admin.Items, wnd.MakeButton{ parent = window, w = 100, h = 30, x = sx + 10, y = sy + 45, text = "Simple Slap", id = 2030, onclick = AdminExecute })
		table.insert(Admin.Items, wnd.MakeButton{ parent = window, w = 100, h = 30, x = sx + 10, y = sy + 80, text = "Secret Spectate", id = 2031, onclick = AdminExecute })
		table.insert(Admin.Items, wnd.MakeButton{ parent = window, w = 100, h = 30, x = sx + 10, y = sy + 125, text = "Strip weapons", id = 2032, onclick = AdminExecute })
		table.insert(Admin.Items, wnd.MakeButton{ parent = window, w = 100, h = 30, x = sx + 120, y = sy + 125, text = "Permanent strip", id = 2035, onclick = AdminExecute })
		if Admin.SelfAccess < 3 then return end
		table.insert(Admin.Items, wnd.MakeButton{ parent = window, w = 100, h = 30, x = sx + 120, y = sy + 80, text = "Set Time", id = 2037, onclick = AdminExecute })
		table.insert(Admin.Items, wnd.MakeButton{ parent = window, w = 100, h = 30, x = sx + 10, y = sy + 160, text = "Save positions", id = 2033, onclick = AdminExecute })
		table.insert(Admin.Items, wnd.MakeButton{ parent = window, w = 100, h = 30, x = sx + 120, y = sy + 160, text = "Load positions", id = 2034, onclick = AdminExecute })
		table.insert(Admin.Items, wnd.MakeButton{ parent = window, w = 100, h = 30, x = sx + 120, y = sy + 45, text = "Massive Slap", id = 2036, onclick = AdminExecute })
	elseif id == 204 then
		txtplayer = wnd.MakeTextBox{ parent = window, w = 120, h = 22, x = sx + 100, y = sy + 14, text = "Enter Player" }
		table.insert(Admin.Items, txtplayer)
		table.insert(Admin.Items, wnd.MakeButton{ parent = window, w = 80, h = 30, x = sx + 10, y = sy + 10, text = "Lock-out player", id = 2040, onclick = AdminExecute })

		if Admin.SelfAccess < 3 then return end
		window:SetSize(wnd["Visible"]["Dimension"][1] + 240, wnd["Visible"]["Dimension"][2])
		window:Center()
	
		local list = vgui.Create("DListView", window)
		list:SetPos(sx + 10, sy + 45)
		list:SetSize(565, 268)
		list:SetMultiSelect(false)
		list:SetHeaderHeight(20)

		list.OnRowSelected = function(parent, line)
			local line = list:GetLine(line)
			txtplayer:SetValue(line:GetValue(2))
		end

		Admin.ItemInsert = table.insert(Admin.Items, list)
		table.insert(Admin.Items, wnd.MakeButton{ parent = window, w = 80, h = 30, x = sx + 225, y = sy + 10, text = "Load Data", id = 2041, onclick = AdminExecute })
		table.insert(Admin.Items, wnd.MakeButton{ parent = window, w = 80, h = 30, x = sx + 310, y = sy + 10, text = "Erase by UID", id = 2042, onclick = AdminExecute })
		table.insert(Admin.Items, wnd.MakeButton{ parent = window, w = 80, h = 30, x = sx + 395, y = sy + 10, text = "Lift by UID", id = 2043, onclick = AdminExecute })
	elseif id == 301 then
		txtplayer = wnd.MakeTextBox{ parent = window, w = 120, h = 22, x = sx + 10, y = sy + 45, text = LocalPlayer():Name() }
		table.insert(Admin.Items, txtplayer)
		table.insert(Admin.Items, wnd.MakeButton{ parent = window, w = 80, h = 30, x = sx + 10, y = sy + 10, text = "Enable Bot", id = 3010, onclick = AdminExecute })
		table.insert(Admin.Items, wnd.MakeButton{ parent = window, w = 80, h = 30, x = sx + 100, y = sy + 10, text = "Disable Bot", id = 3011, onclick = AdminExecute })
		table.insert(Admin.Items, wnd.MakeButton{ parent = window, w = 80, h = 30, x = sx + 10, y = sy + 80, text = "Start Record", id = 3012, onclick = AdminExecute })
		table.insert(Admin.Items, wnd.MakeButton{ parent = window, w = 80, h = 30, x = sx + 100, y = sy + 80, text = "Stop Record", id = 3013, onclick = AdminExecute })
		if Admin.SelfAccess < 3 then return end
		table.insert(Admin.Items, wnd.MakeButton{ parent = window, w = 80, h = 30, x = sx + 10, y = sy + 115, text = "Force Save", id = 3014, onclick = AdminExecute })
		table.insert(Admin.Items, wnd.MakeButton{ parent = window, w = 80, h = 30, x = sx + 100, y = sy + 115, text = "Delete Run", id = 3015, onclick = AdminExecute })
		table.insert(Admin.Items, wnd.MakeButton{ parent = window, w = 80, h = 30, x = sx + 190, y = sy + 115, text = "Garbage Collect", id = 3016, onclick = AdminExecute })
	end
end

function AdminExecute(parent)
	local data = nil
	local id = parent.SetID
	local proc = false

	if id == 1020 then -- Start Add
		Admin.AreaEditor = {}
		Admin.AreaEditor.Start = LocalPlayer():GetPos()
		Admin.AreaEditor.Type = AREA_START
		Admin.AreaEditor.Opened = true
	elseif id == 1022 then -- End Add
		Admin.AreaEditor = {}
		Admin.AreaEditor.Start = LocalPlayer():GetPos()
		Admin.AreaEditor.Type = AREA_FINISH
		Admin.AreaEditor.Opened = true
	elseif id == 1024 then -- Start Add Stop
		if Admin.AreaEditor and Admin.AreaEditor.Opened and Admin.AreaEditor.Type == AREA_START then
			local Start, End = Admin.AreaEditor.Start, LocalPlayer():GetPos()
			local Min = Vector(math.min(Start.x, End.x), math.min(Start.y, End.y), math.min(Start.z, End.z))
			local Max = Vector(math.max(Start.x, End.x), math.max(Start.y, End.y), math.max(Start.z + 128, End.z + 128))
			AdminCommand(id, {GetVectorString(Min, true), GetVectorString(Max, true)})
		else
			AddText(TEXT_ADMIN, "No areaeditor opened or start/end types did not match!")
		end
	elseif id == 1025 then -- End Add Stop
		if Admin.AreaEditor and Admin.AreaEditor.Opened and Admin.AreaEditor.Type == AREA_FINISH then
			local Start, End = Admin.AreaEditor.Start, LocalPlayer():GetPos()
			local Min = Vector(math.min(Start.x, End.x), math.min(Start.y, End.y), math.min(Start.z, End.z))
			local Max = Vector(math.max(Start.x, End.x), math.max(Start.y, End.y), math.max(Start.z + 128, End.z + 128))
			AdminCommand(id, {GetVectorString(Min, true), GetVectorString(Max, true)})
		else
			AddText(TEXT_ADMIN, "No areaeditor opened or start/end types did not match!")
		end
	elseif id == 1026 or id == 1027 then
		if Admin.AreaEditor and Admin.AreaEditor.Opened then
			Admin.AreaEditor = {}
			AddText(TEXT_ADMIN, "Area Editing cancelled!")
		end
	elseif id == 1031 then
		if Admin.SelectedData and type(Admin.SelectedData) == "table" then
			if not map:GetValue() or map:GetValue() == "" then return end
			AdminCommand(id, {map:GetValue(), Admin.SelectedData[1], Admin.SelectedData[2]})
		end
	elseif id == 1040 then
		if not map:GetValue() or map:GetValue() == "" then return end
		AdminCommand(id, {map:GetValue()})
	elseif id == 1041 then
		if not extend:GetValue() or extend:GetValue() == "" or not tonumber(extend:GetValue()) then return end
		AdminCommand(id, {extend:GetValue()})
	elseif id == 1042 then
		if not points:GetValue() or points:GetValue() == "" or not tonumber(points:GetValue()) then return end
		AdminCommand(id, {points:GetValue()})
	elseif id == 1043 then
		if boxstart:GetValue() == "" or boxend:GetValue() == "" or not tonumber(boxstart:GetValue()) or not tonumber(boxend:GetValue()) then return end
		AdminCommand(id, {tonumber(boxstart:GetValue()), tonumber(boxend:GetValue())})
	elseif id == 1051 then
		local AD = parent.SetData
		local Menu_Items = {}
		for k,v in pairs(Admin.Strings.Specials) do
			table.insert(Menu_Items, { Text = v[1], ID = k })
		end
		PromptForChoice("[Special] Add: Select Type", Menu_Items, function(Dlg, Itm, Prm)
			PromptStringRequest("[Special] Add - Enter Data - " .. Admin.Strings.Specials[Itm.ID][1], "Data (Player Pos: " .. ((LocalPlayer() and LocalPlayer():GetPos()) and GetVectorString(LocalPlayer():GetPos(), true) or "") .. ")", AD and AD or Admin.Strings.Specials[Itm.ID][2], function(Str)
				if Str == "gui" then
					AdminExecute({ SetID = 10510, SetData = Itm.ID })
				elseif Str == "nogui" then
					Admin.AreaEditor = {}
				else
					AdminCommand(id, {Itm.ID, Str})
				end
			end)
			Dlg:Close()
		end)
	elseif id == 1052 then
		PromptStringRequest("[Special] Edit: Enter Data", "Data:", Admin.SelectedData and Admin.SelectedData[2] or "", function(Str)
			AdminCommand(id, {Admin.SelectedData and Admin.SelectedData[1] or nil, Str})
		end)
	elseif id == 1053 then
		proc = true
		data = {(Admin.SelectedData and type(Admin.SelectedData) == "table") and (Admin.SelectedData[1] and tonumber(Admin.SelectedData[1])) or nil}
	elseif id == 2011 then
		if Admin.SelectedData and type(Admin.SelectedData) == "table" then
			AdminCommand(1031, Admin.SelectedData)
		end
	elseif id == 2020 then
		if to:GetValue() == "" and topos:GetValue() != "" then
			AdminCommand(id, {from:GetValue() or "", topos:GetValue(), "true"})
		else
			AdminCommand(id, {from:GetValue() or "", to:GetValue() or ""})
		end
	elseif id == 2030 then
		AdminCommand(id, {txtplayer:GetValue() or "", power:GetValue() or "10000"})
	elseif id == 2032 then
		AdminCommand(id, {txtplayer:GetValue() or ""})
	elseif id == 2035 then
		AdminCommand(2032, {txtplayer:GetValue() or "", "true"})
	elseif id == 2036 then
		AdminCommand(id, {txtplayer:GetValue() or "", power:GetValue() or "10000"})
	elseif id == 2037 then
		AdminCommand(id, {txtplayer:GetValue() or "", power:GetValue() or "00:00"})
	elseif id == 2040 then
		local Menu_Items = {
			{ Text = "Permanent", Time = 0 },
			{ Text = "2 Weeks", Time = 20160 },
			{ Text = "1 Week", Time = 10080 },
			{ Text = "3 Days", Time = 4320 },
			{ Text = "1 Day", Time = 1440 },
			{ Text = "12 Hours", Time = 720 },
			{ Text = "6 Hours", Time = 360 },
			{ Text = "1 Hour", Time = 60 }
		}
		PromptForChoice("[Scripter] Add: Select Duration", Menu_Items, function(Dlg, Itm, Prm)
			PromptStringRequest("[Scripter] Add: Enter Reason", "Reason", "Scripting: clarification", function(Str)
				AdminCommand(id, {txtplayer:GetValue() or "", Itm.Time, Str})
			end)
			Dlg:Close()
		end)
	elseif id == 2042 or id == 2043 then
		AdminCommand(id, {txtplayer:GetValue()})
	elseif id == 3012 or id == 3013 then
		AdminCommand(id, {txtplayer:GetValue()})
	elseif id == 10510 then
		local AD = parent.SetData
		if not AD then return end
		
		if Admin.AreaEditor and Admin.AreaEditor.Opened and Admin.AreaEditor.Type == "SPECIAL" then
			local Start, End = Admin.AreaEditor.Start, LocalPlayer():GetPos()
			local Min = Vector(math.min(Start.x, End.x), math.min(Start.y, End.y), math.min(Start.z, End.z))
			local Max = Vector(math.max(Start.x, End.x), math.max(Start.y, End.y), math.max(Start.z + 128, End.z + 128))
			PromptStringRequest("Confirm Bonus Positions", "Data:", GetVectorString(Min, true) .. ";" .. GetVectorString(Max, true), function(Str)
				AdminCommand(1051, {tonumber(AD), Str})
			end)
		else
			Admin.AreaEditor = {}
			Admin.AreaEditor.Start = LocalPlayer():GetPos()
			Admin.AreaEditor.Type = "SPECIAL"
			Admin.AreaEditor.Data = AD
			Admin.AreaEditor.Opened = true
		end
	else
		proc = true
	end

	if proc then AdminCommand(id, data) end
end

function AdminCommand(id, args)
	if args then
		RunConsoleCommand("bhop_adm", tostring(id), unpack(args))
	else
		RunConsoleCommand("bhop_adm", tostring(id))
	end
end

local function AdminCallback()
	local id = net.ReadInt(12)
	local data = net.ReadTable()
	
	if id == 1030 then
		local i = Admin.ItemInsert
		if #Admin.Items[i]:GetLines() > 0 then
			Admin.Items[i]:Clear()
		else
			Admin.Items[i]:AddColumn("ID"):SetWidth(30)
			Admin.Items[i]:AddColumn("UID"):SetWidth(75)
			Admin.Items[i]:AddColumn("Time"):SetWidth(75)
			Admin.Items[i]:AddColumn("Name")
		end
		
		if data and data[1] then
			for k,v in pairs(data) do
				Admin.Items[i]:AddLine(v[1], v[4], ConvertTime(tonumber(v[3])), v[2])
			end
		else
			Admin.Items[i]:AddLine("", "", "", "No data!")
		end
	elseif id == 1050 then
		local i = Admin.ItemInsert
		if #Admin.Items[i]:GetLines() > 0 then
			Admin.Items[i]:Clear()
		else
			Admin.Items[i]:AddColumn("ID"):SetWidth(30)
			Admin.Items[i]:AddColumn("Type"):SetWidth(100)
			Admin.Items[i]:AddColumn("Data")
		end

		if data and data[1] and data[1]["nType"] then
			for k,v in pairs(data) do
				Admin.Items[i]:AddLine(v["nID"], Admin.Strings.Specials[v["nType"]][1], v["szData"])
			end
		else
			Admin.Items[i]:AddLine("", "", "No specials found!")
		end
	elseif id == 2010 then
		local i = Admin.ItemInsert
		if #Admin.Items[i]:GetLines() > 0 then
			Admin.Items[i]:Clear()
		else
			Admin.Items[i]:AddColumn("ID"):SetWidth(30)
			Admin.Items[i]:AddColumn("UID"):SetWidth(75)
			Admin.Items[i]:AddColumn("Time"):SetWidth(75)
			Admin.Items[i]:AddColumn("Map"):SetWidth(120)
			Admin.Items[i]:AddColumn("Name")
		end
		
		if data and data[1] then
			for k,v in pairs(data) do
				Admin.Items[i]:AddLine(v[1], v[4], ConvertTime(tonumber(v[3])), v[5], v[2])
			end
		else
			Admin.Items[i]:AddLine("", "", "", "", "No data!")
		end
	elseif id == 2041 then
		local i = Admin.ItemInsert
		if #Admin.Items[i]:GetLines() > 0 then
			Admin.Items[i]:Clear()
		else
			Admin.Items[i]:AddColumn("ID"):SetWidth(30)
			Admin.Items[i]:AddColumn("UID"):SetWidth(75)
			Admin.Items[i]:AddColumn("Name")
			Admin.Items[i]:AddColumn("Expire"):SetWidth(55)
			Admin.Items[i]:AddColumn("Date"):SetWidth(120)
			Admin.Items[i]:AddColumn("Admin"):SetWidth(90)
			Admin.Items[i]:AddColumn("Reason")
		end
		
		if data and data[1] then
			for k,v in pairs(data) do
				Admin.Items[i]:AddLine(v[1], v[2], v[3], v[4], v[6], v[7], v[5])
			end
		else
			Admin.Items[i]:AddLine("", "", "No data!", "", "", "", "")
		end
	end
end
net.Receive("BHOP_ADM", AdminCallback)

local DrawLaser = Material("trails/laser")
local DrawColor = Color(50, 0, 255, 255)

hook.Add("PostDrawOpaqueRenderables", "DrawPreview", function()
	if Admin.AreaEditor and Admin.AreaEditor.Opened then
		local Start = Admin.AreaEditor.Start
		local End = LocalPlayer():GetPos()
		local Min = Vector(math.min(Start.x, End.x), math.min(Start.y, End.y), math.min(Start.z, End.z))
		local Max = Vector(math.max(Start.x, End.x), math.max(Start.y, End.y), math.max(Start.z + 128, End.z + 128))
		local C1, C2, C3, C4 = Vector(Min.x, Min.y, Min.z), Vector(Min.x, Max.y, Min.z), Vector(Max.x, Max.y, Min.z), Vector(Max.x, Min.y, Min.z)
	
		render.SetMaterial(DrawLaser)
		render.DrawBeam(C1, C2, 10, 0, 1, DrawColor) 
		render.DrawBeam(C2, C3, 10, 0, 1, DrawColor)
		render.DrawBeam(C3, C4, 10, 0, 1, DrawColor)
		render.DrawBeam(C4, C1, 10, 0, 1, DrawColor)
	end
end)