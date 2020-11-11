------------------
-- CLIENT LISTS --
------------------

MapList = {}
MapPointList = {}
NominateList = {}
VoteList = {}
TopList = {}
MapsBeatList = {}
RecordList = {[MODE_AUTO] = {}, [MODE_SIDEWAYS] = {}, [MODE_WONLY] = {}, [MODE_SCROLL] = {}}

net.Receive("BHOP_Map", function()
	local length = net.ReadUInt(32)
	local data = net.ReadData(length)
	local tab = util.JSONToTable(util.Decompress(data))
	
	for i,d in pairs(tab) do
		MapList[i] = d[1]
		MapPointList[d[1]] = tonumber(d[2])
		NominateList[i] = FriendlyName(d[1]) .. " [" .. d[2] .. "]"
	end
end)

-----------------
-- MESSAGING --
-----------------

local txtData = {
	[MSG_ID["Nominate"]] = {["ID"] = TEXT_BHOP, ["Text"] = "1; has nominated 2;"},
	[MSG_ID["NominateChange"]] = {["ID"] = TEXT_BHOP, ["Text"] = "1; has changed his nomination from 2; to 3;"},
	[MSG_ID["RTV"]] = {["ID"] = TEXT_BHOP, ["Text"] = "1; has voted to Rock the Vote! (2; more needed)"},
	[MSG_ID["Revoke"]] = {["ID"] = TEXT_BHOP, ["Text"] = "1; has revoked his RTV! (2; more needed)"},
	[MSG_ID["WaitPeriod"]] = {["ID"] = TEXT_BHOP, ["Text"] = "You have to wait 1; minutes before you can Rock the Vote."},
	[MSG_ID["AlreadyVoted"]] = {["ID"] = TEXT_BHOP, ["Text"] = "You have already voted to Rock the Vote!"},
	[MSG_ID["VoteStart"]] = {["ID"] = TEXT_BHOP, ["Text"] = "A vote to change maps has started!"},
	[MSG_ID["MapChange"]] = {["ID"] = TEXT_BHOP, ["Text"] = "Now changing the map to 1;!"},
	[MSG_ID["AlreadyNominate"]] = {["ID"] = TEXT_BHOP, ["Text"] = "You have already nominated this map!"},
	[MSG_ID["Teleported"]] = {["ID"] = TEXT_BHOP, ["Text"] = "You have been teleported to 1;"},
	[MSG_ID["TeleportCooldown"]] = {["ID"] = TEXT_BHOP, ["Text"] = "Your mode has to be set to practice before you can use this command!"},
	[MSG_ID["TimerFinish"]] = {["ID"] = TEXT_TIMER, ["Text"] = "[3;] 1; has finished the map with a time of 2;!"},
	[MSG_ID["TimerImprove"]] = {["ID"] = TEXT_TIMER, ["Text"] = "[4;] 1; has finished the map with a time of 3;! [-2;]"},
	[MSG_ID["WRFinish"]] = {["ID"] = TEXT_TIMER, ["Text"] = "[4;] 1; has obtained the 2; rank in the top 10 with a time of 3;!"},
	[MSG_ID["WRImprove"]] = {["ID"] = TEXT_TIMER, ["Text"] = "[5;] 1; has obtained the 2; rank in the top 10 with a time of 3;! [-4;]"},
	[MSG_ID["WRRecord"]] = {["ID"] = TEXT_BOT, ["Text"] = "1;'s 2;run has been recorded and is set to be displayed by the WR Bot!"},
	[MSG_ID["Connect"]] = {["ID"] = TEXT_BHOP, ["Text"] = "1; has connected to the server."},
	[MSG_ID["Leave"]] = {["ID"] = TEXT_BHOP, ["Text"] = "1; has left the server."},
	[MSG_ID["MapExtend"]] = {["ID"] = TEXT_BHOP, ["Text"] = "This map has been extended by a time of 1; minutes!"},
	[MSG_ID["ExtendLimit"]] = {["ID"] = TEXT_BHOP, ["Text"] = "The map has already been extended by 1; minutes. This option is not votable."},
	[MSG_ID["TimeLeft"]] = {["ID"] = TEXT_BHOP, ["Text"] = "There is 1; left on this map!"},
	[MSG_ID["LJMsg"]] = {["ID"] = TEXT_LJ, ["Text"] = "1;"},
	[MSG_ID["AdminMsg"]] = {["ID"] = TEXT_ADMIN, ["Text"] = "1;"},
	[MSG_ID["BhopMsg"]] = {["ID"] = TEXT_BHOP, ["Text"] = "1;"},
	[MSG_ID["BotMsg"]] = {["ID"] = TEXT_BOT, ["Text"] = "1;"},
}
local msgData = {[TEXT_BHOP] = {"Bhop", Color(168, 223, 133)}, [TEXT_TIMER] = {"Timer", Color(133, 156, 223)}, [TEXT_ADMIN] = {"Admin", Color(223, 133, 133)}, [TEXT_BOT] = {"Bot", Color(133, 201, 223)}, [TEXT_LJ] = {"LJ", Color(223, 201, 133)}}

