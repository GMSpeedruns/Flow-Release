local PLAYER = FindMetaTable("Player")

function PLAYER:StartTimer()
	if self:IsBot() then return end
	self.timer = CurTime()
	self:SendLua("StartTimer(" .. self.timer .. ")")
	if self.BotRecord then self.BotFromStart = true Bot.Leader:StartRecord(self, true) end
		
	for k,v in pairs(player.GetHumans()) do
		if not v.Spectating then continue end
		local ob = v:GetObserverTarget()
		if ob and ob == self and self.timer and self.timer > 0 then
			SendData(v, DATA_ID["SpecTime"], {false, self.timer, (self.CurrentRecord and self.CurrentRecord > 0) and self.CurrentRecord or nil, CurTime()})
		end
	end
end

function PLAYER:ResetTimer()
	self.timer = nil
	self.timerFinish = nil
	self:SendLua("StopTimer(0)")
end

function PLAYER:StopTimer(IsFinish)
	if self:IsBot() then return end
	if IsFinish then
		self.timerFinish = CurTime()
		self:SendLua("StopTimer(" .. self.timerFinish .. ")")
		Timer:FinishMap(self, self.timerFinish - self.timer)
	else
		self:ResetTimer()
	end
end

Timer = {}

function Timer:FinishMap(ply, time)
	if ply.HopMode == MODE_PRACTICE then return end
	ply:SendLua("ShowFinish(" .. time .. ")")
	
	local OldRecord = ply.CurrentRecord or 0
	if ply.CurrentRecord != 0 and time >= ply.CurrentRecord then return end
	
	if ply.HopMode == MODE_NORMAL then
		SQLQuery("SELECT nTime FROM records_normal WHERE szMap = '" .. game.GetMap() .. "' AND nID = " .. ply:UniqueID(), function(data)
			if data and data[1] and tonumber(data[1]["nTime"]) then
				SQLQuery("UPDATE records_normal SET nTime = " .. time .. ", szName = '" .. mSQL:escape(ply:Nick()) .. "', nWeight = " .. Ranks:CalculateWeight(time) .. " WHERE nID = " .. ply:UniqueID() .. " AND szMap = '" .. game.GetMap() .. "'", function()
					Timer:SQLFuncRank(ply)
				end)
			else
				SQLQuery("INSERT INTO records_normal VALUES ('" .. game.GetMap() .. "', '" .. mSQL:escape(ply:Nick()) .. "', " .. ply:UniqueID() .. ", " .. time .. ", " .. Ranks:CalculateWeight(time) .. ")", function()
					Timer:SQLFuncRank(ply)
				end)
			end
		end)
	else
		SQLQuery("SELECT nTime FROM records_special WHERE szMap = '" .. game.GetMap() .. "' AND nID = " .. ply:UniqueID() .. " AND nStyle = " .. ply.HopMode, function(data)
			if data and data[1] and data[1]["nTime"] then
				SQLQuery("UPDATE records_special SET nTime = " .. time .. ", szName = '" .. mSQL:escape(ply:Nick()) .. "' WHERE nID = " .. ply:UniqueID() .. " AND szMap = '" .. game.GetMap() .. "' AND nStyle = " .. ply.HopMode)
			else
				SQLQuery("INSERT INTO records_special VALUES ('" .. game.GetMap() .. "', '" .. mSQL:escape(ply:Nick()) .. "', " .. ply:UniqueID() .. ", " .. time .. ", " .. ply.HopMode .. ")")
			end
		end)
	end
	
	ply.CurrentRecord = time
	ply:SetNWInt("BhopRec", ply.CurrentRecord)
	
	self:CheckWR(ply, OldRecord)
end

