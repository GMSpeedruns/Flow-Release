local PLAYER = FindMetaTable("Player")

function PLAYER:StartTimer()
	if self:IsBot() then return end
	self.timer = CurTime()
	self:SendLua("StartTimer(" .. self.timer .. ")")
	self:BotRecord()
	
	local UID = self:UniqueID()
	for k,v in pairs(player.GetHumans()) do
		local ob = v:GetObserverTarget()
		if not ob then continue end
		
		if ob:UniqueID() == UID then
			NotifyTime(v, self, self.timer or -1)
		end
	end
end

function PLAYER:ResetTimer()
	if not self.timer then return end
	self.timer = nil
	self.timerFinish = nil
	self:SendLua("StopTimer(0)")
end

function PLAYER:StopTimer(IsFinish)
	if self:IsBot() then return end
	if IsFinish then
		self.timerFinish = CurTime()
		self:SendLua("StopTimer(" .. self.timerFinish .. ")")
		self:FinishMap(self.timerFinish - self.timer)
	else
		self:ResetTimer()
	end
end


------------
-- WR Bot --
------------

local PlaybackFrame = 1
DisableRecording = false
PlaybackStart = nil
BotInitialized = false
BotRequired = false
BotAutoAllowed = false

function GM:SetupMove(ply, movedata)
	if DisableRecording then return end
	if ply == self.WRBot then
		if PlaybackFrame >= self.WRBFrames then PlaybackFrame = 1 PlaybackStart = CurTime() BotNotify() end
		movedata:SetOrigin(self.WRBPosition[PlaybackFrame])
		ply:SetEyeAngles(self.WRBAngles[PlaybackFrame])
		PlaybackFrame = PlaybackFrame + 1
	elseif ply:Team() == TEAM_HOP and ply.Recorded and ply.timer and not ply.timerFinish then
		ply.WRBPosition[ply.CFrame] = movedata:GetOrigin()
		ply.WRBAngles[ply.CFrame] = ply:EyeAngles()
		ply.CFrame = ply.CFrame + 1
	end
end

function PLAYER:BotRecord()
	if not self:IsValid() or not self.RankID then return end
	if (self.RankID < PLAYER_BOT_MINIMUM and not self.BotOverride) or DisableRecording then return end
	if self.HopMode == MODE_TELEPORT then return end 

	self.Recorded = true
	self.WRBPosition = {}
	self.WRBAngles = {}
	self.CFrame = 1
end

function PLAYER:BotClear()
	if not self:IsValid() then return end
	self.Recorded = false
	self.WRBPosition = nil
	self.WRBAngles = nil
	self.WRBPosition = {}
	self.WRBAngles = {}
	self.CFrame = 1
end

function PLAYER:BotEnd(position)
	if not self.Recorded or (self.RankID < PLAYER_BOT_MINIMUM and not self.BotOverride) or DisableRecording then return end
	if not self.WRBPosition or #self.WRBPosition == 0 then return end
	if GAMEMODE.BotData and GAMEMODE.BotData["Type"] != self.HopMode then
		if self.timerFinish - self.timer > GAMEMODE.BotData["Time"] then
			self:BotRecord()
			self.Recorded = false
			return
		end
	end
	
	GAMEMODE.WRBPosition = self.WRBPosition
	GAMEMODE.WRBAngles = self.WRBAngles
	GAMEMODE.WRBFrames = #GAMEMODE.WRBPosition
	GAMEMODE.IsNewWRB = true
	GAMEMODE.BotData = {["Name"] = self:Name(), ["Time"] = self.timerFinish - self.timer, ["Type"] = self.HopMode}
	
	self:BotRecord()
	self.Recorded = false
	
	SendGlobalMessage(MSG_WR_RECORDED, {self:Name(), position})
	
	PlaybackFrame = 1
	BotCreate()
end

function BotInitialize(skip)
	if DisableRecording then return end
	
	timer.Create("BotPlayerChecker", 30, 0, BotCheckPlayers)
	
	if not skip then
		file.CreateDir("botrecordings")
		
		local SQLData = sql.Query("SELECT * FROM botdata WHERE map_name = '" .. game.GetMap() .. "'")
		if SQLData and #SQLData > 0 then
			GAMEMODE.BotData = {["Name"] = SQLData[1]["player"], ["Time"] = tonumber(SQLData[1]["time"]), ["Type"] = tonumber(SQLData[1]["type"])}
		end
		
		GAMEMODE.WRBFrames = 0
		if file.Exists("botrecordings/" .. game.GetMap() .. ".txt", "DATA") then
			local data = file.Read("botrecordings/" .. game.GetMap() .. ".txt", "DATA")
			data = util.Decompress(data)
			if not data then return end
			data = util.JSONToTable(data)
			GAMEMODE.WRBPosition = data[1]
			GAMEMODE.WRBAngles = data[2]
			GAMEMODE.WRBFrames = #GAMEMODE.WRBPosition
		else
			BotRequired = true
		end
	end
	
	if GAMEMODE.WRBPosition and #GAMEMODE.WRBPosition > 0 then
		PlaybackFrame = 1
		BotCreate()
		timer.Simple(1, function() BotInitialized = true end)
	end
