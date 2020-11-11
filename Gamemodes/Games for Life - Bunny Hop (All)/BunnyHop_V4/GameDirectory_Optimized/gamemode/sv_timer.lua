local PLAYER = FindMetaTable("Player")

Timer = {}
Timer.Bonus = {}

function Timer:Validate( ply, bBonus )
	if ply:IsBot() then return false end
	if ply.Mode == Config.Modes["Practice"] then return false end
	if bBonus then
		if ply.Mode != Config.Modes["Bonus"] then return false end
	else
		if ply.Mode == Config.Modes["Bonus"] then return false end
	end

	return true
end

function PLAYER:SetInSpawn( bBool )
	if self.Mode == Config.Modes["Practice"] then
		if self.InSpawn then
			self.InSpawn = false
		end
		
		return
	end

	self.InSpawn = bBool
	
	if bBool then
		self.Jumps = 0
	end
end

function PLAYER:StartTimer()
	if not Timer:Validate( self ) then return end
	
	self.timer = CurTime()
	self:SendLua( "Timer:Start(" .. self.timer .. ")" )
	
	if self.BotRecord then
		self.BotFull = true
		Bot:RecordRestart( self )
	end
	
	Spectator:PlayerRestart( self )
end

function PLAYER:StopTimer( bFinished )
	if not Timer:Validate( self ) then return end
	
	if bFinished then
		self.timerFinish = CurTime()
		self:SendLua( "Timer:Stop(" .. self.timerFinish .. ")" )
		Timer:Finish( self, self.timerFinish - self.timer )
	else
		self:ResetTimer()
	end
end

function PLAYER:ResetTimer()
	if self:IsBot() or self.Mode == Config.Modes["Bonus"] then return end
	if not self.timer then return end
	
	self.timer = nil
	self.timerFinish = nil
	self:SendLua( "Timer:Reset()" )
end


function PLAYER:BonusStart()
	if not Timer:Validate( self, true ) then return end

	self.timerB = CurTime()
	self:SendLua( "Timer:Start(" .. self.timerB .. ")" )
	
	Spectator:PlayerRestart( self )
end

function PLAYER:BonusStop()
	if not Timer:Validate( self, true ) then return end
	
	self.timerFinishB = CurTime()
	self:SendLua( "Timer:Stop(" .. self.timerFinishB .. ")" )
	Timer:FinishBonus( self, self.timerFinishB - self.timerB )
end

function PLAYER:BonusReset()
	if not Timer:Validate( self, true ) then return end
	if not self.timerB then return end
	
	self.timerB = nil
	self.timerFinishB = nil
	self:SendLua( "Timer:Reset()" )
end

function PLAYER:StartFreestyle()
	if self:IsBot() then return false end
	if self.Mode == Config.Modes["Practice"] then return false end
	
	self.Freestyle = true
	self:SendLua( "Timer:Freestyle(" .. tostring( self.Freestyle ) .. ")" )
end

function PLAYER:StopFreestyle()
	if self:IsBot() then return false end
	if self.Mode == Config.Modes["Practice"] then return false end
	
	self.Freestyle = nil
	self:SendLua( "Timer:Freestyle(" .. tostring( self.Freestyle ) .. ")" )
end


function Timer:Finish( ply, nTime )
	if ply.Mode > Config.Modes["Scroll"] then return end
	
	local nJumps = nil
	if ply.Jumps and ply.Jumps > 0 then
		nJumps = ply.Jumps
	end
	
	ply:SendLua( "Timer:Finish(" .. nTime .. "," .. nJumps .. ")" )
	local OldRecord = ply.CurrentRecord or 0
	if ply.CurrentRecord != 0 and nTime >= ply.CurrentRecord then return end
	
	if ply.Mode <= Config.Modes["Scroll"] and OldRecord == 0 then
		local bFirst = true
		for i = Config.Modes["Auto"], Config.Modes["Scroll"] do
			for _, data in pairs( Records.Cache[i] ) do
				if data.UID == ply:UniqueID() then
					bFirst = false
					break
				end
			end
		end
		if bFirst then
			local nPoints = Map.Current and Map.Current.Points or 0
			Player:AddRankPoints( ply, nPoints )
			Message:Single( ply, "PointDisplay", Config.Prefix.Game, { nPoints } )
		end
	end
	
	ply.CurrentRecord = nTime
	ply:SetNWInt( "Record", ply.CurrentRecord )

	Records:Add( ply, nTime, OldRecord, ply.Mode )
end

function Timer:FinishBonus( ply, nTime )
	if ply.Mode != Config.Modes["Bonus"] then return end
	
	local nJumps = nil
	if ply.Jumps and ply.Jumps > 0 then
		nJumps = ply.Jumps
	end
	
	ply:SendLua( "Timer:Finish(" .. nTime .. "," .. nJumps .. ")" )
	local OldRecord = ply.CurrentRecord or 0
	if ply.CurrentRecord != 0 and nTime >= ply.CurrentRecord then return end
	
	ply.CurrentRecord = nTime
	ply:SetNWInt( "Record", ply.CurrentRecord )
	
	Records:Add( ply, nTime, OldRecord, ply.Mode )
end


Timer.Floor = math.floor
Timer.Format = string.format

function Timer:Convert( nSeconds )
	if nSeconds > 3600 then
		return Timer.Format( "%d:%.2d:%.2d.%.2d", Timer.Floor(nSeconds / 3600), Timer.Floor(nSeconds / 60 % 60), Timer.Floor(nSeconds % 60), Timer.Floor(nSeconds * 100 % 100) )
	else
		return Timer.Format( "%.2d:%.2d.%.2d", Timer.Floor(nSeconds / 60 % 60), Timer.Floor(nSeconds % 60), Timer.Floor(nSeconds * 100 % 100) )
	end
end