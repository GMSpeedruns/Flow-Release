util.AddNetworkString("bhop_records")
util.AddNetworkString("bhop_vote")
util.AddNetworkString("bhop_message")
util.AddNetworkString("bhop_data")

local PLAYER = FindMetaTable("Player")

---------------------
-- PLAYER VALUES --
---------------------

function PLAYER:SetMovementData()
	self:SetHull(VEC_HULLMIN, VEC_HULLSTAND)
	self:SetHullDuck(VEC_HULLMIN, VEC_HULLDUCK)
	self:SetViewOffset(VEC_VIEWSTAND)
	self:SetViewOffsetDucked(VEC_VIEWDUCK)
end

----------------------
-- PLAYER RECORDS --
----------------------

function LoadMapRecords(map)
	for i = MODE_NORMAL, MODE_AUTO do
		if i == MODE_AUTO then
			currentMapRecords[i] = sql.Query("SELECT unique_id, time, name FROM playerauto WHERE map_name = '" .. game.GetMap() .. "' AND time != 0 ORDER BY time LIMIT 10") or {}
		else
			currentMapRecords[i] = sql.Query("SELECT unique_id, time" .. i .. " AS time, `name` FROM playerrecords WHERE map_name = '" .. map .. "' AND time" .. i .. " != 0 ORDER BY time" .. i .. " LIMIT 10") or {}
		end
	end
	currentTopPlayers = sql.Query("SELECT SUM(A.points) AS rec_points, B.name AS rec_name FROM mapdata AS A JOIN playerrecords AS B ON B.map_name = A.name GROUP BY B.unique_id ORDER BY rec_points DESC LIMIT 10") or {}
end

function PLAYER:LoadPlayerInfo()
	net.Start("bhop_records")
	net.WriteTable(currentMapRecords)
	net.Send(self)

	net.Start("bhop_vote")
	net.WriteTable(globalVoteList)
	net.Send(self)

	self.HopMode = MODE_NORMAL
	self.ThirdPerson = 0
	self.RankPoints = 0
	self.RankID = 1
	self.CurrentRecord = 0
	
	local data = sql.Query("SELECT * FROM playerrecords WHERE unique_id = '" .. self:UniqueID() .. "'")
	if data then
		for k,v in pairs(data) do
			if v["map_name"] == game.GetMap() then
				self.CurrentRecord = tonumber(v["time" .. self.HopMode])
				self:SendLua("SetRecord(" .. self.CurrentRecord .. ")")
			end
			
			local mapdata = globalMapData[v["map_name"]]
			if mapdata then
				self.RankPoints = self.RankPoints + mapdata[5]
			end
		end
		self.RankID = CalculateRank(self.RankPoints)
	end
	
	self:SetNWInt("BhopRank", self.RankID)
	self:SetNWInt("BhopType", self.HopMode)
	self:SetNWInt("BhopRec", self.CurrentRecord)
end

function PLAYER:ReloadPlayerInfo()
	self.RankPoints = 0
	self.RankID = 1

	local data = sql.Query("SELECT * FROM playerrecords WHERE unique_id = '" .. self:UniqueID() .. "'")
	if data then
		for k,v in pairs(data) do
			local mapdata = globalMapData[v["map_name"]]
			if mapdata then
				self.RankPoints = self.RankPoints + mapdata[5]
			end
		end
		self.RankID = CalculateRank(self.RankPoints)
	end
	
	self:SetNWInt("BhopRank", self.RankID)
	self:SetNWInt("BhopType", self.HopMode)
	self:SetNWInt("BhopRec", self.CurrentRecord)
end

