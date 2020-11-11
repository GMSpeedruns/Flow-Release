local wndHelpText = {"Welcome to the Prestige Gaming Bunny Hop Server!", "", "In this gamemode, your goal is to reach the end of", "the map, utilizing your bunny hop possibilities along", "with strafing to land on the platforms succesfully!", "Sometimes levels are of a high difficulty; try your best", "to conquer these levels as they will give you satisfaction", "upon completion.", "", "Have fun, and good luck!", "", "Gamemode Controls:", "F1: Show this help window", "F2: Go into spectate mode; In spectator mode:", "- Use the left/right mouse button to switch through players", "- Use the reload key to go into free roam mode", "F3: Toggle third person mode", "", "Chat Commands:", "!help or !commands: Show this window", "!rtv: Vote to change the map, if you're too impatient to have it occur normally.", "!timeleft: Shows how long the map has left", "!motd: Show pG's MOTD", "!r or !restart: Reset your position to the start", "!wr [mode]: Shows the world records for this map", "!mode or !style: Select your bhop play style", "!auto/!sideways/!wonly/!normal: Change bhop mode", "!nominate: Select a map to be added to the list of next possible maps", "!top or !toplist: Shows the top players of our server", "!rank: Shows your rank and the coming ranks", "!points [map]: Shows how many points a map is worth. Example: !points bhop_eazy_v2", "!beat or !mapsbeat: Shows the maps you have beaten", "!left or !mapsleft: Shows the maps you still need to beat", "!spawn: Use in free spectator, teleports you to your spectator location", "!noweapons or !remove or !stripweapons: Remove your weapons", "!usp or !glock or !knife: Give you the appropriate weapon", "!show or !showplayers: Show other players on your screen", "!hide or !hideplayers: Remove other players from your screen", "!showgui or !showhud: Show the HUD", "!hidegui or !hidehud: Hides the HUD", "!showspec: Shows the spectator list", "!hidespec: Hides the spectator list", "", "Bot Commands", "!bot: Show current bot data", "!bot who: Show who is currently being recorded by the WR Bot", "!bot record [me]: Call to be recorded", "!bot record stop: If you are recorded, this will stop it.", "", "Extra Commands", "!lj: Toggle LJ Stats", "!spec [player]: Directly spectate a player", "!chat or !togglechat: Hides or shows the chat", "!(un)muteall: Mutes players", "", "Bhop Styles:", "- Normal: You can use all keys and have to jump with scroll wheel", "- Sideways: You can only use W/S and jump with scroll/auto", "- W-Only: You can only use W and jump with scroll/auto", "- Teleportation: With this style you can teleport to other players and", "  hold space to bunny hop. Commands: !tpto or !tele [player]", "- Auto Hop: With this style could can bunny hop normally but", "  you can hold space to make perfect jumps!", "", "Console Commands", "- cl_showothers: Show or hide other players", "- cl_showspec: Show or hide the spectator list", "- cl_showgui: Show or hide the HUD"}

wnd = {
	["Visible"] = nil,
	["Form"] = nil,
	["Stored"] = nil,
	["WR"] = {["Dimension"] = {235, 290},	["Title"] = "Records"},
	["Mode"] = {["Dimension"] = {145, 170}, ["Title"] = "Style"},
	["Nominate"] = {["Dimension"] = {230, 250}, ["Title"] = "Nominate"},
	["Beat"] = {["Dimension"] = {230, 250}, ["Title"] = "Maps Beat"},
	["Left"] = {["Dimension"] = {210, 250}, ["Title"] = "Maps Left"},
	["Top"] = {["Dimension"] = {250, 265}, ["Title"] = "Top 10"},
	["Rank"] = {["Dimension"] = {210, 250}, ["Title"] = "Ranks"},
	["Vote"] = {["Dimension"] = {220, 170}, ["Title"] = "Voting"},
	["Spectate"] = {["Dimension"] = {140, 80}, ["Title"] = "Spectate?"},
	["Help"] = {["Dimension"] = {650, 400}, ["Custom"] = true},
	["Admin"] = {["Dimension"] = {550, 350}, ["Custom"] = true},
}

HUD_BLUE, HUD_LGRAY, HUD_DGRAY, COLOR_WHITE = Color(0, 120, 255, 255), Color(50, 50, 50, 255), Color(40, 40, 40, 255), Color(255, 255, 255)