local function ReceivePlayerMessage()
	local TEXT_ID = net.ReadInt(8)
	local HAS_VAR = net.ReadBit() == 1
	local VAR_TABLE = {}

	if HAS_VAR then
		VAR_TABLE = net.ReadTable()
	end
	
	if TEXT_ID then
		WrapText(txtData[TEXT_ID], VAR_TABLE)
		
		if TEXT_ID == MSG_ID["ExtendLimit"] then
			if wnd["Form"] and wnd["Form"].Data and wnd["Form"].Data.ID == "Vote" then
				local Data = wnd["Form"].Data
				for i = 1, 6 do
					Data.Labels[i]:SetColor(GetMapColor(Data.PointList[i]))
				end
			end
		end
	else
		AddText(TEXT_BHOP, "Receive error!")
	end
end
net.Receive("BHOP_Msg", ReceivePlayerMessage)

function WrapText(DATA, TAB)
	local Text = DATA["Text"]
	for ID, V in pairs(TAB) do
		Text = string.gsub(Text, ID .. ";", V)
	end
	AddText(DATA["ID"], Text)
end

function AddText(PREF, TEXT)
	chat.AddText(COLOR_WHITE, "[", msgData[PREF][2], msgData[PREF][1], COLOR_WHITE, "] " .. TEXT)
	if IsChatEnabled() then chat.PlaySound() end
end

local function ReceivePlayerData()
	local ID = net.ReadInt(8)
	local HAS_VAR = net.ReadBit() == 1
	local VAR_TABLE = {}
	
	if HAS_VAR then
		VAR_TABLE = net.ReadTable()
	end

	if ID and VAR_TABLE and type(VAR_TABLE) == "table" then
		ParseData(ID, VAR_TABLE)
	else
		AddText(TEXT_BHOP, "[BHOP Data] Message receive failure 0x01: MSGID " .. ID)
	end
end
net.Receive("BHOP_Data", ReceivePlayerData)

function ParseData(ID, DATA)
	if ID == DATA_ID["VoteList"] then
		VoteList = DATA
		SetActiveWindow("Vote")
	elseif ID == DATA_ID["Votes"] then
		if IsWindowActive("Vote") then
			wnd["Form"].Data.Votes = DATA
			wnd["Form"].Data.NewVoteData = true
		end
	elseif ID == DATA_ID["WRFull"] then
		RecordList = DATA
		if IsWindowActive("WR") then SetActiveWindow("WR", PlayerMode) end
	elseif ID == DATA_ID["WRUpdate"] then
		RecordList[DATA[1]] = DATA[2]
		if IsWindowActive("WR") then SetActiveWindow("WR", PlayerMode) end
	elseif ID == DATA_ID["MapsBeat"] then
		MapsBeatList = DATA
		SetActiveWindow("Beat")
	elseif ID == DATA_ID["MapsLeft"] then
		MapsBeatList = DATA
		SetActiveWindow("Left")
	elseif ID == DATA_ID["TopList"] then
		TopList = DATA
		SetActiveWindow("Top")
	elseif ID == DATA_ID["SpecView"] then
		ProcessView(DATA)
	elseif ID == DATA_ID["SpecTime"] then
		ProcessTime(DATA)
	elseif ID == DATA_ID["LJ"] then
		DisplayLJ(DATA)
	end
end

-----------------
-- SPECTATING --
-----------------

Spectator = {}
Spectator.List = {}
Spectator.Viewing = {}
Spectator.Data = {["Contains"] = false, ["IsBot"] = false, ["BotPlayer"] = "Bot", ["StartTime"] = nil, ["BestTime"] = nil}
Spectator.ModeID = 1
Spectator.Modes = {"First Person", "Chase Cam", "Free Roam"}
Spectator.TimeDifference = 0

function ProcessView(data)
	if data[1] then
		if not Spectator.List[data[3]] or Spectator.List[data[3]] != data[2] then
			Spectator.List[data[3]] = data[2]
		end
	else
		if Spectator.List[data[3]] then
			Spectator.List[data[3]] = nil
		end
	end
end

