require("mysqloo")

util.AddNetworkString("BHOP_Map")
util.AddNetworkString("BHOP_Msg")
util.AddNetworkString("BHOP_Data")

----------
-- SQL --
----------

mSQL = {}

local DATABASE_HOST = "127.0.0.1"
local DATABASE_PORT = 3306
local DATABASE_NAME = "bhop_database"
local DATABASE_USERNAME = "root"
local DATABASE_PASSWORD = ""
local DATABASE_POST = false

function mSQLInit()
	DATABASE_POST = true
	mSQL = mysqloo.connect(DATABASE_HOST, DATABASE_USERNAME, DATABASE_PASSWORD, DATABASE_NAME, DATABASE_PORT)
	mSQL.onConnected = mSQL_onConnected
	mSQL.onConnectionFailed = mSQL_onConnectionFailed
	mSQL:connect()
end

function mSQLRetry()
	if mSQL == nil then
		mSQL = mysqloo.connect(DATABASE_HOST, DATABASE_USERNAME, DATABASE_PASSWORD, DATABASE_NAME, DATABASE_PORT)
		mSQL:connect()
	end
end

function mSQL_onConnected()
	if DATABASE_POST then
		DATABASE_POST = false
		
		CacheMaps()
		ExecMapChecks(game.GetMap())

		RTV:Initialize()
		Ranks:Initialize()
		Records:Initialize()
		
		CreateAreaBoxes()
		SetupMapTriggers()
		timer.Simple(5, function() Bot:Initialize() end)
	end
end

function mSQL_onConnectionFailed(e)
	ServerLog("Connection to database failed!")
	ServerLog("Error:", e)
end

function SQLQuery(query, callback, arg)
	mSQLRetry()

	local tQuery = mSQL:query(query)
	
	function tQuery:onSuccess(data)
		if callback then callback(data, arg) end
	end
	
	function tQuery:onError(A, B)
		if callback then callback({}) end
		ServerLog("[SQL Error]" .. A .. "\n" .. B .. "\n")
	end
	
	tQuery:start()
end

-------------------
-- RANK SYSTEM --
-------------------

Ranks = {}
Ranks.MaximumRank = 0
Ranks.TopRank = math.floor(2.275 * math.pow(36, 2.5))
Ranks.PointFactor = 0.10