surface.CreateFont("HUDHeaderBig", {size = 44, font = "Coolvetica"})
surface.CreateFont("HUDHeader", {size = 30, font = "Coolvetica"})
surface.CreateFont("HUDHeaderSmall", {size = 20, font = "Coolvetica"})
surface.CreateFont("HUDTitle", {size = 24, font = "Coolvetica"})
surface.CreateFont("HUDFont", {size = 22, weight = 800, font = "Tahoma"})
surface.CreateFont("HUDFontSmall", {size = 14, weight = 800, font = "Tahoma"})
surface.CreateFont("HUDLabel", {size = 17, weight = 550, font = "Verdana"})
surface.CreateFont("HUDLabelSpecial", {size = 17, weight = 550, font = "Verdana", italic = true})
surface.CreateFont("HUDLabelSmall", {size = 12, weight = 800, font = "Tahoma"})

KeyLimit = false

function SetActiveWindow(identifier, arg)
	if wnd["Visible"] and wnd["Form"] and wnd["Form"].Close then
		if wnd["Form"].Data and wnd["Form"].Data.ID == "Vote" then return end
		wnd["Form"]:Close()
		wnd["Form"] = nil
		wnd["Visible"] = nil
	elseif wnd["Visible"] and wnd["Form"] then
		if wnd["Form"].Data and wnd["Form"].Data.ID == "Vote" then return end
		wnd["Form"] = nil
		wnd["Visible"] = nil
	end

	if wnd[identifier] then
		wnd["Visible"] = wnd[identifier]
		wnd["Form"] = InitActiveWindow(identifier, arg)
	end
end

function IsWindowActive(identifier)
	if wnd and wnd["Form"] and wnd["Form"].Data then
		if wnd["Form"].Data.ID == identifier then
			return true
		end
	end
	return false
end

function InitActiveWindow(identifier, arg)
	if not wnd["Visible"] then return nil end
	if wnd["Visible"]["Custom"] then return InitCustomWindow(identifier) end
	
	local window = RestoreWindow(identifier)
	if window then
		window:Show()
		return window
	end
	
	window = vgui.Create("DFrame")
	window:SetTitle("")
	window:SetSize(wnd["Visible"]["Dimension"][1], wnd["Visible"]["Dimension"][2])
	window:SetPos(20, ScrH() / 2 - window:GetTall() / 2)
	window:SetDraggable(false)
	window:ShowCloseButton(false)
	
	window.Data = LoadWindowData(identifier, window, arg)
	window.Think = WindowThink
	
	window.Paint = function()
		local w, h = window:GetWide(), window:GetTall()
		surface.SetDrawColor(HUD_DGRAY)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(HUD_LGRAY)
		surface.DrawRect(10, 30, w - 20, h - 40)
		draw.SimpleText(wnd["Visible"]["Title"], "HUDTitle", 10, 5, HUD_BLUE, TEXT_ALIGN_LEFT)
	end

	return window
end

function StoreWindow(window, identifier, delete)
	if wnd["Stored"] then
		if wnd["Stored"].Window and wnd["Stored"].Window.Close and not delete then
			wnd["Stored"].Window:Close()
		end
		
		wnd["Stored"] = nil
	end
	
	wnd["Stored"] = { Identifier = identifier, Window = window }
end

function RestoreWindow(identifier)
	if wnd["Stored"] and wnd["Stored"].Identifier == identifier then
		local Window = wnd["Stored"].Window
		wnd["Stored"] = nil
		return Window
	end
	
	return false
end

function InitCustomWindow(identifier)
	local window = RestoreWindow(identifier)
	if window then
		window:MakePopup()
		window:Show()
		return window
	end
	
	window = vgui.Create("DFrame")
	window:SetDeleteOnClose(false)
	window.OnClose = function() StoreWindow(window, identifier, true) end

	if identifier == "Help" then
		window:SetTitle("")
		window:SetSize(wnd["Visible"]["Dimension"][1], wnd["Visible"]["Dimension"][2])
		window:Center()
		window.SetDText = "Bunny Hop"
		
		local list = vgui.Create("DPanelList", window)
		list:SetSize(window:GetWide() - 12, window:GetTall() - 50)
		list:SetPos(8, 45)
		list:EnableVerticalScrollbar(true)
		
		for i = 1, #wndHelpText do
			local text = vgui.Create("DLabel", window)
			text:SetFont("HUDHeaderSmall")
			text:SetColor(COLOR_WHITE)
			text:SetText(wndHelpText[i])
			text:SizeToContents()
			list:AddItem(text)
		end
		
		window.Paint = function()
			local w, h = window:GetWide(), window:GetTall()
			surface.SetDrawColor(HUD_DGRAY)
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(HUD_LGRAY)
			surface.DrawRect(5, 5, w - 10, h - 10)
			surface.SetDrawColor(LocalPlayer() and team.GetColor(LocalPlayer():Team()) or Color(25, 25, 25, 150))
			surface.DrawOutlinedRect(4, 4, w - 8, 40)
			draw.SimpleText(window.SetDText, "HUDHeader", w / 2 + 2, 10, Color(25, 25, 25, 255), TEXT_ALIGN_CENTER)
			draw.SimpleText(window.SetDText, "HUDHeader", w / 2, 8, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER)
		end
		
		window:MakePopup()
	elseif identifier == "Admin" then
		if Admin.SelfAccess == 0 then window:Close() window = nil return end
		window:SetTitle("Admin Control Panel")
		window:SetSize(wnd["Visible"]["Dimension"][1], wnd["Visible"]["Dimension"][2])
		window:Center()
		window:SetDraggable(false)
		window:ShowCloseButton(true)
		window:MakePopup()
		
		AdminLoad(window, identifier)
	end
	
	return window