function ProcessTime(data)
	if not data[1] then
		if data[4] then SyncTime(tonumber(data[4])) end
		if data[5] and #data[5] > 0 then SetSpecList(data[5]) else SetSpecList({}) end
		
		Spectator.Data["IsBot"] = false
		Spectator.Data["StartTime"] = data[2] and tonumber(data[2]) + Spectator.TimeDifference or nil
		Spectator.Data["BestTime"] = data[3] and tonumber(data[3]) or 0
		Spectator.Data["Contains"] = true
	else
		if data[5] then SyncTime(tonumber(data[5])) end
		if data[6] and #data[6] > 0 then SetSpecList(data[6]) else SetSpecList({}) end
		
		Spectator.Data["IsBot"] = true
		Spectator.Data["BotPlayer"] = data[3] or "Bot"
		Spectator.Data["StartTime"] = data[2] and tonumber(data[2]) + Spectator.TimeDifference or nil
		Spectator.Data["BestTime"] = data[4] and tonumber(data[4]) or 0
		Spectator.Data["Contains"] = true
	end
end

function SyncTime(sv)
	if not sv then return end
	Spectator.TimeDifference = CurTime() - sv
end

function ClearSpec()
	Spectator.List = {}
	Spectator.Data = {["Contains"] = false, ["IsBot"] = false, ["BotPlayer"] = "Bot", ["StartTime"] = nil, ["BestTime"] = nil}
	if ThirdPerson == 1 then ThirdPerson = 0 end
	SpecMode(1)
end

function SetSpecList(list)
	Spectator.Viewing = list
end

function SpecMode(id)
	Spectator.ModeID = id
end

function ToggleChat()
	local ctime = GetConVar("hud_saytext_time"):GetInt()
	if ctime > 0 then
		AddText(TEXT_BHOP, "Chat has been hidden! Type !chat to show it again")
		RunConsoleCommand("hud_saytext_time", 0)
	else
		AddText(TEXT_BHOP, "Chat has been re-enabled!")
		RunConsoleCommand("hud_saytext_time", 12)
	end
end

function IsChatEnabled()
	return GetConVar("hud_saytext_time"):GetInt() > 0
end

-----------------
-- CALCULATE --
-----------------

function DisplayLJ(data)
	for i = 1, 5 do if not data[i] or not tonumber(data[i]) then return else data[i] = tonumber(data[i]) end end
	
	AddText(TEXT_LJ, data[1] .. " units")
	print("Long Jump Distance: " .. data[1] .. ", Prestrafe: " .. data[3] .. ", Strafes: " .. data[4] .. ", Max Speed: " .. data[5] .. ", Sync: " .. data[2])
	if tonumber(data[5]) > 0 and data[6] and #data[6] > 0 then
		print("#	Max	Gain	Loss	Sync")
		for k,v in pairs(data[6]) do
			print(v[1] .. "	" .. v[2] .. "	" .. v[3] .. "	" .. v[4] .. "	" .. v[5])
		end
	end
end

-- I should bother to re-do this, but I'm just wasting time adding memory consuming comments on client-side files
hook.Add("PrePlayerDraw", "BlockPlayerPre", function(ply)
	ply:SetNoDraw(not CVPlayer:GetBool())
	if not CVPlayer:GetBool() then return true end
end)

local function OnEntitySpawned(ent)
	if ent:GetClass() == "env_spritetrail" then
		if not CVPlayer:GetBool() then
			if ent:GetParent() and ent:GetParent():IsValid() and ent:GetParent():IsPlayer() then
				ent.OldColor = ent:GetColor()
				ent:SetColor(Color(255, 255, 255, 0))
				ent:SetNoDraw(true)
				ent:SetModelScale(0, 0)
			end
		end
	end
end
hook.Add("OnEntityCreated", "EntityBlock", OnEntitySpawned)

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

hook.Add("PlayerBindPress", "CheckIllegalBind", function(ply, bind, pressed)
	if LocalPlayer():Team() == TEAM_HOP and (PlayerMode == MODE_SIDEWAYS or PlayerMode == MODE_WONLY) then
		local data = IllegalKeys[PlayerMode]
		for k,v in pairs(data.Bind) do
			if string.find(bind, v) then
				if pressed then AddText(TEXT_BHOP, "This key is not allowed in " .. MODE_NAME[PlayerMode] .. " play style.") end
				return true
			end
		end
	end
end)

function GetVectorString(vec, short)
	if short then
		return string.format("%.0f,%.0f,%.0f", vec.x, vec.y, vec.z)
	else
		return vec.x .. "," .. vec.y .. "," .. vec.z
	end
end