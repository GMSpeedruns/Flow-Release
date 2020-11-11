local Zone = {
	Start = 1,
	End = 2,
	Damage = 3,
	Velocity = 4,
}

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

	self:SetZoneType( self.zonetype )
end

function ENT:StartTouch( ent )
	if IsValid( ent ) and ent:IsPlayer() and ent:Team() != TEAM_SPECTATOR then
		local zone = self:GetZoneType()
		if zone == Zone.Start then
			ent:SetInSpawn( true )
		elseif zone == Zone.End then
			ent:StopTimer()
		elseif zone == Zone.Damage then
			ent.DamageMultiplier = self.data.Multiplier
			ent.DamageType = self.data.Type
		elseif zone == Zone.Velocity then
			ent:LimitVelocity( self.data.Velocity )
		end
	end
end

function ENT:EndTouch( ent )
	if IsValid( ent ) and ent:IsPlayer() and ent:Team() != TEAM_SPECTATOR then
		local zone = self:GetZoneType()
		if zone == Zone.Start then
			ent:StartTimer()
		elseif zone == Zone.Damage then
			ent.DamageMultiplier = nil
		end
	end
end