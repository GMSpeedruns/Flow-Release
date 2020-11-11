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
local DATABASE_NAME = "prestige_bhop"
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
		timer.Simple(5, function()
			Bot:Initialize()
		end)
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
Ranks.DefaultMaximum = 20030 --19105 + 905
Ranks.MaximumPoints = Ranks.DefaultMaximum
Ranks.MaximumRank = 0
Ranks.MapBest = nil
Ranks.MapBestReload = false

function Ranks:Initialize()
	for k,v in pairs(GAMEMODE.RankList) do
		GAMEMODE.RankList[k][3] = math.floor(2.25 * math.pow(k, 2.538))
	end
	
	self:LoadMaximum()
	self:LoadMapBest()
end

function Ranks:LoadMaximum()
	SQLQuery("SELECT SUM(nPoints) AS nSum FROM records_maps", function(data)
		if not data or not data[1] or not data[1]["nSum"] then return end
		self.MaximumRank = tonumber(data[1]["nSum"]) or Ranks.DefaultMaximum
		GAMEMODE.RankList[#GAMEMODE.RankList][3] = self.MaximumRank
	end)
	
	SQLQuery("SELECT MAX(nTotalWeight) AS nMax FROM records_rank", function(data)
		if not data or not data[1] or not data[1]["nMax"] then return end
		self.MaximumPoints = tonumber(data[1]["nMax"]) or Ranks.DefaultMaximum
	end)
end

function Ranks:LoadMapBest()
	SQLQuery("SELECT MIN(nTime) AS nMin FROM records_normal WHERE szMap = '" .. game.GetMap() .. "'", function(data)
		if not data or not data[1] or not data[1]["nMin"] then return end
		self.MapBest = tonumber(data[1]["nMin"]) or nil
	end)
end

function Ranks:ReloadPlayerRank(ply)
	SQLQuery("SELECT nTotalWeight FROM records_rank WHERE nID = " .. ply:UniqueID(), function(data)
		if not data or not data[1] or not data[1]["nTotalWeight"] then return end
		
		ply.RankWeight = tonumber(data[1]["nTotalWeight"]) or 0
		ply.RankID = Ranks:CalculateRank(ply.RankWeight or 0)
		ply:SetNWInt("BhopRank", ply.RankID)
	end)
end

function Ranks:ReloadRank(ply, weight)
	ply.RankWeight = tonumber(weight) or 0
	local NewRank = Ranks:CalculateRank(ply.RankWeight)
	if ply.RankID != NewRank then
		ply.RankID = NewRank
		ply:SetNWInt("BhopRank", ply.RankID)
	end
end

function Ranks:CalculateRank(Points)
	if Points > self.MaximumPoints then
		self.MaximumPoints = Points
	end
	
	Points = (Points / self.MaximumPoints) * self.MaximumRank

	local RankID = 1
	for ID, Data in pairs(GAMEMODE.RankList) do
		if Points >= Data[3] and ID > RankID then
			RankID = ID
		end
	end
	
	return RankID
end

function Ranks:CalculateWeight(Time, Map)
	if not Map then Map = currentMapData[5] end
	if not tonumber(Map) then ServerLog("Server hasn't loaded point data for map: " .. game.GetMap()) return 0 end
	if not self.MapBest then self.MapBest = Time
	elseif Time < self.MapBest then
		self.MapUpdate = {game.GetMap(), Map, Time, true}
		self.MapBestReload = true
		self.MapBest = Time
	end
	
	local Weight = 0
	if self.MapBest * 2 < Time then
		Weight = Map / 2
	else
		Weight = Map * (self.MapBest / Time)
	end

	return Weight
end

function GM:LoadPlayer(ply)
	SQLQuery("SELECT nTotalWeight FROM records_rank WHERE nID = " .. ply:UniqueID(), function(data)
		if not data or not data[1] or not data[1]["nTotalWeight"] then return end
		
		ply.RankWeight = tonumber(data[1]["nTotalWeight"]) or 0
		ply.RankID = Ranks:CalculateRank(ply.RankWeight or 0)
		ply:SetNWInt("BhopRank", ply.RankID)
	end)
		
	SQLQuery("SELECT nTime FROM records_normal WHERE nID = " .. ply:UniqueID() .. " AND szMap = '" .. game.GetMap() .. "'", function(data)
		if not data or not data[1] or not data[1]["nTime"] then return end
			
		ply.CurrentRecord = tonumber(data[1]["nTime"])
		ply:SetNWFloat("BhopRec", ply.CurrentRecord)
		ply:SendLua("SetRecord(" .. ply.CurrentRecord .. ")")
	end)

	timer.Simple(1, function() Records:SendFull(ply) end)
	timer.Simple(2, function() self:SendMapList(ply) end)
end

function GM:ReloadMode(ply)
	ply.CurrentRecord = 0
	ply:SetNWInt("BhopType", ply.HopMode)
	ply:SetNWFloat("BhopRec", ply.CurrentRecord)

	if ply.HopMode == MODE_AUTO then
		SQLQuery("SELECT nTime FROM records_normal WHERE szMap = '" .. game.GetMap() .. "' AND nID = " .. ply:UniqueID(), function(data)
			if data and data[1] and data[1]["nTime"] then
				ply.CurrentRecord = tonumber(data[1]["nTime"])
			end

			ply:SetNWFloat("BhopRec", ply.CurrentRecord)
			ply:SendLua("SetMode(" .. ply.HopMode .. "," .. ply.CurrentRecord .. ")")
		end)
		if Ranks.MapBestReload then
			SQLQuery("SELECT nTotalWeight FROM records_rank WHERE nID = " .. ply:UniqueID(), function(data)
				if not data or not data[1] or not data[1]["nTotalWeight"] then return end
				
				ply.RankWeight = tonumber(data[1]["nTotalWeight"]) or 0
				ply.RankID = Ranks:CalculateRank(ply.RankWeight or 0)
				ply:SetNWInt("BhopRank", ply.RankID)
			end)
		end
	elseif ply.HopMode != MODE_PRACTICE then
		SQLQuery("SELECT nTime FROM records_special WHERE szMap = '" .. game.GetMap() .. "' AND nID = " .. ply:UniqueID() .. " AND nStyle = " .. ply.HopMode, function(data)
			if data and data[1] and data[1]["nTime"] then 
				ply.CurrentRecord = tonumber(data[1]["nTime"])
			end
			
			ply:SetNWFloat("BhopRec", ply.CurrentRecord)
			ply:SendLua("SetMode(" .. ply.HopMode .. "," .. ply.CurrentRecord .. ")")
			
			if ply.HopMode == MODE_BONUS then
				
			end
		end)
	else
		ply:SendLua("SetMode(" .. ply.HopMode .. "," .. ply.CurrentRecord .. ")")
	end
	
	RestartMap(ply)
end

function GM:ReloadPlayer(ply)
	ply.CurrentRecord = 0
	ply:SetNWInt("BhopType", ply.HopMode)
	ply:SetNWFloat("BhopRec", ply.CurrentRecord)
	
	if ply.HopMode == MODE_AUTO then
		SQLQuery("SELECT nTime FROM records_normal WHERE szMap = '" .. game.GetMap() .. "' AND nID = " .. ply:UniqueID(), function(data)
			if data and data[1] and data[1]["nTime"] then
				ply.CurrentRecord = tonumber(data[1]["nTime"])
			end

			ply:SetNWFloat("BhopRec", ply.CurrentRecord)
			ply:SendLua("SetRecord(" .. ply.CurrentRecord .. ")")
		end)
	elseif ply.HopMode != MODE_PRACTICE then
		SQLQuery("SELECT nTime FROM records_special WHERE szMap = '" .. game.GetMap() .. "' AND nID = " .. ply:UniqueID() .. " AND nStyle = " .. ply.HopMode, function(data)
			if data and data[1] and data[1]["nTime"] then 
				ply.CurrentRecord = tonumber(data[1]["nTime"])
			end
			
			ply:SetNWFloat("BhopRec", ply.CurrentRecord)
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
RTV.LatestList = {}

RTV.MapInit = CurTime()
RTV.MapEnd = RTV.MapInit + 7200
RTV.MapVotes = 0
RTV.MapVoteList = {0, 0, 0, 0, 0, 0}

function RTV:Initialize()
	timer.Simple(7200, function() self:StartVote() end)
	self.MapInit = CurTime()
	self.MapEnd = self.MapInit + 7200
	
	self:LatestMaps()
end

function RTV:Vote(ply)
	if CurTime() - self.MapInit < PLAYER_RTV_TIME and #player.GetHumans() > 2 then
		SendMessage(ply, MSG_ID["WaitPeriod"], {math.ceil((PLAYER_RTV_TIME - (CurTime() - self.MapInit)) / 60)})
		return
	end
	
	if ply.RTVLimit and CurTime() - ply.RTVLimit < 60 then
		SendMessage(ply, MSG_ID["BhopMsg"], {"Please wait " .. math.ceil(60 - (CurTime() - ply.RTVLimit)) .. " seconds before RTVing again."})
		return
	end
	ply.RTVLimit = CurTime()
	
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
		SendMessage(ply, MSG_ID["WaitPeriod"], {math.ceil((PLAYER_RTV_TIME - (CurTime() - self.MapInit)) / 60)})
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

	SendGlobalMessage(MSG_ID["Leave"], {ply:IsBot() and "The WR Bot" or ply:Name()}, ply)
	
	if ply.Spectating then
		Spectator:End(ply)
		ply.Spectating = false
	end
	
	if RTV.Votable then return end
	
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
			if self.Nominations[v.NominatedMap] then
				table.insert(self.Nominations[v.NominatedMap], v)
			else
				self.Nominations[v.NominatedMap] = v
			end
		end
	end

	local AddedItems = 0
	for k,v in pairs(self.Nominations) do
		if AddedItems > 4 then break end
		if table.HasValue(self.SelectedMaps, v) then continue end
		
		table.insert(self.SelectedMaps, v)
		AddedItems = AddedItems + 1
	end
	
	if AddedItems < 5 then
		for k,v in RandomPairs(globalMapData) do
			if AddedItems > 4 then break end
			if table.HasValue(self.SelectedMaps, k) then continue end
			
			if k != game.GetMap() then
				table.insert(self.SelectedMaps, k)
				AddedItems = AddedItems + 1
			end
		end
	end
	
	SendGlobalData(DATA_ID["VoteList"], self.SelectedMaps)

-- This was something I wanted to do, but quit before I could
--	DO MapVote ON TIMER WITH self.Nominations
	
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
			v:SendLua("TotalTime = " .. (self.ExtendTime * 60))
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

function RTV:LatestMaps()
	if not file.Exists("botdata/mapdata.txt", "DATA") then
		file.Write("botdata/mapdata.txt", "A;B;C;D;E")
	end
	
	local Latest = file.Read("botdata/mapdata.txt", "DATA")
	if not Latest or Latest == "" then return end
	local Split = string.Explode(";", Latest)
	if #Split != 5 then return end
	RTV.LatestList = Split
	table.insert(Split, 1, game.GetMap())
	table.remove(Split, 6)
	file.Write("botdata/mapdata.txt", string.Implode(";", Split))
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