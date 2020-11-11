function ENT:Initialize()
	local BBOX = (self.max - self.min) / 2

	self:SetSolid( SOLID_BBOX )
	self:PhysicsInitBox( -BBOX, BBOX )
	self:SetCollisionBoundsWS( self.min, self.max )

	self:SetTrigger( true )
	self:DrawShadow( false )
	self:SetNotSolid( true )
	self:SetNoDraw( false )

	self.Phys = self:GetPhysicsObject()
	if self.Phys and self.Phys:IsValid() then
		self.Phys:Sleep()
		self.Phys:EnableCollisions( false )
	end

	self:SetAreaType( self.areatype )
end

function ENT:StartTouch( ent )  
	if IsValid( ent ) and ent:IsPlayer() and ent:Team() != TEAM_SPECTATOR then
		if self:GetAreaType() == Config.Area.Start then
			ent:SetInSpawn( true )
			ent:ResetTimer()
		elseif self:GetAreaType() == Config.Area.Finish and ent.timer and not ent.timerFinish then
			ent:StopTimer( true )
		elseif self:GetAreaType() == Config.Area.Block then
			ent:ResetTimer()
		elseif self:GetAreaType() == Config.Area.Teleport and self.dest then
			ent:SetPos( self.dest )
		elseif self:GetAreaType() == Config.Area.StepSize and self.steps then
			ent:SetStepSize( self.steps[1] )
		elseif self:GetAreaType() == Config.Area.Velocity and self.velocity then
			ent.SetBoost = self.velocity
		elseif self:GetAreaType() == Config.Area.BonusA then
			ent:SetInSpawn( true )
			ent:BonusReset()
		elseif self:GetAreaType() == Config.Area.BonusB and ent.timerB and not ent.timerFinishB then
			ent:BonusStop()
		elseif self:GetAreaType() == Config.Area.Freestyle then
			ent:StartFreestyle()
		end
	end
end

function ENT:EndTouch( ent )
	if IsValid( ent ) and ent:IsPlayer() and ent:Team() != TEAM_SPECTATOR then
		if self:GetAreaType() == Config.Area.Start then
			ent:SetInSpawn( false )
			ent:StartTimer()
		elseif self:GetAreaType() == Config.Area.BonusA then
			ent:SetInSpawn( false )
			ent:BonusStart()
		elseif self:GetAreaType() == Config.Area.StepSize and self.steps then
			ent:SetStepSize( self.steps[2] )
		elseif self:GetAreaType() == Config.Area.Velocity then
			ent.SetBoost = nil
		elseif self:GetAreaType() == Config.Area.Freestyle then
			ent:StopFreestyle()
		end
	end
end