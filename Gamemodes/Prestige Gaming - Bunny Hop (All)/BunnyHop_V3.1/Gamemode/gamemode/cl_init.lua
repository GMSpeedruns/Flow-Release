include("shared.lua")
include("cl_window.lua")
include("cl_data.lua")
include("cl_scoreboard.lua")
include("cl_admin.lua")

AFKChecks = 0
ThirdPerson = 0
PlayerMode = MODE_AUTO

CVHud = CreateClientConVar("cl_showgui", "1", true, false)
CVSpec = CreateClientConVar("cl_showspec", "1", true, false)
CVPlayer = CreateClientConVar("cl_showothers", "1", true, false)

function InitializeClient()
	for k,v in pairs(GAMEMODE.RankList) do
		GAMEMODE.RankList[k][3] = math.floor(2.25 * math.pow(k, 2.538))
	end
	GAMEMODE.RankList[36][3] = 20030

	timer.Create("SetHullAndView", 5, 0, SetHullAndViewOffset)
end
hook.Add( "Initialize", "CInitialize", InitializeClient )

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
	
	if PLAYER_SPEED < 1 && LocalPlayer() && LocalPlayer():IsValid() && LocalPlayer():Team() != TEAM_SPECTATOR then
		AFKChecks = AFKChecks + 1
		if AFKChecks >= (StartTime and PLAYER_AFK_LIMIT * 3 or PLAYER_AFK_LIMIT) then
			RunConsoleCommand("bhop_afk")
			AFKChecks = 0
		end
	else
		AFKChecks = 0
	end
end

function GM:CalcView(ply, pos, angles, fov)
	if ThirdPerson == 1 then
		pos = pos - (angles:Forward() * 100) + (angles:Up() * 40)
		local ang = (ply:GetPos() + (angles:Up() * 30 )) - pos
		ang:Normalize()
		angles = ang:Angle()
	end
	
    return self.BaseClass:CalcView(ply, pos, angles, fov)
end

function GM:ShouldDrawLocalPlayer(ply)
	return ThirdPerson == 1 and true or self.BaseClass:ShouldDrawLocalPlayer(ply)
end

--------------------
-- PLAYER TIMING --
--------------------

StartTime = nil
FinishTime = nil
RecordString = "00:00:00"
TotalTime = 7200

function StartTimer(time, correction)
	StartTime = time
	FinishTime = nil
	if correction then StartTime = StartTime - correction end
	SyncTime(time)
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

function ShowWeight(weight, total)
	AddText(TEXT_BHOP, "For completing the map you have obtained " .. string.format("%.2f", weight) .. (total > 0 and " out of " .. total or "") .. " possible rank points!")
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

function SetGun(id, name)
	if name then
		local len = name == "usp" and 3 or 1
		name = "a " .. string.upper(string.sub(name, 1, len)) .. string.sub(name, len + 1)
	end
	
	if id == 0 then
		AddText(TEXT_BHOP, "You have received " .. name)
	elseif id == 1 then
		AddText(TEXT_BHOP, "You already have " .. name)
	elseif id == 2 then
		AddText(TEXT_BHOP, "You have been stripped of your weapons.")
	elseif id == 3 then
		AddText(TEXT_BHOP, "You can't get any new guns because your weapons have been stripped permanently!")
	end
end

function ShowPoints(points, map)
	if points >= 0 then
		AddText(TEXT_BHOP, "The map " .. map .. " is worth " .. points .. " points.")
	else
		AddText(TEXT_BHOP, "The map " .. map .. " does not exist on our server and is not worth any points.")
	end
end

function SetCV(id, value)
	if not tonumber(id) then return end
	
	if id == 1 then
		if not value or not tonumber(value) then value = CVHud:GetBool() and 0 or 1 end
		RunConsoleCommand("cl_showgui", tostring(value))
	elseif id == 2 then
		if not value or not tonumber(value) then value = CVSpec:GetBool() and 0 or 1 end
		RunConsoleCommand("cl_showspec", tostring(value))
	elseif id == 3 then
		if not value or not tonumber(value) then value = CVPlayer:GetBool() and 0 or 1 end
		if not CVPlayer:GetBool() and value == 0 then RunConsoleCommand("cl_showothers", "1") end
		RunConsoleCommand("cl_showothers", tostring(value))
	end
end

--------------------------
-- DRAWING FUNCTIONS --
--------------------------

