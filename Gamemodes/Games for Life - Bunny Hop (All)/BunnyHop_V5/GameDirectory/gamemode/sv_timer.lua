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

function PLAYER:SetInSpawn( bBool, bBonus )
	if self.Mode == Config.Modes["Practice"] then
		if self.InSpawn then
			self.InSpawn = false
		end
		
		return
	end

	if bBonus and self.Mode == Config.Modes["Bonus"] then
		self.InSpawn = bBool
	elseif not bBonus and self.Mode != Config.Modes["Bonus"] then
		self.InSpawn = bBool
	end
	
	if bBool then
		self.Jumps = 0
	end
end

function PLAYER:StartTimer()
	if not Timer:Validate( self ) then return end
	
	self.timer = CurTime()
	self:SendLua( "Timer:Start(" .. self.timer .. ")" )
	self.InRun = true
	
	self.BotFull = nil
	if Bot:IsRecorded( self ) then
		self.BotFull = true
		Bot:RecordRestart( self )
	end
	
	SetPlayerJumps( self, 0 )
	Spectator:PlayerRestart( self )
end

function PLAYER:StopTimer( bFinished )
	if not Timer:Validate( self ) then return end
	
	if bFinished then
		self.timerFinish = CurTime()
		self.InRun = nil
		self:SendLua( "Timer:Stop(" .. self.timerFinish .. ")" )
		Timer:Finish( self, self.timerFinish - self.timer )
	else
		self:ResetTimer()
	end
end

function PLAYER:ResetTimer( bAC )
	if self:IsBot() or self.Mode == Config.Modes["Bonus"] then return end
	if not self.timer then return end
	
	self.timer = nil
	self.timerFinish = nil
	self.InRun = nil
	self:SendLua( "Timer:Reset()" )
	
	if bAC then
		Message:Single( self, "ACZoneEnter", Config.Prefix.Timer )
	end
end


function PLAYER:BonusStart()
	if not Timer:Validate( self, true ) then return end

	self.timerB = CurTime()
	self:SendLua( "Timer:Start(" .. self.timerB .. ")" )
	self.InRun = true
	
	self.BotFull = nil
	if Bot:IsRecorded( self ) then
		self.BotFull = true
		Bot:RecordRestart( self )
	end
	
	SetPlayerJumps( self, 0 )
	Spectator:PlayerRestart( self )
end

function PLAYER:BonusStop()
	if not Timer:Validate( self, true ) then return end
	
	self.timerFinishB = CurTime()
	self.InRun = nil
	self:SendLua( "Timer:Stop(" .. self.timerFinishB .. ")" )
	Timer:FinishBonus( self, self.timerFinishB - self.timerB )
end

function PLAYER:BonusReset()
	if not Timer:Validate( self, true ) then return end
	if not self.timerB then return end
	
	self.timerB = nil
	self.timerFinishB = nil
	self.InRun = nil
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
	
	local nRecorded, nJumps = GetPlayerJumps( ply ), nil
	if nRecorded and nRecorded > 0 then
		nJumps = nRecorded
	end
	
	ply:SendLua( "Timer:Finish(" .. nTime .. "," .. nJumps .. ")" )
	local OldRecord = ply.CurrentRecord or 0
	if ply.CurrentRecord != 0 and nTime >= ply.CurrentRecord then return end
	
	if ply.Mode <= Config.Modes["Scroll"] and OldRecord == 0 then
		if Records:IsFirstBeat( ply:UniqueID() ) then
			local nPoints = Map.Current and Map.Current.Points or 0
			Player:AddRankPoints( ply, nPoints )
			Message:Single( ply, "PointDisplay", Config.Prefix.Game, { nPoints } )
		end
	end
	
	ply.CurrentRecord = nTime
	ply:SetNWInt( "Record", ply.CurrentRecord )

	Records:Add( ply, nTime, OldRecord, ply.Mode, nJumps )
end

function Timer:FinishBonus( ply, nTime )
	if ply.Mode != Config.Modes["Bonus"] then return end
	
	local nRecorded, nJumps = GetPlayerJumps( ply ), nil
	if nRecorded and nRecorded > 0 then
		nJumps = nRecorded
	end
	
	ply:SendLua( "Timer:Finish(" .. nTime .. "," .. nJumps .. ")" )
	local OldRecord = ply.CurrentRecord or 0
	if ply.CurrentRecord != 0 and nTime >= ply.CurrentRecord then return end
	
	ply.CurrentRecord = nTime
	ply:SetNWInt( "Record", ply.CurrentRecord )
	
	Records:Add( ply, nTime, OldRecord, ply.Mode, nJumps )
end


local mFloor = math.floor
local mFormat = string.format

function Timer:Convert( nSeconds )
	if nSeconds > 3600 then
		return mFormat( "%d:%.2d:%.2d.%.3d", mFloor(nSeconds / 3600), mFloor(nSeconds / 60 % 60), mFloor(nSeconds % 60), mFloor(nSeconds * 1000 % 1000) )
	else
		return mFormat( "%.2d:%.2d.%.3d", mFloor(nSeconds / 60 % 60), mFloor(nSeconds % 60), mFloor(nSeconds * 1000 % 1000) )
	end
end

function Timer:LongConvert( nSeconds )
	local Mins = math.floor( nSeconds / 60 )
	local Hours = math.floor( Mins / 60 )
	local Days = math.floor( Hours / 24 )
	
	return mFormat( "%02iw %id, %02ih %02im %02is", Days / 7, Days % 7, Hours % 24, Mins % 60, nSeconds % 60 )
end