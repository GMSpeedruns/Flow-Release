include("shared.lua")
include("cl_data.lua")
include("cl_scoreboard.lua")

function InitializeClient()
	timer.Create("SetHullAndView", 5, 0, SetHullAndViewOffset)
	
	if game.GetMap() == "bhop_infog" then
		hook.Add("RenderScreenspaceEffects", "InfogEffects", function()
			cam.Start3D(EyePos(), EyeAngles())
			render.SetMaterial(Material("RYAN_DEV/DEV_BLACK"))
			render.DrawQuad(Vector(2751,-3081,-757), Vector(2751,-2843,-757), Vector(2825,-2843,-757), Vector(2825,-3081,-757))
			cam.End3D()
		end)
	end
end
hook.Add( "Initialize", "CInitialize", InitializeClient )

------------
-- VIEWS --
------------

local AFK_Checks = 0
ThirdPerson = 0
SpectatorList = {}

function SetHullAndViewOffset()
	if (LocalPlayer() && LocalPlayer():IsValid() && LocalPlayer().SetHull && LocalPlayer().SetHullDuck) then
		if (LocalPlayer().SetViewOffset && LocalPlayer().SetViewOffsetDucked && !HasSetView) then
			LocalPlayer():SetViewOffset(VEC_VIEWSTAND)
			LocalPlayer():SetViewOffsetDucked(VEC_VIEWDUCK)
			HasSetView = true
		end
		LocalPlayer():SetHull(VEC_HULLMIN, VEC_HULLSTAND)
		LocalPlayer():SetHullDuck(VEC_HULLMIN, VEC_HULLDUCK)
	end
	
	if RecordString == "00:00:00" and not FinishTime and StartTime then
		if (CurTime() - StartTime) > 3600 then
			RecordString = "00:00:00:00"
		end
	else
		RecordString = ConvertTime(RecordNumber or 0)
	end
	
	
	if PLAYER_SPEED == 0 && LocalPlayer() && LocalPlayer():IsValid() && LocalPlayer():Team() != TEAM_SPECTATOR then
		AFK_Checks = AFK_Checks + 1
		if AFK_Checks >= (StartTime and PLAYER_AFK_LIMIT * 3 or PLAYER_AFK_LIMIT) then
			AddText(TEXT_BHOP, "You have been AFK for 10 minutes and therefore have been kicked!")
			RunConsoleCommand("afk_kickplayer")
		end
	else
		AFK_Checks = 0
	end
end

function GM:CalcView(ply, pos, angles, fov)
	if ThirdPerson == 1 then
		pos = pos- (angles:Forward() * 100) + (angles:Up() * 40)
		local ang = (ply:GetPos() + (angles:Up() * 30 )) - pos
		ang:Normalize()
		angles = ang:Angle()
	end
	
    return self.BaseClass:CalcView(ply, pos, angles, fov)
end

function GM:ShouldDrawLocalPlayer(ply)
	return (ThirdPerson == 1) and true or self.BaseClass:ShouldDrawLocalPlayer(ply)
end

function CalculateSpectator(Data)
	if not Data or #Data == 0 then SpectatorList = {} return end
	if Data[1] == true then -- It is a bot
		SpectatorData["IsBot"] = true
		SpectatorData["BotPlayer"] = Data[4]
		SpectatorData["StartTime"] = tonumber(Data[3])
		SpectatorData["BestTime"] = ConvertTime(tonumber(Data[5]))
		SpectatorData["Contains"] = true
	elseif Data[1] == false then -- Normal player
		if Data[2] == true then
			if Data[3] == true then
				local found = false
				for k,v in pairs(SpectatorList) do
					if v == Data[4] then
						found = true
						break
					end
				end
				if not found then table.insert(SpectatorList, Data[4]) end
			elseif Data[3] == false then
				local id = -1
				for k,v in pairs(SpectatorList) do
					if v == Data[4] then
						id = k
						break
					end
				end
				if id >= 0 then table.remove(SpectatorList, id) end
			end
		elseif Data[2] == false then
			SpectatorData["IsBot"] = false
			SpectatorData["StartTime"] = tonumber(Data[3]) < 0 and nil or tonumber(Data[3])
			SpectatorData["BestTime"] = Data[4] and ConvertTime(tonumber(Data[4])) or nil
			SpectatorData["Contains"] = true
		end
	else
		SpectatorData = {["Contains"] = false, ["IsBot"] = false, ["BotPlayer"] = "Bot", ["StartTime"] = nil, ["BestTime"] = nil}
	end
end

--------------------
-- PLAYER TIMING --
--------------------

StartTime = nil
FinishTime = nil
MapEnd = 7200 - CurTime()
RecordNumber = nil
RecordString = "00:00:00"
PlayerMode = MODE_NORMAL

function StartTimer(time)
	StartTime = time
	FinishTime = nil
end

function StopTimer(time)
	if time == 0 then StartTime = nil return end
	FinishTime = time
end

function SetRecord(time)
	RecordNumber = time
	RecordString = ConvertTime(time)
end

function ShowFinish(time)
	AddText(TEXT_TIMER, "You have finished the map in " .. ConvertTime(time) .. "!")
end

function ShowPersonal(new, old)
	if old == 0 then
		AddText(TEXT_TIMER, "You have got a new personal record of " .. ConvertTime(new) .. "!")
	else
		AddText(TEXT_TIMER, "You have got a new personal record of " .. ConvertTime(new) .. ", beating your old record of " .. ConvertTime(old) .. "! [-" .. ConvertTime(old - new) .. "]")
	end
	SetRecord(new)
end

function ShowRecord(new, old, pos)
	local rank = "-"
	if pos == 1 then rank = "1st"
	elseif pos == 2 then rank = "2nd"
	elseif pos == 3 then rank = "3rd"
	else rank = pos .. "th" end
	
	if old == 0 then
		AddText(TEXT_TIMER, "You have obtained the " .. rank .. " rank in the top 10 with a new personal record of " .. ConvertTime(new) .. "!")
	else
		AddText(TEXT_TIMER, "You have obtained the " .. rank .. " rank in the top 10 with a new personal record of " .. ConvertTime(new) .. ", beating your old record of " .. ConvertTime(old) .. "! [-" .. ConvertTime(old - new) .. "]")
	end
	SetRecord(new)
end

function SetMode(mode, rec)
	SetRecord(rec)
	PlayerMode = mode

	AddText(TEXT_BHOP, "Your mode has been switched to " .. MODE_NAME[PlayerMode] .. "!")
end

function ShowRank(id, points)
	local Current = GAMEMODE.RankList[id]
	if not Current or not tonumber(points) then return end
	
	local RankCount = #GAMEMODE.RankList
	local COLOR_WHITE = Color(255, 255, 255)
	local COLOR_BHOP = Color(168, 223, 133)
	
	chat.AddText(COLOR_WHITE, "[", COLOR_BHOP, "Bhop", COLOR_WHITE, "] You are currently [", Current[2], Current[1], COLOR_WHITE, "] with " .. points .. " points!")
	if id < RankCount then
		chat.AddText(COLOR_WHITE, "[", COLOR_BHOP, "Bhop", COLOR_WHITE, "] The upcoming rank(s):")
		
		local Max = id + 5
		if Max > RankCount then Max = RankCount end
		for i = id + 1, Max do
			chat.AddText(COLOR_WHITE, "\t\t[", GAMEMODE.RankList[i][2], GAMEMODE.RankList[i][1], COLOR_WHITE, "] " .. GAMEMODE.RankList[i][3] .. " points - Missing " .. GAMEMODE.RankList[i][3] - points)
		end
	end

	chat.PlaySound()
end

function ShowPoints(points, map)
	if points >= 0 then
		AddText(TEXT_BHOP, "The map, '" .. map .. "', is worth " .. points .. " points.")
	else
		AddText(TEXT_BHOP, "The map, '" .. map .. "', does not exist on our server and is not worth any points.")
	end