local HiddenHUDs = {["CHudHealth"] = true, ["CHudBattery"] = true, ["CHudAmmo"] = true, ["CHudSecondaryAmmo"] = true, ["CHudCrosshair"] = true, ["CHudSuitPower"] = true}
function GM:HUDShouldDraw(Name)
	return not HiddenHUDs[Name]
end

function GM:HUDPaint()
	if not CVHud:GetBool() then return self.BaseClass:HUDPaint() end

	local w = ScrW()
	local hw = w / 2
	local h = ScrH() - 30
	local ob = LocalPlayer():GetObserverTarget()
	local DrawList = Spectator.List
	local ListName = "Spectators:"
	
	if ob and ob:IsValid() and ob:IsPlayer() then
		ListName = "Watching " .. ob:Name() .. ":"
	
		surface.SetDrawColor(HUD_DGRAY)
		surface.DrawRect(20, ScrH() - 145, 230, 125)
		surface.SetDrawColor(HUD_LGRAY)
		surface.DrawRect(25, ScrH() - 140, 220, 55)
		surface.DrawRect(25, ScrH() - 80, 220, 25)
		surface.DrawRect(25, ScrH() - 50, 220, 25)
		
		draw.SimpleText("Time:", "HUDFont", 30, ScrH() - 125, COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		draw.SimpleText("Record:", "HUDFont", 30, ScrH() - 100, COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		
		local ModeBit = " (" .. MODE_NAME[ob:GetNWInt("BhopType", MODE_AUTO)] .. ")"
		local text = {"Spectating", ob:Name() .. ModeBit}
		if ob:IsBot() and Spectator.Data["Contains"] and Spectator.Data["IsBot"] then
			text = {"Spectating WR Bot", Spectator.Data["BotPlayer"] .. ModeBit}
		end
		
		draw.SimpleText("Remaining:", "HUDFontSmall", 30, ScrH() - 68, COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		draw.SimpleText(ConvertTime(TotalTime - CurTime() + Spectator.TimeDifference), "HUDFontSmall", 120, ScrH() - 68, COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		
		if Spectator.Data["Contains"] then
			local TimeData = {Spectator.Data["StartTime"] and CurTime() - Spectator.Data["StartTime"] or 0, Spectator.Data["BestTime"] and Spectator.Data["BestTime"] or 0}
			draw.SimpleText(ConvertTime(TimeData[1]), "HUDFont", 120, ScrH() - 125, COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText(ConvertTime(TimeData[2]), "HUDFont", 120, ScrH() - 100, COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end
		
		local SpecSpeed = math.Clamp(ob:GetVelocity():Length2D(), 0, 2000)
		local BarWidth = (SpecSpeed / 2000) * 220
		surface.SetDrawColor(Color(0, 132, 132, 255))
		surface.DrawRect(25, ScrH() - 50, BarWidth, 25)
		
		draw.SimpleText(tostring(math.ceil(SpecSpeed)), "HUDFont", 135, ScrH() - 38, COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		draw.SimpleText(text[1], "HUDHeaderBig", hw + 2, h - 58, Color(25, 25, 25, 255), TEXT_ALIGN_CENTER)
		draw.SimpleText(text[1], "HUDHeaderBig", hw, h - 60, Color(0, 120, 255, 255), TEXT_ALIGN_CENTER)

		draw.SimpleText(text[2], "HUDHeader", hw + 2, h - 18, Color(25, 25, 25, 255), TEXT_ALIGN_CENTER)
		draw.SimpleText(text[2], "HUDHeader", hw, h - 20, COLOR_WHITE, TEXT_ALIGN_CENTER)
	end

	if LocalPlayer():Team() == TEAM_SPECTATOR then
		draw.SimpleText(Spectator.Modes[Spectator.ModeID] .. " - Press R to change spectate mode.", "HUDHeader", hw + 2, 32, Color(25, 25, 25, 255), TEXT_ALIGN_CENTER)
		draw.SimpleText(Spectator.Modes[Spectator.ModeID] .. " - Press R to change spectate mode.", "HUDHeader", hw, 30, COLOR_WHITE, TEXT_ALIGN_CENTER)
		draw.SimpleText("Cycle through players with left/right mouse", "HUDHeaderSmall", hw, 60, COLOR_WHITE, TEXT_ALIGN_CENTER)
		
		if PlayerMode == MODE_PRACTICE then
			if Spectator.ModeID == 3 then
				draw.SimpleText("Type !spawn to set yourself to this position!", "HUDHeaderSmall", hw, 80, COLOR_WHITE, TEXT_ALIGN_CENTER)
			else
				draw.SimpleText("Type !tpto to teleport to this player!", "HUDHeaderSmall", hw, 80, COLOR_WHITE, TEXT_ALIGN_CENTER)
			end
		end
		
		DrawList = Spectator.Viewing
	end
	
	if CVSpec:GetBool() then
		local start = (h + 30) / 2 - 50
		local offset, drawn = start + 20, false
		for k,v in pairs(Spectator.List) do
			if not drawn then
				draw.SimpleText(ListName, "HUDLabelSmall", w - 165, start, COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
				drawn = true
			end
		
			draw.SimpleText(v, "HUDLabelSmall", w - 165, offset, COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
			offset = offset + 15
		end
	end

	return self.BaseClass:HUDPaint()
end

function GM:HUDPaintBackground()
	if not CVHud:GetBool() then return end

	if LocalPlayer() and LocalPlayer():Team() != TEAM_SPECTATOR then
		local TimeData = 0
		if not FinishTime and StartTime then
			TimeData = CurTime() - StartTime
		elseif FinishTime and StartTime then
			TimeData = FinishTime - StartTime
		end

		surface.SetDrawColor(HUD_DGRAY)
		surface.DrawRect(20, ScrH() - 145, 230, 125)
		surface.SetDrawColor(HUD_LGRAY)
		surface.DrawRect(25, ScrH() - 140, 220, 55)
		surface.DrawRect(25, ScrH() - 80, 220, 25)
		surface.DrawRect(25, ScrH() - 50, 220, 25)
		
		draw.SimpleText("Time:", "HUDFont", 30, ScrH() - 125, COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		draw.SimpleText("Record:", "HUDFont", 30, ScrH() - 100, COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		draw.SimpleText("Remaining:", "HUDFontSmall", 30, ScrH() - 68, COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		
		draw.SimpleText(ConvertTime(TimeData), "HUDFont", 120, ScrH() - 125, COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		draw.SimpleText(RecordString, "HUDFont", 120, ScrH() - 100, COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		draw.SimpleText(ConvertTime(TotalTime - CurTime() + Spectator.TimeDifference), "HUDFontSmall", 120, ScrH() - 68, COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

		local BarWidth = (math.Clamp(PLAYER_SPEED, 0, 2000) / 2000) * 220
		surface.SetDrawColor(Color(0, 132, 132, 255))
		surface.DrawRect(25, ScrH() - 50, BarWidth, 25)
		
		draw.SimpleText(tostring(PLAYER_SPEED), "HUDFont", 135, ScrH() - 38, COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		local Weapon = LocalPlayer():GetActiveWeapon()
		if Weapon and IsValid(Weapon) and Weapon.Clip1 then
			local weptext = Weapon:Clip1() .. " / " .. LocalPlayer():GetAmmoCount(Weapon:GetPrimaryAmmoType())
			draw.SimpleText(weptext, "HUDHeader", ScrW() - 18, ScrH() - 18, Color(25, 25, 25, 255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
			draw.SimpleText(weptext, "HUDHeader", ScrW() - 20, ScrH() - 20, COLOR_WHITE, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
		end
	end
end

--------------------------------
-- CLIENTSIDE CALCULATIONS --
--------------------------------

COLOR_DIFFICULTY = {Color(210, 255, 210), Color(210, 255, 255), Color(210, 210, 255), Color(255, 255, 210), Color(255, 210, 210)}

floor = math.floor
function ConvertTime(time)
	if time > 3600 then
		return string.format("%d:%.2d:%.2d.%.2d", floor(time / 3600), floor(time / 60 % 60), floor(time % 60), floor(time * 100 % 100))
	else
		return string.format("%.2d:%.2d.%.2d", floor(time / 60 % 60), floor(time % 60), floor(time * 100 % 100))
	end
end

function FriendlyName(input)
	return string.gsub(string.gsub(input, "bhop_", ""), "_", " ")
end

function GetMapColor(points, bright)
	local outcome = Color(255, 255, 255)
	
	if not points or points < 0 then points = 0 end
	if points > 175 then outcome = COLOR_DIFFICULTY[5]
	elseif points > 80 then outcome = COLOR_DIFFICULTY[4]
	elseif points > 35 then outcome = COLOR_DIFFICULTY[3]
	elseif points > 15 then outcome = COLOR_DIFFICULTY[2]
	elseif points > 0 then outcome = COLOR_DIFFICULTY[1] end

	if bright then
		return Color(outcome.r == 255 and 255 or 0, outcome.g == 255 and 255 or 0, outcome.b == 255 and 255 or 0)
	else
		return outcome
	end
end