end

function BotSave()
	if DisableRecording then return end
	if not GAMEMODE.WRBPosition or #GAMEMODE.WRBPosition == 0 then return end
	if not GAMEMODE.IsNewWRB or not GAMEMODE.BotData then return end

	local SQLData = sql.Query("SELECT * FROM botdata WHERE map_name = '" .. game.GetMap() .. "'")
	if SQLData and #SQLData > 0 then
		sql.Query("UPDATE botdata SET player = " .. sql.SQLStr(GAMEMODE.BotData["Name"]) .. ", time = '" .. GAMEMODE.BotData["Time"] .. "', type = '" .. GAMEMODE.BotData["Type"] .. "' WHERE map_name = '" .. game.GetMap() .. "'")
	else
		sql.Query("INSERT INTO botdata VALUES ('" .. game.GetMap() .. "', " .. sql.SQLStr(GAMEMODE.BotData["Name"]) .. ", '" .. GAMEMODE.BotData["Time"] .. "', '" .. GAMEMODE.BotData["Type"] .. "')")
	end
	
	local WriteData = {GAMEMODE.WRBPosition, GAMEMODE.WRBAngles}
	local BotData = util.Compress(util.TableToJSON(WriteData))
	file.Write("botrecordings/" .. game.GetMap() .. ".txt", BotData)
end

function BotCreate()
	if DisableRecording then return end
	local HasBot = false
	for k,v in pairs(player.GetAll()) do
		if v:IsBot() then
			HasBot = true
			GAMEMODE.WRBot = v
			PlaybackStart = CurTime()
			if v:GetMoveType() != MOVETYPE_NONE then
				v:SetMoveType(MOVETYPE_NONE)
				v:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
			end
			v:StripWeapons()
			v:SetActiveWeapon(v:Give("weapon_knife"))
			
			if GAMEMODE.BotData then
				v:SetNWInt("BhopRec", tonumber(GAMEMODE.BotData["Time"]))
				v:SetNWInt("BhopType", tonumber(GAMEMODE.BotData["Type"]))
			end
		end
	end
	if not GAMEMODE.WRBot or not HasBot then
		RunConsoleCommand("bot")
		timer.Simple(0.5, BotCreate)
	end
end

function BotNotify()
	if DisableRecording then return end
	for k,v in pairs(player.GetHumans()) do
		local ob = v:GetObserverTarget()
		if ob and ob:IsBot() then
			if GAMEMODE.BotData then
				v:SendData(NET_SPECDATA, {true, false, tonumber(PlaybackStart), GAMEMODE.BotData["Name"], tonumber(GAMEMODE.BotData["Time"])})
			end
		end
	end
end

function BotReload()
	if DisableRecording then return end
	if BotInitialized and #player.GetAll() == 1 then
		BotInitialized = false
		BotInitialize(true)
	end
end

function IsBotRequired(time, min)
	if BotRequired or min then
		local ID = 11
		for k,v in pairs(currentMapRecords[MODE_NORMAL]) do
			if time < tonumber(v["time"]) then
				Top = k
				break
			end
		end
		if ID < 11 then
			return true
		elseif min then
			if min >= 10 or ID < min then
				return true
			end
		end
	end
	
	return false
end

HighestWR = 0
function BotCheckPlayers()
	if HighestWR == 0 then
		for i = MODE_NORMAL, MODE_AUTO do
			for k,v in pairs(currentMapRecords[i]) do
				if HighestWR < tonumber(v["time"]) then
					HighestWR = tonumber(v["time"])
				end
			end
		end
		if HighestWR == 0 then
			HighestWR = 3600
		end
	end
	
	for k,v in pairs(player.GetHumans()) do
		if v:IsValid() and not v.InSpawn and v.timer and not v.timerFinished and v.Recorded then
			local time = CurTime() - v.timer
			if time > HighestWR then
				v:BotClear()
			end
		end
	end
end