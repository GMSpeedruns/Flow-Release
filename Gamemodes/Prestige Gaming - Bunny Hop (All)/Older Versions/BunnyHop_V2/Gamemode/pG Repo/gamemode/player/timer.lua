local PLAYER = FindMetaTable("Player")

function PLAYER:StartTimer()
	if self:IsBot() then return end
	self.timer = CurTime()
	self:SendLua("StartTimer(" .. self.timer .. ")")

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