function Timer:CheckWR(ply, OldRecord)
	local IsWR = false
	local InWR = 0
	for k,v in pairs(Records.List[ply.HopMode]) do
		if v[1] == ply:UniqueID() then
			IsWR = true
			InWR = k
			break
		end
	end
	
	if not IsWR then
		if #Records.List[ply.HopMode] >= 10 then
			local LastTime = Records.List[ply.HopMode][10][2]
			if ply.CurrentRecord < LastTime then
				IsWR = true
			end
		else
			IsWR = true
		end
	end
	
	if not IsWR then
		ply:SendLua("ShowPersonal(" .. ply.CurrentRecord .. "," .. OldRecord .. ")")
		
		if OldRecord == 0 then
			SendGlobalMessage(MSG_ID["TimerFinish"], {ply:Name(), ConvertTime(ply.CurrentRecord), MODE_NAME[ply.HopMode]}, ply)
		else
			SendGlobalMessage(MSG_ID["TimerImprove"], {ply:Name(), ConvertTime(OldRecord - ply.CurrentRecord), ConvertTime(ply.CurrentRecord), MODE_NAME[ply.HopMode]}, ply)
		end
	else
		local Position = 0
		for k,v in pairs(Records.List[ply.HopMode]) do
			if ply.CurrentRecord < v[2] then
				Position = k
				break
			end
		end

		local Count = #Records.List[ply.HopMode]
		if Position == 0 and Count > 0 and Count < 10 then
			Position = Count + 1
		elseif Position == 0 and Count > 0 then
			return
		elseif Position == 0 and Count == 0 then
			Position = 1
		end

		if InWR > 0 then
			if Position < InWR then
				table.remove(Records.List[ply.HopMode], InWR)
				table.insert(Records.List[ply.HopMode], Position, {ply:UniqueID(), ply.CurrentRecord, ply:Name()})
			elseif Position == InWR then
				Records.List[ply.HopMode][InWR] = {ply:UniqueID(), ply.CurrentRecord, ply:Name()}
			end
		else
			table.insert(Records.List[ply.HopMode], Position, {ply:UniqueID(), ply.CurrentRecord, ply:Name()})
			if #Records.List[ply.HopMode] > 10 then
				table.remove(Records.List[ply.HopMode], #Records.List[ply.HopMode])
			end
		end

		ply:SendLua("ShowRecord(" .. ply.CurrentRecord .. "," .. OldRecord .. "," .. Position .. ")")
		
		local Rank = ""
		if Position == 1 then Rank = "1st"
		elseif Position == 2 then Rank = "2nd"
		elseif Position == 3 then Rank = "3rd"
		else Rank = Position .. "th" end
		
		Bot:Stop(ply, Position)
		if OldRecord == 0 then
			SendGlobalMessage(MSG_ID["WRFinish"], {ply:Name(), Rank, ConvertTime(ply.CurrentRecord), MODE_NAME[ply.HopMode]}, ply)
		else
			SendGlobalMessage(MSG_ID["WRImprove"], {ply:Name(), Rank, ConvertTime(ply.CurrentRecord), ConvertTime(OldRecord - ply.CurrentRecord), MODE_NAME[ply.HopMode]}, ply)
		end
		
		Records:UpdateList(ply.HopMode)
	end
end

function Timer:SQLFuncRank(ply)
	SQLQuery("SELECT SUM(nWeight) AS nTotalWeight FROM records_normal WHERE nID = " .. ply:UniqueID(), function(subdata)
		if not subdata or not subdata[1] or not tonumber(subdata[1]["nTotalWeight"]) then return end
		SQLQuery("SELECT nTotalWeight FROM records_rank WHERE nID = " .. ply:UniqueID(), function(testdata, arg)
			if not testdata or not testdata[1] or not tonumber(testdata[1]["nTotalWeight"]) then
				SQLQuery("INSERT INTO records_rank VALUES (" .. ply:UniqueID() .. ", " .. arg .. ")", function()
					Ranks:ReloadRank(ply, arg)
				end)
			else
				SQLQuery("UPDATE records_rank SET nTotalWeight = " .. arg .. " WHERE nID = " .. ply:UniqueID(), function()
					Ranks:ReloadRank(ply, arg)
				end)
			end
		end, tonumber(subdata[1]["nTotalWeight"]))
	end)
end

function Timer:SQLFuncRankUID(uid)
	SQLQuery("SELECT SUM(nWeight) AS nTotalWeight FROM records_normal WHERE nID = " .. uid, function(subdata)
		if not subdata or not subdata[1] or not tonumber(subdata[1]["nTotalWeight"]) then return end
		SQLQuery("SELECT nTotalWeight FROM records_rank WHERE nID = " .. uid, function(testdata, arg)
			if not testdata or not testdata[1] or not tonumber(testdata[1]["nTotalWeight"]) then
				SQLQuery("INSERT INTO records_rank VALUES (" .. uid .. ", " .. arg .. ")")
			else
				SQLQuery("UPDATE records_rank SET nTotalWeight = " .. arg .. " WHERE nID = " .. uid)
			end
		end, tonumber(subdata[1]["nTotalWeight"]))
	end)
end

--------------
-- RECORDS --
--------------

Records = {}
Records.List = {}
Records.Top = {}

function Records:Initialize()
	self:Load()
	self:LoadTopList()
end

function Records:Load()
	Records.List = {[MODE_NORMAL] = {}, [MODE_SIDEWAYS] = {}, [MODE_WONLY] = {}, [MODE_AUTO] = {}}

	SQLQuery("SELECT nID, nTime, szName FROM records_normal WHERE szMap = '" .. game.GetMap() .. "' ORDER BY nTime ASC LIMIT 10", function(data)
		if data and #data > 0 and data[1]["nTime"] then
			for k,v in pairs(data) do
				table.insert(Records.List[MODE_NORMAL], {v["nID"], tonumber(v["nTime"]), v["szName"]})
			end
		end
	end)
	
	for MODE = MODE_SIDEWAYS, MODE_AUTO do
		SQLQuery("SELECT nID, nTime, szName FROM records_special WHERE szMap = '" .. game.GetMap() .. "' AND nStyle = " .. MODE .. " ORDER BY nTime ASC LIMIT 10", function(data)
			if data and #data > 0 and data[1]["nTime"] then
				for k,v in pairs(data) do
					table.insert(Records.List[MODE], {v["nID"], tonumber(v["nTime"]), v["szName"]})
				end
			end
		end)
	end
end

function Records:LoadTopList()
	SQLQuery("SELECT RANK.nID AS fID, RANK.nTotalWeight AS fWeight, REC.szName AS fName FROM records_rank AS RANK JOIN records_normal AS REC ON RANK.nID = REC.nID GROUP BY REC.nID ORDER BY RANK.nTotalWeight DESC LIMIT 10", function(data)
		if data and #data > 0 and data[1]["fID"] then
			Records.Top = {}
			for k,v in pairs(data) do
				table.insert(Records.Top, {v["fName"], tonumber(string.format("%.2f", v["fWeight"]))})
			end
		end
	end)
end

function Records:SendFull(ply)
	local Copy = {}
	
	for k,v in pairs(self.List) do
		local Add = {}
		for k2,v2 in pairs(v) do
			table.insert(Add, {tonumber(v2[2]), v2[3]})
		end
		Copy[k] = Add
	end
	
	SendData(ply, DATA_ID["WRFull"], Copy)
end

function Records:GlobalFull()
	local Copy = {}
	
	for k,v in pairs(self.List) do
		local Add = {}
		for k2,v2 in pairs(v) do
			table.insert(Add, {tonumber(v2[2]), v2[3]})
		end
		Copy[k] = Add
	end
	
	SendGlobalData(DATA_ID["WRFull"], Copy)
end

function Records:UpdateList(mode)
	if not self.List[mode] then return end

	local Copy = {}
	
	for k,v in pairs(self.List[mode]) do
		table.insert(Copy, {tonumber(v[2]), v[3]})
	end
	
	SendGlobalData(DATA_ID["WRUpdate"], {mode, Copy})
end