function PLAYER:FinishMap(time)
	if self.HopMode == MODE_TELEPORT then return end
	
	self:SendLua("ShowFinish(" .. time .. ")")

	local Overridden = false
	if self.BotOverride then
		if IsBotRequired(time, self.BotMinimum) then
			Overridden = true
			self:BotEnd("")
		end
	end
	
	if not self.HasMapPoints and currentMapData and currentMapData[5] and self.HopMode != MODE_AUTO then
		self.HasMapPoints = true

		local ReceiveCredits = math.floor(currentMapData[5] / 2)
		if self.SetCredits and self.StoreNotify then
			self:SetCredits(self.Credits + ReceiveCredits)
			self:StoreNotify("You have been given ".. ReceiveCredits .." credits for beating this map. Type !store to access the store.")
		end
	end
	
	local OldRecord = self.CurrentRecord
	if self.CurrentRecord == 0 or time < self.CurrentRecord then
		if self.HopMode == MODE_AUTO then
			local Check = sql.Query("SELECT * FROM playerauto WHERE map_name = '" .. game.GetMap() .. "' AND unique_id = '" .. self:UniqueID() .. "'")
			if not Check then
				sql.Query("INSERT INTO playerauto (unique_id, `name`, map_name, time) VALUES ('" .. self:UniqueID() .. "', " .. sql.SQLStr(self:Name()) .. ", '" .. game.GetMap() .. "', '" .. time .. "')")
			else
				sql.Query("UPDATE playerauto SET time = '" .. time .. "', `name` = " .. sql.SQLStr(self:Name()) .. " WHERE unique_id = '" .. self:UniqueID() .. "' AND map_name = '" .. game.GetMap() .. "'")
			end
		else
			local Check = sql.Query("SELECT * FROM playerrecords WHERE map_name = '" .. game.GetMap() .. "' AND unique_id = '" .. self:UniqueID() .. "'")
			if not Check then
				local OtherModes = {MODE_NORMAL, MODE_SIDEWAYS, MODE_WONLY}
				table.remove(OtherModes, self.HopMode)
				
				sql.Query("INSERT INTO playerrecords (unique_id, `name`, map_name, time" .. self.HopMode .. ", time" .. OtherModes[1] .. ", time" .. OtherModes[2] .. ") VALUES ('" .. self:UniqueID() .. "', " .. sql.SQLStr(self:Nick()) .. ", '" .. game.GetMap() .. "', '" .. time .. "', 0, 0)")
			else
				sql.Query("UPDATE playerrecords SET time" .. self.HopMode .. " = '" .. time .. "', `name` = " .. sql.SQLStr(self:Nick()) .. " WHERE unique_id = '" .. self:UniqueID() .. "' AND map_name = '" .. game.GetMap() .. "'")
			end
		end
		self.CurrentRecord = time
		self:ReloadPlayerInfo()
		
		local NewWR = nil
		if self.HopMode == MODE_AUTO then
			NewWR = sql.Query("SELECT unique_id, time, `name` FROM playerauto WHERE map_name = '" .. game.GetMap() .. "' AND time != 0 ORDER BY time LIMIT 10") or {}
		else
			NewWR = sql.Query("SELECT unique_id, time" .. self.HopMode .. " AS time, `name` FROM playerrecords WHERE map_name = '" .. game.GetMap() .. "' AND time" .. self.HopMode .. " != 0 ORDER BY time" .. self.HopMode .. " LIMIT 10") or {}
		end
		
		local OldTimes = 0
		local NewTimes = 0
		
		for _,old in pairs(currentMapRecords[self.HopMode]) do
			OldTimes = OldTimes + tonumber(old['time'])
		end
		for _,new in pairs(NewWR) do
			NewTimes = NewTimes + tonumber(new['time'])
		end

		if OldTimes == NewTimes then
			self:SendLua("ShowPersonal(" .. time .. "," .. OldRecord .. ")")
			
			if OldRecord == 0 then
				SendGlobalMessage(MSG_WR_NOR_FINISH, {self:Name(), ConvertTime(time), MODE_NAME[self.HopMode]})
			else
				SendGlobalMessage(MSG_WR_IMPR_FINISH, {self:Name(), ConvertTime(OldRecord - time), ConvertTime(time), MODE_NAME[self.HopMode]})
			end
		else
			currentMapRecords[self.HopMode] = NewWR

			net.Start("bhop_records")
			net.WriteTable(currentMapRecords)
			net.Broadcast()

			local NewPosition = 0
			for k,v in pairs(currentMapRecords[self.HopMode]) do
				if v['unique_id'] == self:UniqueID() then
					NewPosition = k
					break
				end
			end

			if NewPosition == 0 then
				MsgN("[IMPOSSIBLE] If this is displayed; Check it out! - If it is not after several days, these lines can be removed!")
				self:SendLua("ShowPersonal(" .. time .. "," .. OldRecord .. ")")
				
				if OldRecord == 0 then
					SendGlobalMessage(MSG_WR_NOR_FINISH, {self:Name(), ConvertTime(time), MODE_NAME[self.HopMode]})
				else
					SendGlobalMessage(MSG_WR_IMPR_FINISH, {self:Name(), ConvertTime(OldRecord - time), ConvertTime(time), MODE_NAME[self.HopMode]})
				end
				return
			end

			self:SendLua("ShowRecord(" .. time .. "," .. OldRecord .. "," .. NewPosition .. ")")
			local rank = "-"
			if NewPosition == 1 then rank = "1st"
			elseif NewPosition == 2 then rank = "2nd"
			elseif NewPosition == 3 then rank = "3rd"
			else rank = NewPosition .. "th" end

			if OldRecord == 0 then
				SendGlobalMessage(MSG_WR_TOP_FINISH, {self:Name(), rank, ConvertTime(time), MODE_NAME[self.HopMode]})
			else
				SendGlobalMessage(MSG_WR_TOPIMPR_FINISH, {self:Name(), rank, ConvertTime(time), ConvertTime(OldRecord - time), MODE_NAME[self.HopMode]})
			end
			
			if Overridden then return end
			if NewPosition == 1 then
				self:BotEnd("#1 ")
			elseif IsBotRequired(time) then
				self:BotEnd("#" .. NewPosition .. " ")
			end
		end
	end
