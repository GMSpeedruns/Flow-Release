AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
AREA_START = 1
AREA_FINISH = 2
AREA_BLOCK = 3
AREA_TELEPORT = 4
AREA_STEPSIZE = 5
AREA_VELOCITY = 6
AREA_BONUS1 = 10
AREA_BONUS2 = 11

function ENT:SetupDataTables()
	self:NetworkVar( "Int", 0, "AreaType" );
end

if SERVER then

	function ENT:Initialize()  
		local BBOX = (self.max - self.min) / 2
	
		self:SetSolid(SOLID_BBOX)
		self:PhysicsInitBox(-BBOX, BBOX)
		self:SetCollisionBoundsWS(self.min, self.max)
	
		self:SetTrigger(true)
		self:DrawShadow(false)
		self:SetNotSolid(true)
		self:SetNoDraw(false)
	
		self.Phys = self:GetPhysicsObject()
		if (self.Phys && self.Phys:IsValid()) then
			self.Phys:Sleep()
			self.Phys:EnableCollisions(false)
		end

		self:SetAreaType(self.areatype)
	end

	function ENT:StartTouch(ent)  
		if IsValid(ent) and ent:IsPlayer() and ent:Team() != TEAM_SPECTATOR then
			if self:GetAreaType() == AREA_START then
				ent.InSpawn = true
				if ent.timer then ent:ResetTimer() end
			elseif self:GetAreaType() == AREA_FINISH and ent.timer and not ent.timerFinish then
				ent:StopTimer(true)
			elseif self:GetAreaType() == AREA_BLOCK then
				ent:ResetTimer()
			elseif self:GetAreaType() == AREA_TELEPORT and self.dest then
				ent:SetPos(self.dest)
			elseif self:GetAreaType() == AREA_STEPSIZE and self.steps then
				ent:SetStepSize(self.steps[1])
			elseif self:GetAreaType() == AREA_VELOCITY and self.velocity then
				ent:SetVelocity(self.velocity)
			elseif self:GetAreaType() == AREA_BONUS1 then
				ent.InSpawn = true
				if ent.bonusTimer then ent:ResetTimerBonus() end
			elseif self:GetAreaType() == AREA_BONUS2 and ent.bonusTimer and not ent.timerBonus then
				ent:StopTimerBonus()
			end
		end
	end

	function ENT:EndTouch(ent)
		if IsValid(ent) and ent:IsPlayer() and ent:Team() != TEAM_SPECTATOR then
			if self:GetAreaType() == AREA_START and IsValid(ent) and ent:IsPlayer() then
				ent.InSpawn = false
				ent:StartTimer()
			elseif self:GetAreaType() == AREA_BONUS1 and IsValid(ent) and ent:IsPlayer() then
				ent.InSpawn = false
				ent:StartTimerBonus()
			elseif self:GetAreaType() == AREA_STEPSIZE and IsValid(ent) and ent:IsPlayer() and self.steps then
				ent:SetStepSize(self.steps[2])
			end
		end
	end
	
else
	local Laser = Material("bhop/timer.png") -- cable/blue
	function ENT:Initialize()
	end
 
	function ENT:Think()
		local Min, Max = self:GetCollisionBounds()
		self:SetRenderBounds(Min, Max)
	end
 
	function ENT:Draw()
		if self:GetAreaType() > AREA_FINISH and self:GetAreaType() < AREA_BONUS1 then return end
		
		local Min, Max = self:GetCollisionBounds()
		Min = self:GetPos() + Min
		Max = self:GetPos() + Max

		local Col, Width = (self:GetAreaType() == AREA_FINISH or self:GetAreaType() == AREA_BONUS2) and Color(180, 0, 0, 255) or Color(0, 230, 0, 255), 1
		local B1, B2, B3, B4 = Vector(Min.x, Min.y, Min.z), Vector(Min.x, Max.y, Min.z), Vector(Max.x, Max.y, Min.z), Vector(Max.x, Min.y, Min.z)
		local T1, T2, T3, T4 = Vector(Min.x, Min.y, Max.z), Vector(Min.x, Max.y, Max.z), Vector(Max.x, Max.y, Max.z), Vector(Max.x, Min.y, Max.z)
       
		render.SetMaterial(Laser)
		render.DrawBeam(B1, B2, Width, 0, 1, Col)
		render.DrawBeam(B2, B3, Width, 0, 1, Col)
		render.DrawBeam(B3, B4, Width, 0, 1, Col)
		render.DrawBeam(B4, B1, Width, 0, 1, Col)
		
		render.DrawBeam(T1, T2, Width, 0, 1, Col)
		render.DrawBeam(T2, T3, Width, 0, 1, Col)
		render.DrawBeam(T3, T4, Width, 0, 1, Col)
		render.DrawBeam(T4, T1, Width, 0, 1, Col)
		
		render.DrawBeam(B1, T1, Width, 0, 1, Col)
		render.DrawBeam(B2, T2, Width, 0, 1, Col)
		render.DrawBeam(B3, T3, Width, 0, 1, Col)
		render.DrawBeam(B4, T4, Width, 0, 1, Col)
	end
end