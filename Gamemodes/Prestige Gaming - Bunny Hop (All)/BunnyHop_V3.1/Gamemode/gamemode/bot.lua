------------
-- WR Bot --
------------

Bot = {}
Bot.Enabled = false
Bot.PlaybackFrame = 1
Bot.PlaybackStart = nil
Bot.Initialized = false
Bot.NewRun = false

Bot.Runner = nil
Bot.RunnerFrames = 0
Bot.RunnerPosition = {}
Bot.RunnerAngles = {}

Bot.Leader = {}
Bot.Leader.Runner = nil
Bot.Leader.LastCall = nil
Bot.Leader.Nominated = {}

function GM:SetupMove(ply, movedata)
	if not Bot.Enabled then return end
	
	if ply == Bot.Runner then
		if Bot.PlaybackFrame >= Bot.RunnerFrames then
			Bot.PlaybackFrame = 1
			Bot.PlaybackStart = CurTime()
			Bot:ResetTimer()
		end
		
		movedata:SetOrigin(Bot.RunnerPosition[Bot.PlaybackFrame])
		ply:SetEyeAngles(Bot.RunnerAngles[Bot.PlaybackFrame])
		Bot.PlaybackFrame = Bot.PlaybackFrame + 1
		
		Bot:FixMovement()
	elseif ply.BotRecord and ply.timer and not ply.timerFinish then
		ply.BotPosition[ply.BotFrame] = movedata:GetOrigin()
		ply.BotAngles[ply.BotFrame] = ply:EyeAngles()
		ply.BotFrame = ply.BotFrame + 1
	end
end

function Bot:Stop(ply, pos)
	if not ply or not IsValid(ply) or not ply.BotRecord then return end
	if not ply.BotPosition or #ply.BotPosition == 0 then return end
	if not ply.timer or not ply.timerFinish or ply.HopMode > MODE_SCROLL then return end
	
	if Bot.Data then
		if ply.timerFinish - ply.timer >= Bot.Data["Time"] then
			SendMessage(ply, MSG_ID["BotMsg"], {"Your time was not good enough to be displayed by the WR Bot."})
			return
		end
	end
	if not ply.BotFromStart then
		SendMessage(ply, MSG_ID["BotMsg"], {"Your run was not recorded from the start and therefore not saved!"})
		return
	end
	
	Bot.RunnerPosition = ply.BotPosition
	Bot.RunnerAngles = ply.BotAngles
	Bot.RunnerFrames = #Bot.RunnerPosition
	Bot.NewRun = true
	Bot.Data = {["Name"] = ply:Name(), ["Time"] = ply.timerFinish - ply.timer, ["Style"] = ply.HopMode}
	
	Bot.Leader:StartRecord(ply, true)
	
	SendGlobalMessage(MSG_ID["WRRecord"], {ply:Name(), "#" .. pos .. " "})
	
	Bot.PlaybackFrame = 1
	Bot:Create()
end

function Bot:ResetTimer()
	for k,v in pairs(player.GetHumans()) do
		if not v.Spectating then continue end
		local ob = v:GetObserverTarget()
		if ob and ob:IsBot() and ob == Bot.Runner and Bot.Data then
			SendData(v, DATA_ID["SpecTime"], {true, tonumber(Bot.PlaybackStart), Bot.Data["Name"], tonumber(Bot.Data["Time"]), CurTime()})
		end
	end
end

function Bot:TestFor()
	if Bot.Initialized and #player.GetAll() == 1 then
		Bot.Initialized = false
		Bot:Initialize(true)
	end
end

function Bot:Save()
	if not Bot.RunnerPosition or Bot.RunnerFrames == 0 then return end
	if not Bot.NewRun or not Bot.Data then return end
	
	SQLQuery("SELECT nID FROM bhop_botdata WHERE szMap = '" .. game.GetMap() .. "'", function(data)
		if data and data[1] and data[1]["nID"] then
			SQLQuery("UPDATE bhop_botdata SET szPlayer = '" .. mSQL:escape(Bot.Data["Name"]) .. "', nTime = " .. Bot.Data["Time"] .. ", nStyle = " .. Bot.Data["Style"] .. ", szDate = NOW() WHERE szMap = '" .. game.GetMap() .. "'")
		else
			SQLQuery("INSERT INTO bhop_botdata VALUES (0, '" .. game.GetMap() .. "', '" .. mSQL:escape(Bot.Data["Name"]) .. "', " .. Bot.Data["Time"] .. ", " .. Bot.Data["Style"] .. ", NOW())")
		end
	end)
	
	local WriteData = {Bot.RunnerPosition, Bot.RunnerAngles}
	local BotData = util.Compress(util.TableToJSON(WriteData))
	file.Write("botdata/" .. game.GetMap() .. ".txt", BotData)