end

-----------------
-- MAP VOTING --
-----------------

local SelectedMaps = {}
MapInit = 0
MapVotes = 0
MapVoteList = {0, 0, 0, 0, 0}
Votable = false

function InitializeVote()
	timer.Simple(7200, StartVote)
	MapInit = CurTime()
end

function PLAYER:Rock()
	if CurTime() - MapInit < PLAYER_RTV_TIME && #player.GetHumans() > 2 then
		self:SendMessage(MSG_RTV_WAIT, {math.floor((PLAYER_RTV_TIME - (CurTime() - MapInit)) / 60)})
		return
	end
	if self.Rocked then
		self:SendMessage(MSG_RTV_VOTED, nil)
		return
	end
	
	local RequiredVotes = math.ceil(#player.GetHumans() * (2 / 3))
	self.Rocked = true
	MapVotes = MapVotes + 1
	SendGlobalMessage(MSG_RTV_DO, {self:Nick(), RequiredVotes - MapVotes})
	
	if MapVotes >= RequiredVotes then
		StartVote()
	end
end

local function RemoveVote(ply)
	local BotTest = #player.GetAll()
	if BotTest - 1 == 1 then
		BotSave()
	end
	
	SpectateEnd(ply)
	
	if ply.Rocked then
		MapVotes = MapVotes - 1
	end

	local PlayerCount = #player.GetHumans()
	if PlayerCount < 2 then return else PlayerCount = PlayerCount - 1 end
	local RequiredVotes = math.ceil(#player.GetHumans() * (2 / 3))
	
	if MapVotes >= RequiredVotes then
		StartVote()
	end
end
hook.Add("PlayerDisconnected", "RemoveVotes", "RemoveVotes")

function StartVote()
	SendGlobalMessage(MSG_RTV_CHANGE, nil)
	Votable = true
	
	local Nominations = {}
	for k,v in pairs(player.GetHumans()) do
		if v.NominatedMap then
			table.insert(Nominations, v.NominatedMap)
		end
	end
	
	local AddedMaps = 0

	for k,v in RandomPairs(Nominations) do
		if AddedMaps > 4 then break end
		if table.HasValue(SelectedMaps, v) then continue end
		
		AddedMaps = AddedMaps + 1
		table.insert(SelectedMaps, v)
	end
	
	for k,v in RandomPairs(globalMapData) do
		if AddedMaps > 4 then break end
		if table.HasValue(SelectedMaps, k) then continue end
		
		if k != game.GetMap() then
			AddedMaps = AddedMaps + 1
			table.insert(SelectedMaps, k)
		end
	end

	SendGlobalData(NET_RTVLIST, SelectedMaps)
	timer.Simple(31, EndVote)
end

function EndVote()
	BotSave()

	local Highest = 0
	local Winner = -1
	
	for i = 1, 5 do
		if MapVoteList[i] > Highest then
			Highest = MapVoteList[i]
			Winner = i
		end
	end
	
	if Winner < 0 or Winner > 5 then
		Winner = math.random(1, 5)
	end

	if not SelectedMaps[Winner] then return end
	SendGlobalMessage(MSG_RTV_MAP, {SelectedMaps[Winner]})
	timer.Simple(5, function() RunConsoleCommand("changelevel", SelectedMaps[Winner]) end)
end

-------------------------
-- MESSAGING SYSTEM --
-------------------------

function PLAYER:SendMessage(TEXT_ID, VAR_TABLE)
	net.Start("bhop_message")
	net.WriteInt(TEXT_ID, 8)
	
	if VAR_TABLE and type(VAR_TABLE) == "table" then
		net.WriteBit(true)
		net.WriteTable(VAR_TABLE)
	else
		net.WriteBit(false)
	end
	
	net.Send(self)
end

function SendGlobalMessage(TEXT_ID, VAR_TABLE, EXCLUDE)
	net.Start("bhop_message")
	net.WriteInt(TEXT_ID, 8)
	
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

function PLAYER:SendData(MSG_ID, VAR_TABLE)
	net.Start("bhop_data")
	net.WriteInt(MSG_ID, 4)
	net.WriteTable(VAR_TABLE)
	net.Send(self)
end

function SendGlobalData(MSG_ID, VAR_TABLE, EXCLUDE)
	net.Start("bhop_data")
	net.WriteInt(MSG_ID, 4)
	net.WriteTable(VAR_TABLE)
	
	if EXCLUDE and EXCLUDE:IsPlayer() then
		net.SendOmit(EXCLUDE)
	else
		net.Broadcast()
	end
end