end

function ShowTime(time)
	AddText(TEXT_BHOP, "There is " .. ConvertTime(time) .. " left on this map!")
	MapEnd = 7200 - time
end

function ShowGun(value, text)
	if text == "usp" then text = "an USP" elseif text and type(text) == "string" then text = "a " .. string.upper(string.sub(text, 1, 1)) .. string.sub(text, 2) end
	if value == 0 then
		AddText(TEXT_BHOP, "You already have " .. text .. " in your weapon list.")
	elseif value == 1 then
		AddText(TEXT_BHOP, "You have been given " .. text .. "!")
	elseif value == 2 then
		AddText(TEXT_BHOP, "Your weapons have been removed!")
	end
end

------------
-- CVARs --
------------

function SetCV(id, value)
	if not tonumber(id) or not tonumber(value) then return end
	if id == 1 then
		RunConsoleCommand("cl_showgui", tostring(value))
	elseif id == 2 then
		RunConsoleCommand("cl_showspec", tostring(value))
	elseif id == 3 then
		RunConsoleCommand("cl_showothers", tostring(value))
	elseif id == 4 then
		RunConsoleCommand("cl_hudtype", tostring(1 - CVHudSpecial:GetInt()))
	elseif id == 5 then
		RunConsoleCommand("cl_timeprecision", tostring(1 - CVTime:GetInt()))
		timer.Simple(1, function() RecordString = ConvertTime(RecordNumber or 0) end)
	end
end

local function ShowPlayerCallback(CVar, PreviousValue, NewValue)
	if tonumber(NewValue) == 1 then
		for k,v in pairs(ents.FindByClass("env_spritetrail")) do
 			if v:IsValid() and v:GetParent() and v:GetParent():IsValid() and v:GetParent():IsPlayer() then
				v:SetColor(v.OldColor)
				v:SetNoDraw(false)
				v:SetModelScale(1, 0)
			end
		end
	else
		for k,v in pairs(ents.FindByClass("env_spritetrail")) do
			if v:IsValid() and v:GetParent() and v:GetParent():IsValid() and v:GetParent():IsPlayer() then
				v.OldColor = v:GetColor()
				v:SetColor(Color(255, 255, 255, 0))
				v:SetNoDraw(true)
				v:SetModelScale(0, 0)
			end
		end
	end
end
cvars.AddChangeCallback("cl_showothers", ShowPlayerCallback)

--------------------------
-- DRAWING FUNCTIONS --
--------------------------

local HUDFull = Material("pgsb/HUD.png")
local HUDPointer = Material("pgsb/HUDPointer.png")

local HiddenHUDs = {["CHudHealth"] = true, ["CHudBattery"] = true, ["CHudAmmo"] = true, ["CHudSecondaryAmmo"] = true, ["CHudCrosshair"] = true, ["CHudSuitPower"] = true}
local HUDMeterMiddle = Vector(25 + (165 / 2), ScrH() - 25 - (165 / 2), 0)

local DrawWRList, DrawModeList, DrawListen = false, false, true
local WRView = MODE_NORMAL

local wndHelp = nil
local wnd = {["Nominate"] = nil, ["Beat"] = nil, ["Left"] = nil, ["Top"] = nil}
local txtHelp = {"Welcome to the Prestige Gaming Bunny Hop Server!", "", "In this gamemode, your goal is to reach the end of", "the map, utilizing your bunny hop possibilities along", "with strafing to land on the platforms succesfully!", "Sometimes levels are of a high difficulty; try your best", "to conquer these levels as they will give you satisfaction", "upon completion.", "", "Have fun, and good luck!", "", "Gamemode Controls:", "F1: Show this help window", "F2: Go into spectate mode; In spectator mode:", "- Use the left/right mouse button to switch through players", "- Use the reload key to go into free roam mode", "F3: Toggle third person mode", "", "Chat Commands:", "!help or !commands: Show this window", "!rtv: Vote to change the map, if you're too impatient to have it occur normally.", "!timeleft: Shows how long the map has left", "!motd: Show pG's MOTD", "!r or !restart: Reset your position to the start", "!wr: Shows the world records for this map", "!mode or !style: Select your bhop play style", "!nominate: Select a map to be added to the list of next possible maps", "!top or !toplist: Shows the top players of our server", "!rank: Shows your rank and the coming ranks", "!points [map]: Shows how many points a map is worth. Example: !points bhop_eazy_v2", "!beat or !mapsbeat: Shows the maps you have beaten", "!left or !mapsleft: Shows the maps you still need to beat", "!noweapons or !remove or !stripweapons: Remove your weapons", "!usp or !glock or !knife: Give you the appropriate weapon", "!show or !showplayers: Show other players on your screen", "!hide or !hideplayers: Remove other players from your screen", "!showgui or !showhud: Show the HUD", "!hidegui or !hidehud: Hides the HUD", "!showspec: Shows the spectator list", "!hidespec: Hides the spectator list", "!hud or !changehud: Changes the default HUD to an advanced HUD", "!precision or !mili: Show more detailed times", "", "Bhop Styles:", "- Normal: You can use all keys and have to jump with scroll wheel", "- Sideways: You can only use W/S and have to jump with scroll wheel", "- W-Only: You can only use W and have to jump with scroll wheel", "", "Special Bhop Styles (These styles do NOT save your time and do not give points!)", "- Teleportation: With this style you can teleport to other players and", "  hold space to bunny hop. Commands: !tpto or !tele [player]", "- Auto Hop: With this style could can bunny hop normally but", "  you can hold space to make perfect jumps!", "", "Console Commands:", "- cl_showothers: Show or hide other players", "- cl_showspec: Show or hide the spectator list", "- cl_showgui: Show or hide the HUD", "- cl_hudtype: Show or hide the advanced HUD", "- cl_timeprecision: Show more detailed times"}

CVHud = CreateClientConVar("cl_showgui", "1", true, false)
CVSpec = CreateClientConVar("cl_showspec", "1", true, false)
CVPlayer = CreateClientConVar("cl_showothers", "1", true, false)
CVHudSpecial = CreateClientConVar("cl_hudtype", "0", true, false)
CVTime = CreateClientConVar("cl_timeprecision", "0", true, false)

local HUD_BLUE, HUD_LGRAY, HUD_DGRAY = Color(0, 120, 255, 255), Color(46, 46, 46, 255), Color(35, 35, 35, 255)

surface.CreateFont("HUDFont", {size = 22, weight = 800, antialias = true, shadow = false, font = "Tahoma"})
surface.CreateFont("HUDFontS", {size = 13, weight = 800, antialias = true, shadow = false, font = "Tahoma"})
surface.CreateFont("HUDFontXS", {size = 12, weight = 800, antialias = true, shadow = false, font = "Tahoma"})
surface.CreateFont("HUDFontB", {size = 44, font = "Coolvetica"})
surface.CreateFont("HUDFontH1", {size = 30, font = "Coolvetica"})
surface.CreateFont("HUDFontH2", {size = 24, font = "Coolvetica"})
surface.CreateFont("HUDFontH3", {size = 20, font = "Coolvetica"})
surface.CreateFont("HUDTextH3", {size = 17, weight = 550, font = "Verdana"})