end

function Bot:Create()
	local HasBot = false
	for k,v in pairs(player.GetAll()) do
		if v:IsBot() then
			HasBot = true
			
			Bot.Runner = v
			Bot.PlaybackStart = CurTime()
			
			if v:GetMoveType() != MOVETYPE_NONE then
				v:SetMoveType(MOVETYPE_NONE)
				v:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
			end
			
			v:StripWeapons()
			v:SetActiveWeapon(v:Give("weapon_glock"))
			v:SetFOV(90, 0)
			
			if Bot.Data then
				timer.Simple(5, function()
					v:SetNWString("BhopName", Bot.Data["Name"])
					v:SetNWFloat("BhopRec", tonumber(Bot.Data["Time"]))
					v:SetNWInt("BhopType", tonumber(Bot.Data["Style"]))
					v:SetNWInt("BhopRank", -1337)
				end)
			end
		end
	end
	if not Bot.Runner or not HasBot then
		RunConsoleCommand("bot")
		timer.Simple(0.5, function() Bot:Create() end)
	else
		timer.Simple(1, function() Bot.Initialized = true Bot.Enabled = true end)
	end
end

function Bot:Remove()
	for k,v in pairs(player.GetAll()) do
		if v:IsBot() then v:Kick("All bots are being kicked!") end
	end
	timer.Simple(2, function()
		Bot.Runner = nil
		Bot.RunnerFrames = 0
		Bot.RunnerPosition = {}
		Bot.RunnerAngles = {}
		Bot.Enabled = false
		Bot.PlaybackFrame = 1
		Bot.PlaybackStart = nil
		Bot.NewRun = false
		Bot.Data = nil
	end)
end

function Bot:FixMovement()
	if not Bot.Runner then return end
	if Bot.Runner:GetMoveType() != MOVETYPE_NONE then
		Bot.Runner:SetMoveType(MOVETYPE_NONE)
		Bot.Runner:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
	end
end

function Bot:Initialize(new)
	if new then
		if Bot.RunnerPosition and Bot.RunnerFrames > 0 then
			Bot.PlaybackFrame = 1
			Bot:Create()
		end
		return
	end

	file.CreateDir("botdata")

	SQLQuery("SELECT szPlayer, nTime, nStyle, szDate FROM bhop_botdata WHERE szMap = '" .. game.GetMap() .. "'", function(data)
		if not data or not data[1] or not data[1]["szPlayer"] then return end
		Bot.Data = {["Name"] = data[1]["szPlayer"], ["Time"] = tonumber(data[1]["nTime"]), ["Style"] = tonumber(data[1]["nStyle"]), ["Stamp"] = data[1]["szDate"]}
	end)
	
	Bot.RunnerFrames = 0
	if file.Exists("botdata/" .. game.GetMap() .. ".txt", "DATA") then
		local data = file.Read("botdata/" .. game.GetMap() .. ".txt", "DATA")
		data = util.Decompress(data)
		if not data then return end
		data = util.JSONToTable(data)
		
		Bot.RunnerPosition = data[1]
		Bot.RunnerAngles = data[2]
		Bot.RunnerFrames = #Bot.RunnerPosition
	end
	
	if Bot.RunnerPosition and Bot.RunnerFrames > 0 then
		Bot.PlaybackFrame = 1
		Bot:Create()
	end
end

---------------------
-- LEADER SYSTEM --
---------------------

function Bot.Leader:StartRecord(ply, nomsg)
	if not ply or not IsValid(ply) then return end
	if not Bot.Enabled then Bot.Enabled = true end
	ply.BotRecord = true
	ply.BotPosition = {}
	ply.BotAngles = {}
	ply.BotFrame = 1
	if not nomsg then SendMessage(ply, MSG_ID["BotMsg"], {"You are now being recorded by the WR Bot!"}) end
end

function Bot.Leader:StopRecord(ply)
	if not ply or not IsValid(ply) then return end
	ply.BotRecord = false
	ply.BotPosition = {}
	ply.BotAngles = {}
	ply.BotFrame = 1
	SendMessage(ply, MSG_ID["BotMsg"], {"You are no longer being recorded by the WR Bot!"})
end

function Bot.Leader:Info(ply)
	SendMessage(ply, MSG_ID["BotMsg"], {"Bot Help: Type '!bot help' for a list of the bot commands!"})
	if not Bot.Data then return end
	SendMessage(ply, MSG_ID["BotMsg"], {"This WR Run was recorded " .. (Bot.Data["Stamp"] and "on " .. Bot.Data["Stamp"] or "in this game") .. ". It was a run by " .. Bot.Data["Name"] .. " [" .. ConvertTime(Bot.Data["Time"]) .. "] on the " .. MODE_NAME[Bot.Data["Style"]] .. " bhop mode."})