end

function LoadWindowData(identifier, window, arg)
	local data = {["ID"] = identifier, ["Labels"] = {}, ["Offset"] = 35}

	if identifier == "Nominate" then
		data.Voted = false
		data.Pages = math.ceil(#NominateList / 7)
		data.Page = 1
	
		local navigationText = {"Previous", "Next", "Close"}
		for i = 1, 10 do
			data.Labels[i] = wnd.MakeLabel{ parent = window, x = 15, y = data.Offset, font = "HUDLabel", color = COLOR_WHITE, text = i > 7 and "(" .. string.gsub(tostring(i), "1", "") .. ") " .. navigationText[i - 7] or "(" .. i .. ") " .. NominateList[i] }
			data.Offset = data.Offset + 20
		end
	elseif identifier == "Vote" then
		data.Voted = false
		data.VotedID = -1
		data.VoteEnd = CurTime() + 30
		data.Votes = {0, 0, 0, 0, 0, 0}
		data.PointList = {0, 0, 0, 0, 0, -1}
		
		timer.Simple(30, function()
			if wnd["Form"] and wnd["Form"].Data and wnd["Form"].Data.ID == "Vote" then
				wnd["Form"]:Close()
				wnd["Form"] = nil
			end
		end)
		
		for i = 1, 6 do
			if i < 6 then
				data.PointList[i] = MapPointList[VoteList[i]]
				VoteList[i] = FriendlyName(VoteList[i])
			else
				data.PointList[i] = MapPointList[game.GetMap()]
				VoteList[i] = "Extend Current Map"
			end

			data.Labels[i] = wnd.MakeLabel{ parent = window, x = 15, y = data.Offset, font = "HUDLabel", color = GetMapColor(data.PointList[i]), text = i .. " [" .. data.Votes[i] .. "] " .. VoteList[i] }
			data.Offset = data.Offset + 20
		end
	elseif identifier == "Mode" then
		MODE_NAME[7] = "Close"
		for i = 1, 7 do
			data.Labels[i] = wnd.MakeLabel{ parent = window, x = 15, y = data.Offset, font = "HUDLabelSmall", color = i == PlayerMode and Color(212, 68, 68, 255) or COLOR_WHITE, text = (i > 6 and 0 or i) .. ". " .. MODE_NAME[i] }
			data.Offset = data.Offset + (i == 6 and 24 or 16)
		end
		MODE_NAME[7] = nil
	elseif identifier == "WR" then
		data.View = arg or MODE_AUTO
		wnd["Visible"]["Title"] = MODE_NAME[data.View] .. " Records"
		
		if RecordList and RecordList[data.View] and #RecordList[data.View] > 0 then
			for k,v in pairs(RecordList[data.View]) do
				data.Labels[k] = wnd.MakeLabel{ parent = window, x = 15, y = data.Offset, font = "HUDLabelSmall", color = COLOR_WHITE, text = "#" .. k .. " [" .. ConvertTime(v[1]) .. "]: " .. v[2] }
				data.Offset = data.Offset + 16
			end
		else
			data.Labels[1] = wnd.MakeLabel{ parent = window, x = 15, y = data.Offset, font = "HUDLabelSmall", color = COLOR_WHITE, text = "No records!" }
			data.Offset = data.Offset + 16
		end
		
		local lID = #data.Labels + 1
		data.Labels[lID] = wnd.MakeLabel{ parent = window, x = 15, y = 290 - 42, font = "HUDLabelSmall", color = COLOR_WHITE, text = "Press '9' to cycle through WRs" }
		data.Labels[lID + 1] = wnd.MakeLabel{ parent = window, x = 15, y = 290 - 26, font = "HUDLabelSmall", color = COLOR_WHITE, text = "Press '0' to close the window" }
		data.Offset = data.Offset + 16
	elseif identifier == "Beat" then
		data.BeatCount = #MapsBeatList
		data.Page = 1
		data.Pages = math.ceil(#MapsBeatList / 7)
		data.Maps = {}
		wnd["Visible"]["Title"] = "Maps Beat: " .. data.BeatCount
		
		for k,v in pairs(MapsBeatList) do
			data.Maps[k] = {FriendlyName(v["szMap"]), tonumber(v["nTime"])}
		end
		
		if #data.Maps == 0 then
			data.Labels[1] = wnd.MakeLabel{ parent = window, x = 15, y = data.Offset, font = "HUDLabel", color = COLOR_WHITE, text = "No beaten maps" }
			data.Offset = data.Offset + 20
			return
		end
		
		local navigationText = {"Previous", "Next", "Close"}
		for i = 1, 10 do
			local lblText = ""
			if i > 7 then
				lblText = "(" .. string.gsub(tostring(i), "1", "") .. ") " .. navigationText[i - 7]
			elseif data.Maps[i] then
				lblText = "(" .. ConvertTime(data.Maps[i][2]) .. ") " .. data.Maps[i][1]
			end
			
			data.Labels[i] = wnd.MakeLabel{ parent = window, x = 15, y = data.Offset, font = "HUDLabel", color = COLOR_WHITE, text = lblText }
			data.Offset = data.Offset + 20
		end
		
		data.Labels[8]:SetVisible(false)
		if data.BeatCount < 8 then data.Labels[9]:SetVisible(false) end
	elseif identifier == "Left" then
		local Temporary = {}
		data.Page = 1
		data.Maps = {}

		for k,v in pairs(MapPointList) do
			Temporary[k] = v
		end

		for k,v in pairs(MapsBeatList) do
			Temporary[v["szMap"]] = nil
		end
		
		for k,v in pairs(Temporary) do
			table.insert(data.Maps, {k, FriendlyName(k), v})
		end

		table.sort(data.Maps, function(a, b)
			return a[3] < b[3]
		end)
		
		data.LeftCount = #data.Maps
		data.Pages = math.ceil(#data.Maps / 7)
		wnd["Visible"]["Title"] = "Maps Left: " .. data.LeftCount
		
		if #data.Maps == 0 then
			data.Labels[1] = wnd.MakeLabel{ parent = window, x = 15, y = data.Offset, font = "HUDLabel", color = COLOR_WHITE, text = "No maps left" }
			data.Offset = data.Offset + 20
			return
		end
		
		local navigationText = {"Previous", "Next", "Close"}
		for i = 1, 10 do
			local lblText = ""
			if i > 7 then
				lblText = "(" .. string.gsub(tostring(i), "1", "") .. ") " .. navigationText[i - 7]
			elseif data.Maps[i] then
				lblText = "[" .. data.Maps[i][3] .. "] " .. data.Maps[i][2]
			end
			data.Labels[i] = wnd.MakeLabel{ parent = window, x = 15, y = data.Offset, font = "HUDLabel", color = COLOR_WHITE, text = lblText }
			data.Offset = data.Offset + 20
		end
		
		data.Labels[8]:SetVisible(false)
		if data.LeftCount < 8 then data.Labels[9]:SetVisible(false) end
	elseif identifier == "Top" then
		for i = 1, 11 do
			local lblText = ""
			if i > 10 then
				lblText = "(0) Close"
			elseif TopList[i] then
				lblText = i .. ": [" .. tonumber(string.format("%.2f", TopList[i][2])) .. "] " .. TopList[i][1]
			end
			data.Labels[i] = wnd.MakeLabel{ parent = window, x = 15, y = data.Offset, font = "HUDLabel", color = i == 1 and HUD_BLUE or COLOR_WHITE, text = lblText }
			data.Offset = data.Offset + 20
		end
	elseif identifier == "Rank" then
		data.Page = 1
		data.Pages = math.ceil(#GAMEMODE.RankList / 7) or 1
		data.RankID = 1
		data.RankPage = 1
		
		if arg and type(arg) == "table" then
			data.RankID = arg[1]
			data.RankWeight = arg[2]
			data.RankPage = math.ceil(data.RankID / 7) or 1
			data.Page = data.RankPage
			wnd["Visible"]["Title"] = "Ranks - " .. tonumber(string.format("%.0f", data.RankWeight)) .. " pts"
		end
		
		local navigationText = {"Previous", "Next", "Close"}
		for i = 1, 10 do
			local Index = 7 * data.RankPage - 7
			local lblText, lblColor, lblFont = "", COLOR_WHITE, "HUDLabel"
			if i > 7 then
				lblText = "(" .. string.gsub(tostring(i), "1", "") .. ") " .. navigationText[i - 7]
			elseif GAMEMODE.RankList[Index + i] then
				lblText = GAMEMODE.RankList[Index + i][1] .. ": " .. GAMEMODE.RankList[Index + i][3]
				lblColor = GAMEMODE.RankList[Index + i][2] or COLOR_WHITE
				if Index + i == data.RankID then lblFont = "HUDLabelSpecial" end
			end
			data.Labels[i] = wnd.MakeLabel{ parent = window, x = 15, y = data.Offset, font = lblFont, color = lblColor, text = lblText }
			data.Offset = data.Offset + 20
		end
		
		if data.Page == 1 then data.Labels[8]:SetVisible(false) end
		if data.Pages * 7 < 8 then data.Labels[9]:SetVisible(false) end
	elseif identifier == "Spectate" then
		wnd["Visible"]["Title"] = (LocalPlayer() and LocalPlayer():Team() == TEAM_SPECTATOR) and "Stop Spec?" or "Spectate?"
		window:Center()
		window:MakePopup()

		wnd.MakeButton{ parent = window, w = 32, h = 24, x = 33, y = 38, text = "Yes", onclick = function() SetActiveWindow("None") RunConsoleCommand("bhop_spectate") end }
		wnd.MakeButton{ parent = window, w = 32, h = 24, x = 75, y = 38, text = "No", onclick = function() SetActiveWindow("None") end }
	end
	
	return data
end

function WindowThink()
	local Form = wnd["Form"]
	if not Form then return end
	
	local Data = wnd["Form"].Data
	if not Data then return end

	local KeyLimitDelay = 0.25
	local Key = -1
	for KEY = 1, 10 do
		if input.IsKeyDown(KEY) then
			Key = KEY - 1
			break
		end
	end

	if Data.ID == "Nominate" then
		if Key > 0 and Key < 8 and not KeyLimit then
			local VotedID = MapList[7 * Data.Page - 7 + Key]
			if not VotedID then return end
			Data.Voted = true
			
			RunConsoleCommand("rtv_nominate", VotedID)
			surface.PlaySound("garrysmod/save_load1.wav")
			timer.Simple(0.25, function() Form:Close() wnd["Form"] = nil end)
		elseif Key == 8 and not KeyLimit and not Data.Voted and Data.Page != 1 then
			Data.Page = Data.Page - 1
			local Index = 7 * Data.Page - 7
			
			for i = 1, 7 do
				Data.Labels[i]:SetText("(" .. i .. ") " .. NominateList[Index + i])
				Data.Labels[i]:SizeToContents()
				Data.Labels[i]:SetVisible(true)
			end
			
			wnd.PageToggle(Data, true)
		elseif Key == 9 and not KeyLimit and not Data.Voted and Data.Page != Data.Pages then
			Data.Page = Data.Page + 1
			local Index = 7 * Data.Page - 7
			
			for i = 1, 7 do
				if NominateList[Index + i] then
					Data.Labels[i]:SetText("(" .. i .. ") " .. NominateList[Index + i])
					Data.Labels[i]:SizeToContents()
					Data.Labels[i]:SetVisible(true)
				else
					Data.Labels[i]:SetText("")
					Data.Labels[i]:SetVisible(false)
				end
			end
			
			wnd.PageToggle(Data, false)
		end
	elseif Data.ID == "Vote" then
		local TimeTitle = "Voting (" .. math.ceil(math.Clamp(Data.VoteEnd - CurTime(), 0, 30)) .. "s left)"
		if TimeTitle != wnd["Visible"]["Title"] then wnd["Visible"]["Title"] = TimeTitle end
		
		if Key > 0 and Key < 7 and not KeyLimit and not Data.Voted then
			Data.Voted = true
			Data.VotedID = Key
			Data.Labels[Key]:SetColor(GetMapColor(Data.PointList[Key], true))
			
			RunConsoleCommand("rtv_vote", tostring(Key))
			surface.PlaySound("garrysmod/save_load1.wav")
			
			KeyLimitDelay = 3
		elseif Key > 0 and Key < 7 and not KeyLimit and Data.Voted and Key != Data.VotedID then
			Data.Labels[Data.VotedID]:SetColor(GetMapColor(Data.PointList[Data.VotedID]))
			Data.Labels[Key]:SetColor(GetMapColor(Data.PointList[Key], true))

			RunConsoleCommand("rtv_vote", tostring(Key), tostring(Data.VotedID))
			surface.PlaySound("garrysmod/save_load1.wav")
			
			Data.VotedID = Key
			KeyLimitDelay = 3
		end
		
		if Data.NewVoteData then
			Data.NewVoteData = false
			for i = 1, 6 do
				if not Data.Votes[i] or not VoteList[i] then continue end
				Data.Labels[i]:SetText(i .. " [" .. Data.Votes[i] .. "] " .. VoteList[i])
				Data.Labels[i]:SizeToContents()
			end
		end
	elseif Data.ID == "Mode" then
		if Key > 0 and Key < 7 and not KeyLimit and not Data.Selected then
			Data.Selected = true
			RunConsoleCommand("bhop_mode", tostring(Key))
			Key = 0
		end
	elseif Data.ID == "WR" then
		if Key == 9 and not KeyLimit then
			local NewView = Data.View + 1 > MODE_BONUS and MODE_AUTO or Data.View + 1
			if NewView == MODE_PRACTICE then NewView = NewView + 1 end
			SetActiveWindow("WR", NewView)
			KeyLimitDelay = 1
		end
	elseif Data.ID == "Beat" then
		if Key == 8 and not KeyLimit and Data.Page != 1 then
			Data.Page = Data.Page - 1
			local Index = 7 * Data.Page - 7
			
			for i = 1, 7 do
				Data.Labels[i]:SetText("(" .. ConvertTime(Data.Maps[Index + i][2]) .. ") " .. Data.Maps[Index + i][1])
				Data.Labels[i]:SizeToContents()
				Data.Labels[i]:SetVisible(true)
			end
			
			wnd.PageToggle(Data, true)
		elseif Key == 9 and not KeyLimit and Data.Page != Data.Pages then
			Data.Page = Data.Page + 1
			local Index = 7 * Data.Page - 7
			
			for i = 1, 7 do
				if Data.Maps[Index + i] then
					Data.Labels[i]:SetText("(" .. ConvertTime(Data.Maps[Index + i][2]) .. ") " .. Data.Maps[Index + i][1])
					Data.Labels[i]:SizeToContents()
					Data.Labels[i]:SetVisible(true)
				else
					Data.Labels[i]:SetText("")
					Data.Labels[i]:SetVisible(false)
				end
			end
			
			wnd.PageToggle(Data, false)
		end
	elseif Data.ID == "Left" then
		if Key > 0 and Key < 8 and not KeyLimit then
			if Data.LeftCount == 0 then return end
			local Vote = Data.Maps[7 * Data.Page - 7 + Key]
			if not Vote then return end
			
			RunConsoleCommand("rtv_nominate", Vote[1])
			surface.PlaySound("garrysmod/save_load1.wav")
			Key = 0
		elseif Key == 8 and not KeyLimit and Data.Page != 1 then
			Data.Page = Data.Page - 1
			local Index = 7 * Data.Page - 7
			
			for i = 1, 7 do
				Data.Labels[i]:SetText("[" .. Data.Maps[Index + i][3] .. "] " .. Data.Maps[Index + i][2])
				Data.Labels[i]:SizeToContents()
				Data.Labels[i]:SetVisible(true)
			end
			
			wnd.PageToggle(Data, true)
		elseif Key == 9 and not KeyLimit and Data.Page != Data.Pages then
			Data.Page = Data.Page + 1
			local Index = 7 * Data.Page - 7
			
			for i = 1, 7 do
				if Data.Maps[Index + i] then
					Data.Labels[i]:SetText("[" .. Data.Maps[Index + i][3] .. "] " .. Data.Maps[Index + i][2])
					Data.Labels[i]:SizeToContents()
					Data.Labels[i]:SetVisible(true)
				else
					Data.Labels[i]:SetText("")
					Data.Labels[i]:SetVisible(false)
				end
			end
			
			wnd.PageToggle(Data, false)
		end
	elseif Data.ID == "Rank" then
		if Key == 8 and not KeyLimit and Data.Page != 1 then
			Data.Page = Data.Page - 1
			local Index = 7 * Data.Page - 7
			
			for i = 1, 7 do
				Data.Labels[i]:SetText(GAMEMODE.RankList[Index + i][1] .. ": " .. GAMEMODE.RankList[Index + i][3])
				Data.Labels[i]:SetColor(GAMEMODE.RankList[Index + i][2] or COLOR_WHITE)
				if Index + i == Data.RankID then Data.Labels[i]:SetFont("HUDLabelSpecial") else Data.Labels[i]:SetFont("HUDLabel") end
				Data.Labels[i]:SizeToContents()
				Data.Labels[i]:SetVisible(true)
			end
			
			wnd.PageToggle(Data, true)
		elseif Key == 9 and not KeyLimit and Data.Page != Data.Pages then
			Data.Page = Data.Page + 1
			local Index = 7 * Data.Page - 7
			
			for i = 1, 7 do
				if GAMEMODE.RankList[Index + i] then
					Data.Labels[i]:SetText(GAMEMODE.RankList[Index + i][1] .. ": " .. GAMEMODE.RankList[Index + i][3])
					Data.Labels[i]:SetColor(GAMEMODE.RankList[Index + i][2] or COLOR_WHITE)
					if Index + i == Data.RankID then Data.Labels[i]:SetFont("HUDLabelSpecial") else Data.Labels[i]:SetFont("HUDLabel") end
					Data.Labels[i]:SizeToContents()
					Data.Labels[i]:SetVisible(true)
				else
					Data.Labels[i]:SetText("")
					Data.Labels[i]:SetVisible(false)
				end
			end
		
			wnd.PageToggle(Data, false)
		end
	end
	
	if Key == 0 and not KeyLimit and not table.HasValue({"Vote"}, Data.ID) then
		timer.Simple(0.25, function() if wnd["Form"] and wnd["Form"].Close then wnd["Form"]:Close() wnd["Form"] = nil end end)
	end
	
	if Key > -1 and not KeyLimit then
		KeyLimit = true
		timer.Simple(KeyLimitDelay, function() KeyLimit = false end)
	end
end

function wnd.MakeLabel(t)
	local lbl = vgui.Create("DLabel", t.parent)
	lbl:SetPos(t.x, t.y)
	lbl:SetFont(t.font)
	lbl:SetColor(t.color)
	lbl:SetText(t.text)
	lbl:SizeToContents()
	return lbl
end

function wnd.MakeButton(t)
	local btn = vgui.Create("DButton", t.parent)
	btn:SetSize(t.w, t.h)
	btn:SetPos(t.x, t.y)
	btn:SetText(t.text)
	if t.id then btn.SetID = t.id end
	btn.DoClick = t.onclick
	return btn
end

function wnd.MakeTextBox(t)
	local txt = vgui.Create("DTextEntry", t.parent)
	txt:SetPos(t.x, t.y)
	txt:SetSize(t.w, t.h)
	txt:SetText(t.text)
	return txt
end

function wnd.PageToggle(data, prev)
	if not prev then
		if data.Page == data.Pages then
			data.Labels[8]:SetVisible(true)
			data.Labels[9]:SetVisible(false)
		else
			data.Labels[8]:SetVisible(true)
			data.Labels[9]:SetVisible(true)
		end
	else
		if data.Page == 1 then
			data.Labels[8]:SetVisible(false)
			data.Labels[9]:SetVisible(true)
		else
			data.Labels[8]:SetVisible(true)
			data.Labels[9]:SetVisible(true)
		end
	end
end

function PromptStringRequest( strTitle, strText, strDefaultText, fnEnter, fnCancel, strButtonText, strButtonCancelText )
	local Window = vgui.Create( "DFrame" )
		Window:SetTitle( strTitle or "Message Title (First Parameter)" )
		Window:SetDraggable( false )
		Window:ShowCloseButton( false )
		Window:SetBackgroundBlur( true )
		Window:SetDrawOnTop( true )
		
	local InnerPanel = vgui.Create( "DPanel", Window )
	
	local Text = vgui.Create( "DLabel", InnerPanel )
		Text:SetText( strText or "Message Text (Second Parameter)" )
		Text:SizeToContents()
		Text:SetContentAlignment( 5 )
		Text:SetTextColor( Color( 70, 70, 70, 255 ) )
		
	local TextEntry = vgui.Create( "DTextEntry", InnerPanel )
		TextEntry:SetText( strDefaultText or "" )
		TextEntry.OnEnter = function() Window:Close() fnEnter( TextEntry:GetValue() ) end
		
	local ButtonPanel = vgui.Create( "DPanel", Window )
		ButtonPanel:SetTall( 30 )
		
	local Button = vgui.Create( "DButton", ButtonPanel )
		Button:SetText( strButtonText or "OK" )
		Button:SizeToContents()
		Button:SetTall( 20 )
		Button:SetWide( Button:GetWide() + 20 )
		Button:SetPos( 5, 5 )
		Button.DoClick = function() Window:Close() fnEnter( TextEntry:GetValue() ) end
		
	local ButtonCancel = vgui.Create( "DButton", ButtonPanel )
		ButtonCancel:SetText( strButtonCancelText or "Cancel" )
		ButtonCancel:SizeToContents()
		ButtonCancel:SetTall( 20 )
		ButtonCancel:SetWide( Button:GetWide() + 20 )
		ButtonCancel:SetPos( 5, 5 )
		ButtonCancel.DoClick = function() Window:Close() if ( fnCancel ) then fnCancel( TextEntry:GetValue() ) end end
		ButtonCancel:MoveRightOf( Button, 5 )
		
	ButtonPanel:SetWide( Button:GetWide() + 5 + ButtonCancel:GetWide() + 10 )
	
	local w, h = Text:GetSize()
	w = math.max( w, 400 ) 
	
	Window:SetSize( w + 50, h + 25 + 75 + 10 )
	Window:Center()
	
	InnerPanel:StretchToParent( 5, 25, 5, 45 )
	
	Text:StretchToParent( 5, 5, 5, 35 )	
	
	TextEntry:StretchToParent( 5, nil, 5, nil )
	TextEntry:AlignBottom( 5 )
	
	TextEntry:RequestFocus()
	TextEntry:SelectAllText( true )
	
	ButtonPanel:CenterHorizontal()
	ButtonPanel:AlignBottom( 8 )
	
	Window:MakePopup()
	Window:DoModal()
	return Window
end

CHOICEPANEL = {}
function CHOICEPANEL:Init()
	self.List = vgui.Create("DPanelList", self)
	self.List:EnableVerticalScrollbar()
	self.List:SetPaintBackground(true)
	self.List:SetPadding(4)
	self.List:SetSpacing(1)
	self.List.Paint = function(w,h)
		draw.RoundedBox( 4, 0, 0, self.List:GetWide(), self.List:GetTall(), Color( 220, 220, 220, 255 ) )
		derma.SkinHook( "Paint", "PanelList", self.List, w, h )
	end

	self.CancelButton = vgui.Create("DButton", self)
	self.CancelButton:SetText("Cancel")
	self.CancelButton.DoClick = function(BTN) self:Close() end
end

function CHOICEPANEL:PerformLayout()
	self.btnClose:SetPos( self:GetWide() - 31 - 4, 0 )
	self.btnClose:SetSize( 31, 31 )

	self.btnMaxim:SetPos( self:GetWide() - 31*2 - 4, 0 )
	self.btnMaxim:SetSize( 31, 31 )

	self.btnMinim:SetPos( self:GetWide() - 31*3 - 4, 0 )
	self.btnMinim:SetSize( 31, 31 )
	
	self.lblTitle:SetPos( 8, 2 )
	self.lblTitle:SetSize( self:GetWide() - 25, 20 )
	
	self.List:SetTall(200)
	
	self.CancelButton:SizeToContents()
	self.CancelButton:SetWide(self.CancelButton:GetWide() + 16)
	self.CancelButton:SetTall(self.CancelButton:GetTall() + 8)

	local height = 32
		
		height = height + self.List:GetTall()
		height = height + 8
		height = height + self.CancelButton:GetTall()
		height = height + 8

	self:SetTall(height)
	
	local width = self:GetWide()

	self.List:SetPos( 8, 32 )
	self.List:SetWide( width - 16 )
	
	local btnY = 32 + self.List:GetTall() + 8
	self.CancelButton:SetPos( width - 8 - self.CancelButton:GetWide(), btnY )
end

function CHOICEPANEL:RemoveItem(BTN)
	self.List:RemoveItem(BTN)
	self:PerformLayout()
end

derma.DefineControl( "DSingleChoiceDialog", "A simple list dialog", CHOICEPANEL, "DFrame" )

function PromptForChoice( TITLE, SELECTION, FUNCTION, ... )
	local arg = {...}
	local TE = vgui.Create("DSingleChoiceDialog")
	TE:SetBackgroundBlur( true )
	TE:SetDrawOnTop( true )
	for k,v in pairs(SELECTION) do
		local item = vgui.Create("DButton")
		item:SetText( v.Text )
		item.DoClick = 
			function(BTN) 
				TE.Selection = item
				pcall( FUNCTION, TE, v, unpack(arg) )
			end
		TE.List:AddItem(item)
	end
	TE:SetTitle(TITLE)
	TE:SetVisible( true )
	TE:SetWide(300)
	TE:PerformLayout()
	TE:Center()
	TE:MakePopup()
end