function Ranks:Initialize()
	for k,v in pairs(GAMEMODE.RankList) do
		GAMEMODE.RankList[k][3] = math.floor(2.275 * math.pow(k, 2.5))
	end
	Ranks.TopRank = GAMEMODE.RankList[#GAMEMODE.RankList][3]

	self:LoadMaximum()
end

function Ranks:LoadMaximum()
	SQLQuery("SELECT MAX(nTotalWeight) AS nMaxTotal FROM records_rank", function(data)
		if not data or not data[1] or not data[1]["nMaxTotal"] then return end
		self.MaximumRank = tonumber(data[1]["nMaxTotal"])
	end)
end

function Ranks:ReloadGlobal()
	for k,v in pairs(player.GetHumans()) do
		local new = Ranks:CalculateRank(Ranks:RelativeRank(v))
		if v.RankID != new then
			v.RankID = new
			v:SetNWInt("BhopRank", v.RankID)
		end
	end
end

function Ranks:ReloadRank(ply, weight)
	ply.RankWeight = tonumber(weight) or 0
	if Ranks.MaximumRank and (Ranks.MaximumRank == 0 or ply.RankWeight > Ranks.MaximumRank) then
		Ranks.MaximumRank = ply.RankWeight
	end

	Ranks:ReloadGlobal()
end

function Ranks:RelativeRank(ply)
	if Ranks.MaximumRank and Ranks.MaximumRank > 0 then
		return (ply.RankWeight / Ranks.MaximumRank) * Ranks.TopRank
	end
	
	return 0
end

function Ranks:CalculateRank(Points)
	local RankID = 1
	
	for ID, Data in pairs(GAMEMODE.RankList) do
		if Points >= Data[3] and ID > RankID then
			RankID = ID
		end
	end
	
	return RankID
end

function Ranks:CalculateWeight(Time, Map)
	if not Map then
		Map = currentMapData[5]
	end
	
	if not tonumber(Map) then ServerLog("Server hasn't loaded point data, but has finishing area") return 0 end
	return Map / (Time / (Ranks.PointFactor * Map))
end

function GM:LoadPlayer(ply)
	SQLQuery("SELECT nTotalWeight FROM records_rank WHERE nID = " .. ply:UniqueID(), function(data)
		if not data or not data[1] or not data[1]["nTotalWeight"] then return end
		
		ply.RankWeight = tonumber(data[1]["nTotalWeight"]) or 0
		ply.RankID = Ranks:CalculateRank(Ranks:RelativeRank(ply))
		ply:SetNWInt("BhopRank", ply.RankID)
	end)
		
	SQLQuery("SELECT nTime FROM records_normal WHERE nID = " .. ply:UniqueID() .. " AND szMap = '" .. game.GetMap() .. "'", function(data)
		if not data or not data[1] or not data[1]["nTime"] then return end
			
		ply.CurrentRecord = tonumber(data[1]["nTime"])
		ply:SetNWInt("BhopRec", ply.CurrentRecord)
		ply:SendLua("SetRecord(" .. ply.CurrentRecord .. ")")
	end)

	timer.Simple(1, function() Records:SendFull(ply) end)
	timer.Simple(2, function() self:SendMapList(ply) end)
end

function GM:ReloadMode(ply)
	ply.CurrentRecord = 0
	ply:SetNWInt("BhopType", ply.HopMode)
	ply:SetNWInt("BhopRec", ply.CurrentRecord)

	if ply.HopMode == MODE_NORMAL then
		SQLQuery("SELECT nTime FROM records_normal WHERE szMap = '" .. game.GetMap() .. "' AND nID = " .. ply:UniqueID(), function(data)
			if data and data[1] and data[1]["nTime"] then
				ply.CurrentRecord = tonumber(data[1]["nTime"])
			end

			ply:SetNWInt("BhopRec", ply.CurrentRecord)
			ply:SendLua("SetMode(" .. ply.HopMode .. "," .. ply.CurrentRecord .. ")")
		end)
	elseif ply.HopMode != MODE_PRACTICE then
		SQLQuery("SELECT nTime FROM records_special WHERE szMap = '" .. game.GetMap() .. "' AND nID = " .. ply:UniqueID() .. " AND nStyle = " .. ply.HopMode, function(data)
			if data and data[1] and data[1]["nTime"] then 
				ply.CurrentRecord = tonumber(data[1]["nTime"])
			end
			
			ply:SetNWInt("BhopRec", ply.CurrentRecord)
			ply:SendLua("SetMode(" .. ply.HopMode .. "," .. ply.CurrentRecord .. ")")
		end)
	else
		ply:SendLua("SetMode(" .. ply.HopMode .. "," .. ply.CurrentRecord .. ")")
	end
	
	RestartMap(ply)
end

function GM:ReloadPlayer(ply)
	ply.CurrentRecord = 0
	ply:SetNWInt("BhopType", ply.HopMode)
	ply:SetNWInt("BhopRec", ply.CurrentRecord)
	
	if ply.HopMode == MODE_NORMAL then
		SQLQuery("SELECT nTime FROM records_normal WHERE szMap = '" .. game.GetMap() .. "' AND nID = " .. ply:UniqueID(), function(data)
			if data and data[1] and data[1]["nTime"] then
				ply.CurrentRecord = tonumber(data[1]["nTime"])
			end

			ply:SetNWInt("BhopRec", ply.CurrentRecord)
			ply:SendLua("SetRecord(" .. ply.CurrentRecord .. ")")
		end)
	elseif ply.HopMode != MODE_PRACTICE then
		SQLQuery("SELECT nTime FROM records_special WHERE szMap = '" .. game.GetMap() .. "' AND nID = " .. ply:UniqueID() .. " AND nStyle = " .. ply.HopMode, function(data)
			if data and data[1] and data[1]["nTime"] then 
				ply.CurrentRecord = tonumber(data[1]["nTime"])
			end
			
			ply:SetNWInt("BhopRec", ply.CurrentRecord)
			ply:SendLua("SetRecord(" .. ply.CurrentRecord .. ")")
		end)
	else
		ply:SendLua("SetRecord(0)")
	end
end

-----------------
-- MAP VOTING --
-----------------

RTV = {}
RTV.Votable = false
RTV.Extendable = true
RTV.ExtendTime = 15
RTV.SelectedMaps = {}

RTV.MapInit = CurTime()
RTV.MapEnd = RTV.MapInit + 7200
RTV.MapVotes = 0
RTV.MapVoteList = {0, 0, 0, 0, 0, 0}

function RTV:Initialize()
	timer.Simple(7200, function() self:StartVote() end)
	self.MapInit = CurTime()
	self.MapEnd = self.MapInit + 7200
end

function RTV:Vote(ply)
	if CurTime() - self.MapInit < PLAYER_RTV_TIME and #player.GetHumans() > 2 then
		SendMessage(ply, MSG_ID["WaitPeriod"], {math.floor((PLAYER_RTV_TIME - (CurTime() - self.MapInit)) / 60)})
		return
	end
	
	if ply.Rocked or self.Votable then
		SendMessage(ply, MSG_ID["AlreadyVoted"])
		return
	end

	ply.Rocked = true
	
	local RequiredVotes = math.ceil(#player.GetHumans() * 0.66)
	self.MapVotes = self.MapVotes + 1
	SendGlobalMessage(MSG_ID["RTV"], {ply:Name(), RequiredVotes - self.MapVotes})
	
	if self.MapVotes >= RequiredVotes then
		self:StartVote()
	end
end

function RTV:Revoke(ply)
	if CurTime() - self.MapInit < PLAYER_RTV_TIME and #player.GetHumans() > 2 then
		SendMessage(ply, MSG_ID["WaitPeriod"], {math.floor((PLAYER_RTV_TIME - (CurTime() - self.MapInit)) / 60)})
		return
	end
	
	if ply.Rocked and not self.Votable then
		ply.Rocked = false
		self.MapVotes = self.MapVotes - 1
		if self.MapVotes < 0 then self.MapVotes = 0 end
		
		local RequiredVotes = math.ceil(#player.GetHumans() * 0.66)
		SendGlobalMessage(MSG_ID["Revoke"], {ply:Name(), RequiredVotes - self.MapVotes})
	end
end

function GM:PlayerDisconnected(ply)
	local BotTest = #player.GetAll()
	if BotTest - 1 == 1 then
		Bot:Save()
	end

	if ply.Connected then
		SendGlobalMessage(MSG_ID["Leave"], {ply:IsBot() and "The WR Bot" or ply:Name()}, ply)
	end
	
	if ply.Spectating then
		Spectator:End(ply)
		ply.Spectating = false
	end
	
	if ply.Rocked then
		RTV.MapVotes = RTV.MapVotes - 1
		if RTV.MapVotes < 0 then RTV.MapVotes = 0 end
	end
	
	local PlayerCount = #player.GetHumans()
	if PlayerCount < 2 then return else PlayerCount = PlayerCount - 1 end
	
	local RequiredVotes = math.ceil(PlayerCount * 0.66)
	if RTV.MapVotes >= RequiredVotes then
		RTV:StartVote()
	end
end

function RTV:StartVote()
	SendGlobalMessage(MSG_ID["VoteStart"])
	self.Cancelled = false
	self.Votable = true
	self.Nominations = {}
	self.SelectedMaps = {}
	
	for k,v in pairs(player.GetHumans()) do
		if v.NominatedMap then
			table.insert(self.Nominations, v.NominatedMap)
		end
	end

	local AddedItems = 0
	for k,v in pairs(self.Nominations) do
		if AddedItems > 4 then break end
		if table.HasValue(self.SelectedMaps, v) then continue end
		
		table.insert(self.SelectedMaps, v)
		AddedItems = AddedItems + 1
	end
	
	for k,v in RandomPairs(globalMapData) do
		if AddedItems > 4 then break end
		if table.HasValue(self.SelectedMaps, k) then continue end
		
		if k != game.GetMap() then
			table.insert(self.SelectedMaps, k)
			AddedItems = AddedItems + 1
		end
	end
	
	SendGlobalData(DATA_ID["VoteList"], self.SelectedMaps)
	timer.Simple(31, function() self:EndVote() end)
end

function RTV:EndVote()
	if RTV.Cancelled then RTV.Cancelled = false return end
	Bot:Save()

	local Highest = 0
	local Winner = -1
	
	for i = 1, 6 do
		if self.MapVoteList[i] > Highest then
			Highest = self.MapVoteList[i]
			Winner = i
		end
	end
	
	if Winner == 0 or Winner < 0 then
		Winner = math.random(1, 5)
	elseif Winner == 6 and not self.Extendable then
		SendGlobalMessage(MSG_ID["ExtendLimit"], {self.ExtendTime})
		Winner = math.random(1, 5)
	elseif Winner == 6 then
		self.Extendable = false
		SendGlobalMessage(MSG_ID["MapExtend"], {self.ExtendTime})
		
		self.Votable = false
		self.SelectedMaps = {}

		self.MapInit = CurTime()
		self.MapEnd = self.MapInit + (self.ExtendTime * 60)
		self.MapVotes = 0
		self.MapVoteList = {0, 0, 0, 0, 0, 0}

		timer.Simple(self.ExtendTime * 60, function() self:StartVote() end)
		
		for k,v in pairs(player.GetHumans()) do
			if v.Rocked then
				v.Rocked = nil
			end
			if v.NominatedMap then
				v.NominatedMap = nil
			end
		end
		
		return
	end
	
	local Map = self.SelectedMaps[Winner]
	if not Map then return end
	
	SendGlobalMessage(MSG_ID["MapChange"], {Map})
	timer.Simple(5, function() RunConsoleCommand("changelevel", Map) end)
end

function RTV:ForceExtend(extend)
	Bot:Save()
	
	self.Cancelled = true
	self.ExtendTime = extend or self.ExtendTime
	self.Extendable = false
	SendGlobalMessage(MSG_ID["MapExtend"], {self.ExtendTime})
		
	self.Votable = false
	self.SelectedMaps = {}

	self.MapInit = CurTime()
	self.MapEnd = self.MapInit + (self.ExtendTime * 60)
	self.MapVotes = 0
	self.MapVoteList = {0, 0, 0, 0, 0, 0}

	timer.Simple(self.ExtendTime * 60, function() self:StartVote() end)
		
	for k,v in pairs(player.GetHumans()) do
		if v.Rocked then
			v.Rocked = nil
		end
		if v.NominatedMap then
			v.NominatedMap = nil
		end
	end
end

function GM:SendMapList(ply)
	net.Start("BHOP_Map")
	net.WriteUInt(mapListLength, 32)
	net.WriteData(globalMapList, mapListLength)
	net.Send(ply)
end

-------------------------
-- MESSAGING SYSTEM --
-------------------------

function SendMessage(PLAYER, ID, VAR_TABLE)
	if not ID then return end
	net.Start("BHOP_Msg")
	net.WriteInt(ID, 8)
	
	if VAR_TABLE and type(VAR_TABLE) == "table" then
		net.WriteBit(true)
		net.WriteTable(VAR_TABLE)
	else
		net.WriteBit(false)
	end

	net.Send(PLAYER)
end

function SendGlobalMessage(ID, VAR_TABLE, EXCLUDE)
	if not ID then return end
	net.Start("BHOP_Msg")
	net.WriteInt(ID, 8)

	if VAR_TABLE and type(VAR_TABLE) == "table" then
		net.WriteBit(true)
		net.WriteTable(VAR_TABLE)
	else
		net.WriteBit(false)
	end

	if EXCLUDE and EXCLUDE:IsPlayer() then
		net.SendOmit(EXCLUDE)
	else
		net.Broadcast()
	end
end

function SendData(PLAYER, ID, VAR_TABLE)
	if not ID then return end
	net.Start("BHOP_Data")
	net.WriteInt(ID, 8)
	
	if VAR_TABLE and type(VAR_TABLE) == "table" then
		net.WriteBit(true)
		net.WriteTable(VAR_TABLE)
	else
		net.WriteBit(false)
	end

	net.Send(PLAYER)
end

function SendGlobalData(ID, VAR_TABLE, EXCLUDE)
	if not ID then return end
	net.Start("BHOP_Data")
	net.WriteInt(ID, 8)
	
	if VAR_TABLE and type(VAR_TABLE) == "table" then
		net.WriteBit(true)
		net.WriteTable(VAR_TABLE)
	else
		net.WriteBit(false)
	end

	if EXCLUDE and EXCLUDE:IsPlayer() then
		net.SendOmit(EXCLUDE)
	else
		net.Broadcast()
	end
end