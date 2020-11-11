----------------------
-- PLAYER RECORDS --
----------------------

MapsBeatList = {}
TopList = {}
RecordList = {}
HasRecordList = false
SpectatorData = {["Contains"] = false, ["IsBot"] = false, ["BotPlayer"] = "Bot", ["StartTime"] = nil, ["BestTime"] = nil}

local function ReceiveRecordData(length)
	RecordList = net.ReadTable()
	HasRecordList = true
end
net.Receive("bhop_records", ReceiveRecordData)

-----------------
-- MAP VOTING --
-----------------

MapList = {}
MapPointList = {}
RTVList = {}
RTVVotes = {0, 0, 0, 0, 0}

local function ReceiveVoteList(length)
	local DataTable = net.ReadTable()
	for i,mapData in pairs(DataTable) do
		table.insert(MapList, mapData[1])
		MapPointList[mapData[1]] = tonumber(mapData[2])
	end
end
net.Receive("bhop_vote", ReceiveVoteList)

local function ReceiveDataTable(length)
	local Type = net.ReadInt(4)
	
	if Type == NET_TOPLIST then
		TopList = net.ReadTable()
		ShowTop()
	elseif Type == NET_RTVLIST then
		RTVList = net.ReadTable()
		ShowVote()
	elseif Type == NET_RTVVOTES then
		RTVVotes = net.ReadTable()
	elseif Type == NET_MAPSBEAT then
		MapsBeatList = net.ReadTable()
		ShowBeat()
	elseif Type == NET_MAPSLEFT then
		MapsBeatList = net.ReadTable()
		ShowLeft()
	elseif Type == NET_SPECDATA then
		local Data = net.ReadTable()
		CalculateSpectator(Data)
	end
end
net.Receive("bhop_data", ReceiveDataTable)

--------------------
-- PLAYER HIDING --
--------------------

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

local VarsSet = false
hook.Add("PrePlayerDraw", "BlockPlayerPre", function(ply)
	if not CVPlayer:GetBool() then if not VarsSet then ply:SetNoDraw(true) ply:DrawShadow(false) ply.CurrentModelScale = ply:GetModelScale() ply:SetModelScale(0, 0) VarsSet = true end return true
	elseif VarsSet then ply:SetNoDraw(false) ply:DrawShadow(true) ply:SetModelScale(ply.CurrentModelScale or 1, 0) ply.CurrentModelScale = nil VarsSet = false end
end)
hook.Add("PostPlayerDraw", "BlockPlayerPost", function(ply)
	if not CVPlayer:GetBool() then if not VarsSet then ply:SetNoDraw(true) ply:DrawShadow(false) ply.CurrentModelScale = ply:GetModelScale() ply:SetModelScale(0, 0) VarsSet = true end return true
	elseif VarsSet then ply:SetNoDraw(false) ply:DrawShadow(true) ply:SetModelScale(ply.CurrentModelScale or 1, 0) ply.CurrentModelScale = nil VarsSet = false end
end)

------------------------
-- PLAYER MOVEMENT --
------------------------

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

-------------------------
-- MESSAGING SYSTEM --
-------------------------

local txtData = {
	[MSG_RTV_NOMSET] = {["ID"] = TEXT_BHOP, ["Text"] = "1; has nominated 2;"},
	[MSG_RTV_NOMCHG] = {["ID"] = TEXT_BHOP, ["Text"] = "1; has changed his nomination from 2; to 3;"},
	[MSG_RTV_DO] = {["ID"] = TEXT_BHOP, ["Text"] = "1; has voted to Rock the Vote! (2; more needed)"},
	[MSG_RTV_WAIT] = {["ID"] = TEXT_BHOP, ["Text"] = "You have to wait 1; minutes before you can Rock the Vote."},
	[MSG_RTV_VOTED] = {["ID"] = TEXT_BHOP, ["Text"] = "You have already voted to Rock the Vote!"},
	[MSG_RTV_CHANGE] = {["ID"] = TEXT_BHOP, ["Text"] = "A vote to change maps has started!"},
	[MSG_RTV_MAP] = {["ID"] = TEXT_BHOP, ["Text"] = "Now changing the map to 1;!"},
	[MSG_RTV_ALNOM] = {["ID"] = TEXT_BHOP, ["Text"] = "You have already nominated this map!"},
	[MSG_TXT_TPTO] = {["ID"] = TEXT_BHOP, ["Text"] = "You have been teleported to 1;"},
	[MSG_TXT_TPCMD] = {["ID"] = TEXT_BHOP, ["Text"] = "Your mode has to be set to teleportation before you can use this command!"},
	[MSG_WR_NOR_FINISH] = {["ID"] = TEXT_TIMER, ["Text"] = "[3;] 1; has finished the map with a time of 2;!"},
	[MSG_WR_IMPR_FINISH] = {["ID"] = TEXT_TIMER, ["Text"] = "[4;] 1; has finished the map with a time of 3;! [-2;]"},
	[MSG_WR_TOP_FINISH] = {["ID"] = TEXT_TIMER, ["Text"] = "[4;] 1; has obtained the 2; rank in the top 10 with a time of 3;!"},
	[MSG_WR_TOPIMPR_FINISH] = {["ID"] = TEXT_TIMER, ["Text"] = "[5;] 1; has obtained the 2; rank in the top 10 with a time of 3;! [-4;]"},
	[MSG_WR_RECORDED] = {["ID"] = TEXT_TIMER, ["Text"] = "1;'s 2;run has been recorded and is set to be displayed by the WR Bot!"},
	[MSG_ADMIN_GENERAL] = {["ID"] = TEXT_ADMIN, ["Text"] = "1;"},
	[MSG_BHOP_GENERAL] = {["ID"] = TEXT_BHOP, ["Text"] = "1;"}
}

local COLOR_WHITE = Color(255, 255, 255)
local COLOR_BHOP = Color(168, 223, 133)
local COLOR_TIMER = Color(133, 156, 223)
local COLOR_ADMIN = Color(223, 133, 133)

local function ReceivePlayerMessage(length)
	local TEXT_ID = net.ReadInt(8)
	local HAS_VAR = net.ReadBit() == 1
	local VAR_TABLE = {}

	if HAS_VAR then
		VAR_TABLE = net.ReadTable()
	end
	
	if TEXT_ID then
		WrapText(txtData[TEXT_ID], VAR_TABLE)
	else
		AddText(TEXT_BHOP, "Receive error!")
	end
end
net.Receive("bhop_message", ReceivePlayerMessage)

function WrapText(D, T)
	local Text = D["Text"]
	for ID, V in pairs(T) do
		Text = string.gsub(Text, ID .. ";", V)
	end
	AddText(D["ID"], Text)
end

function AddText(P, T)
	local COLOR = P == TEXT_BHOP and COLOR_BHOP or (P == TEXT_ADMIN and COLOR_ADMIN or COLOR_TIMER)
	local PREFIX = P == TEXT_BHOP and "Bhop" or (P == TEXT_ADMIN and "Admin" or "Timer")

	chat.AddText(COLOR_WHITE, "[", COLOR, PREFIX, COLOR_WHITE, "] " .. T)
	chat.PlaySound()
end