function GM:HUDPaint()
	if not CVHud:GetBool() then return self.BaseClass:HUDPaint() end

	local w = ScrW()
	local hw = w / 2
	local h = ScrH() - 30
	local ob = LocalPlayer():GetObserverTarget()
	
	if ob and ob:IsValid() and ob:IsPlayer() then
		local text = GetSpectatorName(ob)
		
		draw.SimpleText(text[1], "HUDFontB", hw + 2, h - 68, Color(25, 25, 25, 255), TEXT_ALIGN_CENTER)
		draw.SimpleText(text[1], "HUDFontB", hw, h - 70, Color(0, 120, 255, 255), TEXT_ALIGN_CENTER)

		draw.SimpleText(text[2], "HUDFontH1", hw + 2, h - 28, Color(25, 25, 25, 255), TEXT_ALIGN_CENTER)
		draw.SimpleText(text[2], "HUDFontH1", hw, h - 30, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER)
		
		if text[3] then
			draw.SimpleText(text[3], "HUDFontH1", hw + 2, h + 2, Color(25, 25, 25, 255), TEXT_ALIGN_CENTER)
			draw.SimpleText(text[3], "HUDFontH1", hw, h, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER)
		end
	end
	
	if LocalPlayer():Team() == TEAM_SPECTATOR then
		draw.SimpleText("Press R to change spectate mode.", "HUDFontH1", hw + 2, 32, Color(25, 25, 25, 255), TEXT_ALIGN_CENTER)
		draw.SimpleText("Press R to change spectate mode.", "HUDFontH1", hw, 30, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER)
		draw.SimpleText("Cycle through players with left/right mouse", "HUDFontH3", hw, 60, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER)
	else
		if CVSpec:GetBool() and #SpectatorList > 0 then
			local start = (h + 30) / 2 - 50
			local yoffset = start + 20
			draw.SimpleText("Spectators:", "HUDFontS", w - 165, start, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
			for k,v in pairs(SpectatorList) do
				draw.SimpleText(v, "HUDFontS", w - 165, yoffset, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
				yoffset = yoffset + 15
			end
		end
	end

	return self.BaseClass:HUDPaint()
end

function GM:HUDPaintBackground()
	if not CVHud:GetBool() then return end
	
	local HUD_XSTART, HUD_YSTART = 20, ScrH() - 400
	if DrawWRList and HasRecordList then
		HUD_YSTART = HUD_YSTART - 280
		surface.SetDrawColor(HUD_DGRAY)
		surface.DrawRect(HUD_XSTART, HUD_YSTART, 235, 290)
		surface.SetDrawColor(HUD_LGRAY)
		surface.DrawRect(HUD_XSTART + 10, HUD_YSTART + 30, 215, 250)
		draw.SimpleText(MODE_NAME[WRView] .. " Records", "HUDFontH3", HUD_XSTART + 10, HUD_YSTART + 25, HUD_BLUE, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		
		if #RecordList[WRView] > 0 then
			for k,v in pairs(RecordList[WRView]) do
				draw.SimpleText("#" .. k .. " [" .. ConvertTime(tonumber(v['time'])) .. "]: " .. string.sub(v['name'], 1, 20), "HUDFontXS", HUD_XSTART + 15, HUD_YSTART + 30 + (16 * k), Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
			end
		else
			draw.SimpleText("No records!", "HUDFontXS", HUD_XSTART + 15, HUD_YSTART + 46, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		end
		
		local OtherModes = {MODE_NORMAL, MODE_SIDEWAYS, MODE_WONLY, MODE_AUTO}
		table.remove(OtherModes, WRView)
		
		for k,v in pairs(OtherModes) do
			draw.SimpleText((k + 6) .. ". View " .. MODE_NAME[v] .. " Records", "HUDFontXS", HUD_XSTART + 15, HUD_YSTART + 35 + (16 * (11 + k)), Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		end
		draw.SimpleText("0. Close Window", "HUDFontXS", HUD_XSTART + 15, HUD_YSTART + 35 + (16 * 15), Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		
		if DrawListen then
			if input.IsKeyDown(KEY_7) then
				DrawListen = false
				timer.Simple(0.2, function() WRView = OtherModes[1] DrawListen = true end)
			elseif input.IsKeyDown(KEY_8) then
				DrawListen = false
				timer.Simple(0.2, function() WRView = OtherModes[2] DrawListen = true end)
			elseif input.IsKeyDown(KEY_9) then
				DrawListen = false
				timer.Simple(0.2, function() WRView = OtherModes[3] DrawListen = true end)
			elseif input.IsKeyDown(KEY_0) then
				DrawListen = false
				timer.Simple(0.2, function() DrawWRList = false DrawListen = true end)
			end
		end
	elseif DrawModeList then
		HUD_YSTART = HUD_YSTART - 280
		surface.SetDrawColor(HUD_DGRAY)
		surface.DrawRect(HUD_XSTART, HUD_YSTART, 145, 160)
		surface.SetDrawColor(HUD_LGRAY)
		surface.DrawRect(HUD_XSTART + 10, HUD_YSTART + 30, 125, 120)
		draw.SimpleText("Select Style", "HUDFontH3", HUD_XSTART + 10, HUD_YSTART + 25, HUD_BLUE, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		
		for k,v in pairs(MODE_NAME) do
			draw.SimpleText(k .. ". " .. v, "HUDFontXS", HUD_XSTART + 15, HUD_YSTART + 30 + (16 * k), k == PlayerMode and Color(212, 68, 68, 255) or Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		end
		draw.SimpleText("0. Close Window", "HUDFontXS", HUD_XSTART + 15, HUD_YSTART + 30 + (16 * 7), k == PlayerMode and Color(212, 68, 68, 255) or Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		
		if DrawListen then
			local KeyDown = -1
			if input.IsKeyDown(KEY_1) then KeyDown = 1
			elseif input.IsKeyDown(KEY_2) then KeyDown = 2
			elseif input.IsKeyDown(KEY_3) then KeyDown = 3
			elseif input.IsKeyDown(KEY_4) then KeyDown = 4
			elseif input.IsKeyDown(KEY_5) then KeyDown = 5
			elseif input.IsKeyDown(KEY_0) then KeyDown = 0
			end
			
			if KeyDown > 0 and KeyDown < 6 and KeyDown != PlayerMode then
				DrawListen = false
				timer.Simple(0.2, function() RunConsoleCommand("bhop_setmode", tostring(KeyDown)) DrawModeList = false DrawListen = true end)
			elseif KeyDown == 0 then
				DrawListen = false
				timer.Simple(0.2, function() DrawModeList = false DrawListen = true end)
			end
		end
	end

	if LocalPlayer():Team() != TEAM_SPECTATOR then
		local TimeData = 0
		if not FinishTime and StartTime then
			TimeData = CurTime() - StartTime
		elseif FinishTime and StartTime then
			TimeData = FinishTime - StartTime
		end
	
		if CVHudSpecial:GetBool() then
			surface.SetMaterial(HUDFull)
			surface.SetDrawColor(Color(255, 255, 255, 255))
			surface.DrawTexturedRect(25, ScrH() - 25 - 165, 394, 165)

			if PLAYER_SPEED then
				local fraction = (PLAYER_SPEED > 1500) and 1 or (PLAYER_SPEED / 1500)
				surface.SetMaterial(HUDPointer)
				surface.SetDrawColor(Color(255, 255, 255, 255))
				surface.DrawTexturedRectRotated(HUDMeterMiddle.x, HUDMeterMiddle.y, 5, 140, 360 - (300 * fraction))
			end
			
			draw.SimpleText("Time:", "HUDFont", 200, ScrH() - 136, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText("Record:", "HUDFont", 200, ScrH() - 111, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			
			draw.SimpleText(ConvertTime(TimeData), "HUDFont", 290, ScrH() - 136, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText(RecordString, "HUDFont", 290, ScrH() - 111, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		
			draw.SimpleText("Remaining:", "HUDFontS", 200, ScrH() - 84, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText("Velocity:", "HUDFontS", 200, ScrH() - 69, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText("Ammunition:", "HUDFontS", 200, ScrH() - 54, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

			draw.SimpleText(ConvertTime(MapEnd - CurTime(), true), "HUDFontS", 290, ScrH() - 84, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText(PLAYER_SPEED, "HUDFontS", 290, ScrH() - 69, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText(GetAmmunition(), "HUDFontS", 290, ScrH() - 54, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

			draw.SimpleText(string.sub(MODE_NAME[PlayerMode], 0, 1), "HUDFontS", 180, ScrH() - 54, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		else
			surface.SetDrawColor(HUD_DGRAY)
			surface.DrawRect(20, ScrH() - 145, 230, 125)
			surface.SetDrawColor(HUD_LGRAY)
			surface.DrawRect(25, ScrH() - 140, 220, 55)
			surface.DrawRect(25, ScrH() - 80, 220, 55)
			
			draw.SimpleText("Time:", "HUDFont", 30, ScrH() - 125, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText("Record:", "HUDFont", 30, ScrH() - 100, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText(ConvertTime(TimeData), "HUDFont", 120, ScrH() - 125, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText(RecordString, "HUDFont", 120, ScrH() - 100, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			
			draw.SimpleText("Remaining:", "HUDFontS", 30, ScrH() - 68, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText("Velocity:", "HUDFontS", 30, ScrH() - 53, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText("Ammunition:", "HUDFontS", 30, ScrH() - 38, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

			draw.SimpleText(ConvertTime(MapEnd - CurTime(), true), "HUDFontS", 120, ScrH() - 68, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText(PLAYER_SPEED, "HUDFontS", 120, ScrH() - 53, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText(GetAmmunition(), "HUDFontS", 120, ScrH() - 38, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			
			draw.SimpleText(string.sub(MODE_NAME[PlayerMode], 0, 1), "HUDFontS", 225, ScrH() - 38, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end
	end
end

function GM:HUDShouldDraw(Name)
	return not HiddenHUDs[Name]
end

function ShowWR()
	CloseMenus()
	DrawWRList = true
end

function ShowModes()
	CloseMenus()
	DrawModeList = true
end

function ShowHelp()
	if not wndHelp then
		wndHelp = vgui.Create("DFrame")
		wndHelp:SetDeleteOnClose(false)
		wndHelp:MakePopup()
		
		wndHelp:SetSize(600, 400)
		wndHelp:SetPos(ScrW() / 2 - wndHelp:GetWide() / 2, ScrH() / 2 - wndHelp:GetTall() / 2)
		wndHelp.SetDText = "Bunny Hop"
		wndHelp:SetTitle("")
		
		local list = vgui.Create("DPanelList", wndHelp)
		list:SetSize(wndHelp:GetWide() - 6, wndHelp:GetTall() - 50)
		list:SetPos(3,45)
		list:EnableVerticalScrollbar(true)
		
		wndHelp.Paint = function()
			local w,h = wndHelp:GetWide(), wndHelp:GetTall()
			
			draw.RoundedBox(8, 0, 0, w, h, Color(2, 3, 5, 200))
			draw.RoundedBox(6, 3, 2, w - 6, 40, LocalPlayer() and team.GetColor(LocalPlayer():Team()) or Color(25, 25, 25, 150))
			draw.SimpleText(wndHelp.SetDText, "HUDFontH1", w / 2 + 2, 10, Color(25, 25, 25, 255), TEXT_ALIGN_CENTER)
			draw.SimpleText(wndHelp.SetDText, "HUDFontH1", w / 2, 8, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER)
		end
		
		for i = 1, #txtHelp do
			local text = vgui.Create("DLabel")
			text:SetFont("HUDFontH3")
			text:SetColor(Color(200, 200, 200, 255))
			text:SetText(txtHelp[i])
			text:SizeToContents()
			list:AddItem(text)
		end
	else
		wndHelp:SetVisible(true)
	end
end

function ShowNominate()
	if IsValid(wnd["Nominate"]) then return end
	CloseMenus()

	local Maps = {}
	for k,v in pairs(MapList) do
		Maps[k] = string.gsub(string.gsub(v, "bhop_", ""), "_", " ") .. " [" .. MapPointList[v] .. "]"
	end
	
	local Voted = false
	local Pressable = true
	local Count = math.ceil(#MapList / 7)
	local Current = 1
	
	wnd["Nominate"] = vgui.Create( "DFrame" )
	wnd["Nominate"]:SetTitle( "" )
	wnd["Nominate"]:SetSize( 230, 250 )
	wnd["Nominate"]:SetPos( 20, ScrH()/2 - wnd["Nominate"]:GetTall()/2 )
	wnd["Nominate"]:SetDraggable( false )
	wnd["Nominate"]:ShowCloseButton( false )
	wnd["Nominate"].Paint = function()
		local w, h = wnd["Nominate"]:GetWide(), wnd["Nominate"]:GetTall()

		surface.SetDrawColor(HUD_DGRAY)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(HUD_LGRAY)
		surface.DrawRect(10, 30, w - 20, h - 40)
		draw.SimpleText( "Nominate", "HUDFontH2", 10, 5, HUD_BLUE, TEXT_ALIGN_LEFT )
	end

	local mapLabels = {}
	local textData = { "Previous", "Next", "Quit" }
	local yOffset = 35
	for i = 1, 10 do
		mapLabels[i] = vgui.Create( "DLabel", wnd["Nominate"] )
		mapLabels[i]:SetPos( 15, yOffset )
		mapLabels[i]:SetFont("HUDTextH3")
		mapLabels[i]:SetColor(Color(255, 255, 255))
		
		if (i > 7) then
			mapLabels[i]:SetText( "(" .. string.gsub(tostring(i), "10", "0") .. ") " .. textData[i - 7] ) 
		else
			mapLabels[i]:SetText( "(" .. tostring(i) .. ") " .. Maps[i] )
		end
		mapLabels[i]:SizeToContents()
		
		yOffset = yOffset + 20
	end
	
	wnd["Nominate"].Think = function()
		local KeyDown = -1
		if input.IsKeyDown( KEY_1 ) then KeyDown = 1
		elseif input.IsKeyDown( KEY_2 ) then KeyDown = 2
		elseif input.IsKeyDown( KEY_3 ) then KeyDown = 3
		elseif input.IsKeyDown( KEY_4 ) then KeyDown = 4
		elseif input.IsKeyDown( KEY_5 ) then KeyDown = 5
		elseif input.IsKeyDown( KEY_6 ) then KeyDown = 6
		elseif input.IsKeyDown( KEY_7 ) then KeyDown = 7
		elseif input.IsKeyDown( KEY_8 ) then KeyDown = 8
		elseif input.IsKeyDown( KEY_9 ) then KeyDown = 9
		elseif input.IsKeyDown( KEY_0 ) then KeyDown = 0
		end
		
		if KeyDown > 0 and KeyDown < 8 and not Voted then
			local listVoted = MapList[(7 * Current) - 7 + KeyDown]
			if not listVoted then return end
			Voted = true
			RunConsoleCommand("rtv_nominate", listVoted)
			surface.PlaySound( "garrysmod/save_load1.wav" )
			timer.Simple( .25, function() if wnd["Nominate"] then wnd["Nominate"]:Close() end end )
		end
	
		if KeyDown == 8 and Pressable and not Voted and Current != 1 then
			Pressable = false
			timer.Simple(0.25, function() Pressable = true end)

			Current = Current - 1
			local index = (7 * Current) - 7
			
			for i = 1, 7 do
				mapLabels[i]:SetText("(" .. tostring(i) .. ") " .. Maps[index + i])
				mapLabels[i]:SetVisible(true)
				mapLabels[i]:SizeToContents()
			end

			if(Current == 1) then
				mapLabels[8]:SetVisible(false)
				mapLabels[9]:SetVisible(true)
			else
				mapLabels[8]:SetVisible(true)
				mapLabels[9]:SetVisible(true)
			end
		elseif KeyDown == 9 and Pressable and not Voted and Current != Count then
			Pressable = false
			timer.Simple(0.25,function() Pressable = true end)
		
			Current = Current + 1
			local index = (7 * Current) - 7
			
			for i = 1, 7 do
				if (Maps[index + i]) then
					mapLabels[i]:SetText("(" .. tostring(i) .. ") " .. Maps[index + i])
					mapLabels[i]:SetVisible(true)
					mapLabels[i]:SizeToContents()
				else
					mapLabels[i]:SetVisible(false)
				end
			end

			if Current == Count then
				mapLabels[8]:SetVisible(true)
				mapLabels[9]:SetVisible(false)
			else
				mapLabels[8]:SetVisible(true)
				mapLabels[9]:SetVisible(true)
			end
		elseif KeyDown == 0 and Pressable and not Voted then
			timer.Simple(.25, function()
				if(wnd["Nominate"]) then
					wnd["Nominate"]:Close()
					wnd["Nominate"] = nil
				end
			end)
		end
	end
end

function ShowBeat()
	if IsValid(wnd["Beat"]) then return end
	CloseMenus()

	local Current = 1
	local Maps = {}
	local Count = math.ceil(#MapsBeatList / 7)

	for k,v in pairs(MapsBeatList) do
		Maps[k] = {string.gsub(string.gsub(v['map_name'], "bhop_", ""), "_", " "), tonumber(v['time'])}
	end

	wnd["Beat"] = vgui.Create( "DFrame" )
	wnd["Beat"]:SetTitle( "" )
	wnd["Beat"]:SetSize( 230, 250 )
	wnd["Beat"]:SetPos( 20, ScrH()/2 - wnd["Beat"]:GetTall()/2 )
	wnd["Beat"]:SetDraggable( false )
	wnd["Beat"]:ShowCloseButton( false )
	wnd["Beat"].Paint = function()

		local w, h = wnd["Beat"]:GetWide(), wnd["Beat"]:GetTall()

		surface.SetDrawColor(HUD_DGRAY)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(HUD_LGRAY)
		surface.DrawRect(10, 30, w - 20, h - 40)
		draw.SimpleText( "Beaten Maps (" .. #MapsBeatList .. ")", "HUDFontH2", 10, 5, HUD_BLUE, TEXT_ALIGN_LEFT )
     
	end
	
	local mapLabels = {}
	local textData = { "Previous", "Next", "Quit" } -- pr / nx / q
	local yOffset = 35
	local Allowed = true
	
	for i = 1, 10 do
		mapLabels[i] = vgui.Create( "DLabel", wnd["Beat"] )
		mapLabels[i]:SetPos( 15, yOffset )
		mapLabels[i]:SetFont("HUDTextH3")
		mapLabels[i]:SetColor( Color(255, 255, 255) )
		
		if #Maps == 0 then
			mapLabels[i]:SetText( "" )
		else
			if (i > 7) then
				mapLabels[i]:SetText( "(" .. string.gsub(tostring(i), "10", "0") .. ") " .. textData[i - 7] ) 
			else
				if Maps[i] then
					mapLabels[i]:SetText( "(" .. ConvertTime(Maps[i][2]) .. ") " .. Maps[i][1] )
				else
					mapLabels[i]:SetText( "" )
				end
			end
		end
		mapLabels[i]:SizeToContents()
		
		yOffset = yOffset + 20
	end
	mapLabels[8]:SetVisible(false)
	if #Maps < 8 then mapLabels[9]:SetVisible(false) end
	
	wnd["Beat"].Think = function()
	
		local KeyDown = -1
		if input.IsKeyDown( KEY_8 ) then KeyDown = 8
		elseif input.IsKeyDown( KEY_9 ) then KeyDown = 9
		elseif input.IsKeyDown( KEY_0 ) then KeyDown = 0
		end

		if KeyDown == 8 and Allowed and Current != 1 then
			Allowed = false
			timer.Simple(0.25,function() Allowed = true end)

			Current = Current - 1
			local index = (7 * Current) - 7
			
			for i = 1, 7 do
				if #Maps == 0 then
					mapLabels[i]:SetText( "" )
				else
					mapLabels[i]:SetText( "(" .. ConvertTime(Maps[index + i][2]) .. ") " .. Maps[index + i][1] )
				end
				mapLabels[i]:SetVisible(true)
				mapLabels[i]:SizeToContents()
			end

			if Current == 1 then
				mapLabels[8]:SetVisible(false)
				mapLabels[9]:SetVisible(true)
			else
				mapLabels[8]:SetVisible(true)
				mapLabels[9]:SetVisible(true)
			end
		elseif KeyDown == 9 and Allowed and Current != Count then
			Allowed = false
			timer.Simple(0.25,function() Allowed = true end)
		
			Current = Current + 1
			local index = (7 * Current) - 7
			
			for i = 1, 7 do
				if (Maps[index + i]) then
					mapLabels[i]:SetText( "(" .. ConvertTime(Maps[index + i][2]) .. ") " .. Maps[index + i][1] )
					mapLabels[i]:SetVisible(true)
					mapLabels[i]:SizeToContents()
				else
					mapLabels[i]:SetVisible(false)
				end
			end

			if Current == Count then
				mapLabels[8]:SetVisible(true)
				mapLabels[9]:SetVisible(false)
			else
				mapLabels[8]:SetVisible(true)
				mapLabels[9]:SetVisible(true)
			end
		elseif KeyDown == 0 and Allowed then
			timer.Simple(.25, function()
				if wnd["Beat"] then
					wnd["Beat"]:Close()
					wnd["Beat"] = nil
				end
			end)
		end

	end
end

function ShowLeft()
	if IsValid(wnd["Left"]) then return end
	CloseMenus()

	local Current = 1
	local MapCopy = {}
	local Maps = {}
	local at = 1
	
	for k,v in pairs(MapPointList) do
		MapCopy[k] = v
	end
	for k,v in pairs(MapsBeatList) do
		MapCopy[v['map_name']] = nil
	end
	for k,v in pairs(MapCopy) do
		table.insert(Maps, {string.gsub(string.gsub(k, "bhop_", ""), "_", " "), v, k})
	end
	table.sort(Maps, function(a, b)
		return a[2] < b[2]
	end)
	
	local Count = math.ceil(#Maps / 7)

	wnd["Left"] = vgui.Create( "DFrame" )
	wnd["Left"]:SetTitle( "" )
	wnd["Left"]:SetSize( 210, 250 )
	wnd["Left"]:SetPos( 20, ScrH()/2 - wnd["Left"]:GetTall()/2 )
	wnd["Left"]:SetDraggable( false )
	wnd["Left"]:ShowCloseButton( false )
	wnd["Left"].Paint = function()

		local w, h = wnd["Left"]:GetWide(), wnd["Left"]:GetTall()

		surface.SetDrawColor(HUD_DGRAY)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(HUD_LGRAY)
		surface.DrawRect(10, 30, w - 20, h - 40)
		draw.SimpleText( "Maps Left (" .. #Maps .. ")", "HUDFontH2", 10, 5, HUD_BLUE, TEXT_ALIGN_LEFT )
	 
	end
	
	local mapLabels = {}
	local textData = { "Previous", "Next", "Quit" } -- pr / nx / q
	local yOffset = 35
	local Allowed = true
	
	for i = 1, 10 do
		mapLabels[i] = vgui.Create( "DLabel", wnd["Left"] )
		mapLabels[i]:SetPos( 15, yOffset )
		mapLabels[i]:SetFont("HUDTextH3")
		mapLabels[i]:SetColor( Color(255, 255, 255) )
		
		if #Maps == 0 then
			mapLabels[i]:SetText( "" )
		else
			if (i > 7) then
				mapLabels[i]:SetText( "(" .. string.gsub(tostring(i), "10", "0") .. ") " .. textData[i - 7] ) 
			else
				if Maps[i] then
					mapLabels[i]:SetText( "[" .. Maps[i][2] .. "] " .. Maps[i][1] )
				else
					mapLabels[i]:SetText( "" )
				end
			end
		end
		mapLabels[i]:SizeToContents()
		
		yOffset = yOffset + 20
	end
	mapLabels[8]:SetVisible(false)
	if #Maps < 8 then mapLabels[9]:SetVisible(false) end
	
	wnd["Left"].Think = function()
	
		local KeyDown = -1
		if input.IsKeyDown( KEY_1 ) then KeyDown = 1
		elseif input.IsKeyDown( KEY_2 ) then KeyDown = 2
		elseif input.IsKeyDown( KEY_3 ) then KeyDown = 3
		elseif input.IsKeyDown( KEY_4 ) then KeyDown = 4
		elseif input.IsKeyDown( KEY_5 ) then KeyDown = 5
		elseif input.IsKeyDown( KEY_6 ) then KeyDown = 6
		elseif input.IsKeyDown( KEY_7 ) then KeyDown = 7
		elseif input.IsKeyDown( KEY_8 ) then KeyDown = 8
		elseif input.IsKeyDown( KEY_9 ) then KeyDown = 9
		elseif input.IsKeyDown( KEY_0 ) then KeyDown = 0
		end

		if KeyDown > 0 and KeyDown < 8 and Allowed then
			local listVoted = Maps[(7 * Current) - 7 + KeyDown]
			if listVoted then
				Allowed = false
				RunConsoleCommand( "rtv_nominate", listVoted[3])
				surface.PlaySound( "garrysmod/save_load1.wav" )
				timer.Simple(.25, function()
					Allowed = true
					if wnd["Left"] then
						wnd["Left"]:Close()
						wnd["Left"] = nil
					end
				end)
			end
		elseif KeyDown == 8 and Allowed and Current != 1 then
			Allowed = false
			timer.Simple(0.25,function() Allowed = true end)

			Current = Current - 1
			local index = (7 * Current) - 7
			
			for i = 1, 7 do
				if #Maps == 0 then
					mapLabels[i]:SetText( "" )
				else
					mapLabels[i]:SetText( "[" .. Maps[index + i][2] .. "] " .. Maps[index + i][1] )
				end
				mapLabels[i]:SetVisible(true)
				mapLabels[i]:SizeToContents()
			end

			if Current == 1 then
				mapLabels[8]:SetVisible(false)
				mapLabels[9]:SetVisible(true)
			else
				mapLabels[8]:SetVisible(true)
				mapLabels[9]:SetVisible(true)
			end
		elseif KeyDown == 9 and Allowed and Current != Count then
			Allowed = false
			timer.Simple(0.25,function() Allowed = true end)
		
			Current = Current + 1
			local index = (7 * Current) - 7
			
			for i = 1, 7 do
				if (Maps[index + i]) then
					mapLabels[i]:SetText( "[" .. Maps[index + i][2] .. "] " .. Maps[index + i][1] )
					mapLabels[i]:SetVisible(true)
					mapLabels[i]:SizeToContents()
				else
					mapLabels[i]:SetVisible(false)
				end
			end

			if Current == Count then
				mapLabels[8]:SetVisible(true)
				mapLabels[9]:SetVisible(false)
			else
				mapLabels[8]:SetVisible(true)
				mapLabels[9]:SetVisible(true)
			end
		elseif KeyDown == 0 and Allowed then
			timer.Simple(.25, function()
				if wnd["Left"] then
					wnd["Left"]:Close()
					wnd["Left"] = nil
				end
			end)
		end

	end
end

function ShowTop()
	if #TopList < 1 or IsValid(wnd["Top"]) then return end
	CloseMenus()

	wnd["Top"] = vgui.Create("DFrame")
	wnd["Top"]:SetTitle("")
	wnd["Top"]:SetSize(250, 265)
	wnd["Top"]:SetPos(20, ScrH() / 2 - wnd["Top"]:GetTall() / 2)
	wnd["Top"]:SetDraggable(false)
	wnd["Top"]:ShowCloseButton(false)
	wnd["Top"].Paint = function()
		local w, h = wnd["Top"]:GetWide(), wnd["Top"]:GetTall()

		surface.SetDrawColor(HUD_DGRAY)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(HUD_LGRAY)
		surface.DrawRect(10, 30, w - 20, h - 40)
		draw.SimpleText( "Top 10 Players", "HUDFontH2", 10, 5, HUD_BLUE, TEXT_ALIGN_LEFT )
	end
	
	local mapLabels = {}
	local yOffset = 32
	for i = 1, 11 do
		mapLabels[i] = vgui.Create("DLabel", wnd["Top"])
		mapLabels[i]:SetPos(15, yOffset)
		mapLabels[i]:SetFont("HUDTextH3")
		mapLabels[i]:SetColor(Color(255, 255, 255))
		
		if i > 10 then
			mapLabels[i]:SetText("(0) Quit") 
		elseif i > 1 then
			mapLabels[i]:SetText(i .. ": [" .. tostring(TopList[i]["rec_points"]) .. "] " .. TopList[i]["rec_name"])
		elseif i == 1 then
			mapLabels[i]:SetText(i .. ": [" .. tostring(TopList[i]["rec_points"]) .. "] " .. TopList[i]["rec_name"])
			mapLabels[i]:SetColor(Color(255, 0, 64))
		end
		mapLabels[i]:SizeToContents()
		
		if GetTextWidth(mapLabels[i]:GetText(), "HUDTextH3") > wnd["Top"]:GetWide() - 10 then
			mapLabels[i]:SetText(i .. ": [" .. tostring(TopList[i]["rec_points"]) .. "] " .. string.sub(TopList[i]["rec_name"], 1, 20))
			mapLabels[i]:SizeToContents()
		end
		
		yOffset = yOffset + 20
	end
	
	wnd["Top"].Think = function()
		if input.IsKeyDown(KEY_0) then
			timer.Simple(0.25, function()
				if wnd["Top"] then
					wnd["Top"]:Close()
					wnd["Top"] = nil
				end
			end)
		end
	end
end

function ShowVote()
	CloseMenus()
	MapEnd = CurTime() + 30
	
	local Possible = false
	local Voted = false
	local VotedInt = -1
	
	local rtv = vgui.Create( "DFrame" )
	rtv:SetTitle( "" )
	rtv:SetSize( 200, 150 )
	rtv:SetPos( 20, ScrH()/2 - rtv:GetTall()/2 )
	rtv:SetDraggable( false )
	rtv:ShowCloseButton( false )
	rtv.Paint = function()
		local w, h = rtv:GetWide(), rtv:GetTall()
		
		surface.SetDrawColor(HUD_DGRAY)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(HUD_LGRAY)
		surface.DrawRect(10, 30, w - 20, h - 40)
		draw.SimpleText( "Vote for a map!", "HUDFontH2", 10, 5, HUD_BLUE, TEXT_ALIGN_LEFT )
	end

	timer.Simple(30, function()
		if rtv then
			rtv:Close()
		end
	end)
	
	local PointList = {0, 0, 0, 0, 0}
	for i = 1, 5 do
		PointList[i] = MapPointList[RTVList[i]]
		RTVList[i] = string.gsub(string.gsub(RTVList[i], "bhop_", ""), "_", " ")
	end

	local mapLabels = {}
	local yOffset = 35
	
	for i = 1, 5 do
		mapLabels[i] = vgui.Create( "DLabel", rtv )
		mapLabels[i]:SetPos( 15, yOffset )
		mapLabels[i]:SetFont("HUDTextH3")
		mapLabels[i]:SetColor( GetMapColor(PointList[i]) )
		mapLabels[i]:SetText( tostring(i) .. " [" .. RTVVotes[i] .. "] " .. RTVList[i] )
		mapLabels[i]:SizeToContents()
		
		yOffset = yOffset + 20
	end

	rtv.Think = function()
		for i = 1, 5 do
			mapLabels[i]:SetText( tostring(i) .. " [" .. RTVVotes[i] .. "] " .. RTVList[i] )
		end
		
		local KeyDown = -1
		if input.IsKeyDown( KEY_1 ) then KeyDown = 1
		elseif input.IsKeyDown( KEY_2 ) then KeyDown = 2
		elseif input.IsKeyDown( KEY_3 ) then KeyDown = 3
		elseif input.IsKeyDown( KEY_4 ) then KeyDown = 4
		elseif input.IsKeyDown( KEY_5 ) then KeyDown = 5
		end
		
		if KeyDown > 0 and KeyDown < 6 and not Voted then
			Voted = true
			VotedInt = KeyDown
			RunConsoleCommand( "rtv_vote", tostring(KeyDown) )
			surface.PlaySound( "garrysmod/save_load1.wav" )
			mapLabels[KeyDown]:SetColor( GetMapColor(PointList[KeyDown], true) )
			timer.Simple(3, function() Possible = true end )
		elseif KeyDown > 0 and KeyDown < 6 and Voted and KeyDown != VotedInt and VotedInt >= 0 and Possible then
			mapLabels[VotedInt]:SetColor( GetMapColor(PointList[VotedInt]) )
			mapLabels[KeyDown]:SetColor( GetMapColor(PointList[KeyDown], true) )
			RunConsoleCommand( "rtv_vote", tostring(VotedInt), tostring(KeyDown) )
			VotedInt = KeyDown
			Possible = false
			surface.PlaySound( "garrysmod/save_load1.wav" )
			timer.Simple( 3, function() Possible = true end )
		end
	end
end

function CloseMenus()
	for k,v in pairs(wnd) do
		if IsValid(v) then v:Close() end
	end
	DrawWRList, DrawModeList = false, false
end

------------------
-- ADMIN PANEL --
------------------

function ShowAdmin()
	local admin = vgui.Create( "DFrame" )
	admin:SetTitle( "" )
	admin:SetSize( 200, 180 )
	admin:SetPos( 20, ScrH()/2 - admin:GetTall()/2 )
	admin:SetDraggable( false )
	admin:ShowCloseButton( false )
	admin.Paint = function()
		local w, h = admin:GetWide(), admin:GetTall()
		
		surface.SetDrawColor(HUD_DGRAY)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(HUD_LGRAY)
		surface.DrawRect(10, 30, w - 20, h - 40)
		draw.SimpleText( "Admin Control Panel", "HUDFontH2", 10, 5, HUD_BLUE, TEXT_ALIGN_LEFT )
	end

	local structMenu = {
		[1] = {["Label"] = "Map", ["Expandable"] = true, ["Sub"] = 
			{
				["Level"] = 1,
				[1] = {["Label"] = "Reload map data", ["CallbackID"] = 100},
				[2] = {["Label"] = "Area editor", ["Expandable"] = true, ["Sub"] =
					{
						["Level"] = 2, ["Parent"] = 1,
						[1] = {["Label"] = "Add new area", ["CallbackID"] = 200},
						[2] = {["Label"] = "Remove area", ["CallbackID"] = 201},
						[3] = {["Label"] = "Edit area", ["CallbackID"] = 202}
					}
				},
				[3] = {["Label"] = "Manage times", ["CallbackID"] = 300},
				[4] = {["Label"] = "Change map", ["CallbackID"] = 400},
				[5] = {["Label"] = "Specials editor", ["Expandable"] = true, ["Sub"] =
					{
						["Level"] = 2, ["Parent"] = 1,
						[1] = {["Label"] = "Add new special", ["CallbackID"] = 203},
						[2] = {["Label"] = "Remove special", ["CallbackID"] = 204},
						[3] = {["Label"] = "Edit special", ["CallbackID"] = 205},
						[4] = {["Label"] = "Set map points", ["CallbackID"] = 206}
					}
				}
			}
		},
		[2] = {["Label"] = "Players", ["Expandable"] = true, ["Sub"] =
			{
				["Level"] = 1,
				[1] = {["Label"] = "Manage times", ["Expandable"] = true, ["Sub"] =
					{
						["Level"] = 2, ["Parent"] = 2, 
						[1] = {["Label"] = "Add time", ["CallbackID"] = 500},
						[2] = {["Label"] = "Remove time", ["CallbackID"] = 501},
						[3] = {["Label"] = "Edit time", ["CallbackID"] = 502}
					}
				},
				[2] = {["Label"] = "Teleport", ["CallbackID"] = 600},
				[3] = {["Label"] = "Unstuck", ["CallbackID"] = 700},
			}
		},
		[3] = {["Label"] = "WR Bot", ["Expandable"] = true, ["Sub"] = 
			{
				["Level"] = 1,
				[1] = {["Label"] = "Enable", ["CallbackID"] = 800},
				[2] = {["Label"] = "Disable", ["CallbackID"] = 801},
				[3] = {["Label"] = "Override record", ["CallbackID"] = 802},
				[4] = {["Label"] = "Toggle auto record", ["CallbackID"] = 803}
			}
		}
	}
	
	local mapLabels = {}
	local subMenu = nil
	local yOffset = 35
	
	local Exit = vgui.Create("DLabel", admin)
	Exit:SetPos(15, admin:GetTall() - 30)
	Exit:SetFont("HUDTextH3")
	Exit:SetColor(Color(255, 255, 255))
	Exit:SetText("0. Exit or Return")
	Exit:SizeToContents()
	
	for k,v in pairs(structMenu) do
		mapLabels[k] = vgui.Create("DLabel", admin)
		mapLabels[k]:SetPos(15, yOffset)
		mapLabels[k]:SetFont("HUDTextH3")
		mapLabels[k]:SetColor(Color(255, 255, 255))
		mapLabels[k]:SetText(k .. ". " .. v["Label"])
		mapLabels[k]:SizeToContents()
		
		if v["Expandable"] then
			local yOffset2 = 35
			
			for k2,v2 in pairs(v["Sub"]) do
				if not tonumber(k2) then continue end
				
				local subID1 = k * 10 + k2
				mapLabels[subID1] = vgui.Create("DLabel", admin) -- Continue here
				mapLabels[subID1]:SetPos(15, yOffset2)
				mapLabels[subID1]:SetFont("HUDTextH3")
				mapLabels[subID1]:SetColor(Color(255, 255, 255))
				mapLabels[subID1]:SetText(k2 .. ". " .. v2["Label"])
				mapLabels[subID1]:SizeToContents()
				mapLabels[subID1]:SetVisible(false)
				
				if v2["Expandable"] then
					local yOffset3 = 35
					
					for k3, v3 in pairs(v2["Sub"]) do
						if not tonumber(k3) then continue end
					
						local subID2 = subID1 * 10 + k3
						mapLabels[subID2] = vgui.Create("DLabel", admin)
						mapLabels[subID2]:SetPos(15, yOffset3)
						mapLabels[subID2]:SetFont("HUDTextH3")
						mapLabels[subID2]:SetColor(Color(255, 255, 255))
						mapLabels[subID2]:SetText(k3 .. ". " .. v3["Label"])
						mapLabels[subID2]:SizeToContents()
						mapLabels[subID2]:SetVisible(false)
						
						v3["ID"] = subID2
						yOffset3 = yOffset3 + 20
					end
				end
				
				v2["ID"] = subID1
				yOffset2 = yOffset2 + 20
			end
		end
		
		v["ID"] = k
		yOffset = yOffset + 20
	end

	local Pressable = true
	
	admin.Think = function()
	
		local KeyDown = -1
		if input.IsKeyDown( KEY_0 ) then KeyDown = 0
		elseif input.IsKeyDown( KEY_1 ) then KeyDown = 1
		elseif input.IsKeyDown( KEY_2 ) then KeyDown = 2
		elseif input.IsKeyDown( KEY_3 ) then KeyDown = 3
		elseif input.IsKeyDown( KEY_4 ) then KeyDown = 4
		elseif input.IsKeyDown( KEY_5 ) then KeyDown = 5
		end
		
		if KeyDown < 0 then return end
		if KeyDown == 0 and Pressable then
			Pressable = false
			timer.Simple(.25, function() Pressable = true end)
		
			if not subMenu then
				timer.Simple(.25, function()
					if admin then
						admin:Close()
						admin = nil
					end
				end)
			else
				if subMenu["Level"] == 1 then
					for k,v in pairs(mapLabels) do
						v:SetVisible(false)
					end
					
					subMenu = nil
					for k,v in pairs(structMenu) do
						if k == "Level" or k == "Parent" or not v["ID"] then continue end
						mapLabels[v["ID"]]:SetVisible(true)
					end
				elseif subMenu["Level"] == 2 then
					for k,v in pairs(mapLabels) do
						v:SetVisible(false)
					end
					
					subMenu = structMenu[subMenu["Parent"]]["Sub"]
					for k,v in pairs(subMenu) do
						if k == "Level" or k == "Parent" or not v["ID"] then continue end
						mapLabels[v["ID"]]:SetVisible(true)
					end
				end
			end
		elseif Pressable then
			Pressable = false
			timer.Simple(.25, function() Pressable = true end)
			
			if subMenu then
				if subMenu[KeyDown] then
					if subMenu[KeyDown]["Expandable"] then
						for k,v in pairs(mapLabels) do
							v:SetVisible(false)
						end
						
						subMenu = subMenu[KeyDown]["Sub"]
						for k,v in pairs(subMenu) do
							if k == "Level" or k == "Parent" or not v["ID"] then continue end
							mapLabels[v["ID"]]:SetVisible(true)
						end
					else
						AdminCallback(admin, subMenu[KeyDown]["CallbackID"])
					end
				end
			else
				if structMenu[KeyDown] and structMenu[KeyDown]["Expandable"] then
					for k,v in pairs(mapLabels) do
						v:SetVisible(false)
					end
				
					subMenu = structMenu[KeyDown]["Sub"]
					for k,v in pairs(subMenu) do
						if k == "Level" or k == "Parent" or not v["ID"] then continue end
						mapLabels[v["ID"]]:SetVisible(true)
					end
				end
			end
		end

	end
end

local AE_Data = {["Presses"] = 0, ["Pos1"] = nil, ["Pos2"] = nil}

function AdminCallback(admin, id)
	id = tonumber(id)
	if not id then return end
	
	if admin then
		admin:Close()
		admin = nil
	end

	local data = true
	if id == 200 then -- [MAP] Area editor: Add new
		if AE_Data["Presses"] < 2 then
			AE_Data["Presses"] = AE_Data["Presses"] + 1
			AE_Data["Pos" .. AE_Data["Presses"]] = GetVectorString(LocalPlayer():GetPos())
			AddText(TEXT_TIMER, "Position " .. AE_Data["Presses"] .. " has been saved: " .. AE_Data["Pos" .. AE_Data["Presses"]])
		elseif AE_Data["Presses"] == 2 then
			PromptStringRequest("[Map] Area editor", "Enter Area Type:", "1/2 (Start/Finish)", function(str)
				if not tonumber(str) then return end
				RunConsoleCommand("acp_runcmd", tostring(id), str, AE_Data["Pos1"], AE_Data["Pos2"])
				AE_Data["Presses"] = 0
				AE_Data["Pos1"] = nil
				AE_Data["Pos2"] = nil
			end)
		end
		
		return
	elseif id == 400 then -- [MAP] Change map
		PromptStringRequest("[Map] Map Name", "Enter Map Name:", "", function(str1)
			RunConsoleCommand("acp_runcmd", tostring(id), str1)
		end)
	elseif id == 600 then -- [PLY] Teleport
		PromptStringRequest("[Teleport] Player Name", "Enter Player (From):", "", function(str1)
		PromptStringRequest("[Teleport] Player Name", "Enter Player (To):", "", function(str2)
			RunConsoleCommand("acp_runcmd", tostring(id), str1, str2)
		end)
		end)
	elseif id == 700 then -- [PLY] Unstuck
		PromptStringRequest("[Unstuck] Player Name", "Enter Player Name:", "", function(str)
			RunConsoleCommand("acp_runcmd", tostring(id), str)
		end)
	elseif id == 802 then -- [BOT] Override recording
		PromptStringRequest("[Bot Override] Player Name", "Enter Player:", "", function(str1)
		PromptStringRequest("[Bot Override] Minimum WR", "Minimum required WR (10 for always):", "", function(num1)
			if not tonumber(num1) then return end
			RunConsoleCommand("acp_runcmd", tostring(id), str1, num1)
		end)
		end)
	else
		data = false
	end
	
	if not data then
		RunConsoleCommand("acp_runcmd", tostring(id))
	end
end

--------------------------------
-- CLIENTSIDE CALCULATIONS --
--------------------------------

function GetVectorString(vec)
	return vec.x .. "," .. vec.z .. "," .. vec.y
end

floor = math.floor
function ConvertTime(time, shorten, detailed)
	local detailed = false
	if time < 0 then time = 0 end
	if not shorten then 
		detailed = detailed or CVTime:GetBool()
	end
	
	if time > 3600 then
		if shorten then
			return string.format("%.2d:%.2d:%.2d", floor(time / 3600), floor(time / 60 % 60), floor(time % 60))
		end
		
		return string.format("%.2d:%.2d:%.2d:%.2d", floor(time / 3600), floor(time / 60 % 60), floor(time % 60), floor(time * 60 % 60))
	else
		if shorten then
			return string.format("%.2d:%.2d", floor(time / 60 % 60), floor(time % 60))
		end
		
		if detailed then
			return string.format("%.2d:%.2d:%.2d:%.2d", floor(time / 60 % 60), floor(time % 60), floor(time * 60 % 60), floor(time * 60 * 60 % 60))
		else
			return string.format("%.2d:%.2d:%.2d", floor(time / 60 % 60), floor(time % 60), floor(time * 60 % 60))
		end
	end
end

function GetAmmunition()
	local data = "0 / 0"
	if LocalPlayer() then
		local Weapon = LocalPlayer():GetActiveWeapon()
		if not Weapon or not Weapon.Clip1 then return data end
		data = Weapon:Clip1() .. " / " .. LocalPlayer():GetAmmoCount(Weapon:GetPrimaryAmmoType())
	end
	return data
end

function GetMapColor(points, bright)
	local outcome = Color(255, 255, 255)
	
	if not points or points < 0 then points = 0 end
	if points > 0 and points < 20 then outcome = COLOR_DIFFICULTY[1]
	elseif points > 15 and points < 40 then outcome = COLOR_DIFFICULTY[2]
	elseif points > 35 and points < 100 then outcome = COLOR_DIFFICULTY[3]
	elseif points > 80 and points < 200 then outcome = COLOR_DIFFICULTY[4]
	elseif points > 175 then outcome = COLOR_DIFFICULTY[5] end
	
	if bright then
		return Color(outcome.r == 255 and 255 or 0, outcome.g == 255 and 255 or 0, outcome.b == 255 and 255 or 0)
	else
		return outcome
	end
end

function GetSpectatorName(ob)
	local text = {"Spectating", ob:Nick(), nil}
	
	if ob:IsBot() then
		text[1] = "Spectating WR Bot"
		if SpectatorData["Contains"] and SpectatorData["IsBot"] then
			text[2] = SpectatorData["BotPlayer"] .. " (" .. MODE_NAME[ob:GetNWInt("BhopType", 1)] .. ")"
			
			if SpectatorData["StartTime"] then
				text[3] = ConvertTime(CurTime() - SpectatorData["StartTime"])
				if SpectatorData["BestTime"] then
					text[3] = text[3] .. " / " .. SpectatorData["BestTime"]
				end
			end
		end
	else
		text[2] = text[2] .. " (" .. MODE_NAME[ob:GetNWInt("BhopType", 1)] .. ")"
	
		if SpectatorData["StartTime"] then
			text[3] = ConvertTime(CurTime() - SpectatorData["StartTime"])
			if SpectatorData["BestTime"] then
				text[3] = "Best: " .. SpectatorData["BestTime"] .. " - Time: " .. text[3]
			else
				text[3] = "Time: " .. text[3]
			end
		end
	end
	
	return text
end

function GetTextWidth(text, font)
	surface.SetFont(font)
	return surface.GetTextSize(text)
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