end

function Bot.Leader:Who(ply)
	if self.Runner and self.Runner:IsValid() and self.Runner:IsPlayer() then
		SendMessage(ply, MSG_ID["BotMsg"], {self.Runner:Name() .. " is currently being recorded by the WR Bot."})
	else
		self.LastCall = nil
		SendMessage(ply, MSG_ID["BotMsg"], {"There are currently no players being recorded. Type !bot record to start recording!"})
	end
end

function Bot.Leader:Qualified(ply)
	if ply.RankID >= math.floor(#GAMEMODE.RankList / 2) then return true end
	if ply.CurrentRecord and ply.CurrentRecord > 0 then
		for i = MODE_AUTO, MODE_SCROLL do
			if Records.List[i] and Records.List[i][#Records.List[i]] and ply.CurrentRecord <= Records.List[i][#Records.List[i]][2] then return true end
		end
	end
	return false
end

function Bot.Leader:Record(ply, me)
	if not self:Qualified(ply) then
		SendMessage(ply, MSG_ID["BotMsg"], {"You are not qualified for Bot recording! (Minimum rank of " .. GAMEMODE.RankList[math.floor(#GAMEMODE.RankList / 2)][1] .. " or a WR position on Normal / Auto Hop)"})
		return
	end
	
	if self.Runner and self.Runner == ply then
		SendMessage(ply, MSG_ID["BotMsg"], {"You are already being recorded, silly."})
		return
	elseif self.Runner and self.Runner:IsValid() and self.Runner:IsPlayer() and not me then
		SendMessage(ply, MSG_ID["BotMsg"], {"There is already someone being recorded. Type '!bot who' to see who it is or type '!bot record me' to opt-in for recording!"})
		return
	end
	
	if self.LastCall and CurTime() - self.LastCall < 600 then
		if not self.Runner then
			self.LastCall = CurTime()
			if self:Count() > 0 then
				Bot.Leader:SelectRandom()
			else
				SendGlobalMessage(MSG_ID["BotMsg"], {ply:Name() .. " has been selected to be recorded by the bot!"}, ply)
				self.Nominated = {}
				if self.Runner and self.Runner:IsValid() and self.Runner:IsPlayer() then self:StopRecord(self.Runner) end
				self.Runner = ply
				self:StartRecord(ply)
			end
		else
			if self.Runner and self.Runner != ply and me then
				self.Nominated[ply:UniqueID()] = true
				SendMessage(ply, MSG_ID["BotMsg"], {"You have been added to the list of to-be-recorded persons: [1 out of " .. self:Count() .. " people]"})
			end
		
			SendMessage(ply, MSG_ID["BotMsg"], {"This command will only trigger/choose a person once every 10 minutes. Please wait " .. ConvertTime(600 - (CurTime() - self.LastCall)) .. " before trying again."})
		end
	else
		self.LastCall = CurTime()
		if self:Count() > 0 then
			Bot.Leader:SelectRandom()
		else
			SendGlobalMessage(MSG_ID["BotMsg"], {ply:Name() .. " has been selected to be recorded by the bot!"}, ply)
			self.Nominated = {}
			if self.Runner and self.Runner:IsValid() and self.Runner:IsPlayer() then self:StopRecord(self.Runner) end
			self.Runner = ply
			self:StartRecord(ply)
		end
	end
end

function Bot.Leader:SelectRandom()
	local n, rand, target, ply = 1, math.random(1, self:Count()), nil, nil
	for k,v in pairs(self.Nominated) do
		if n == rand then
			target = k
			break
		end
		n = n + 1
	end
	if not target then return end
	for k,v in pairs(player.GetHumans()) do
		if v:UniqueID() == target then ply = v break end
	end
	if not ply then
		if self:Count() > 1 then
			self.Nominated[target] = nil
			Bot.Leader:SelectRandom()
		end
	else
		SendGlobalMessage(MSG_ID["BotMsg"], {ply:Name() .. " has been selected to be recorded by the bot!"}, ply)
		self.Nominated = {}
		if self.Runner and self.Runner:IsValid() and self.Runner:IsPlayer() then self:StopRecord(self.Runner) end
		self.Runner = ply
		self:StartRecord(ply)
	end
end

function Bot.Leader:RecordCancel(ply)
	if self.Runner and self.Runner == ply then
		self.Runner = nil
		self:StopRecord(ply)
	else
		SendMessage(ply, MSG_ID["BotMsg"], {"You are currently not being recorded."})
	end
end

function Bot.Leader:Count()
	local n = 0 for k,v in pairs(self.Nominated) do n = n + 1 end return n
end