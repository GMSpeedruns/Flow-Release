AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
AREA_START = 1
AREA_FINISH = 2
AREA_BLOCK = 3
AREA_TELEPORT = 4
AREA_STEPSIZE = 5
AREA_VELOCITY = 6

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
		if (ent:IsValid() && ent:IsPlayer() && ent:Team() != TEAM_SPECTATOR) then
			if (self:GetAreaType() == AREA_START) then
				ent.InSpawn = true

				if (ent.timer) then
					ent:ResetTimer()
				end
			elseif (self:GetAreaType() == AREA_FINISH && ent.timer && !ent.timerFinish) then
				ent:StopTimer(true)
			elseif (self:GetAreaType() == AREA_BLOCK) then
				ent:StopTimer()
			elseif (self:GetAreaType() == AREA_TELEPORT && self.dest) then
				ent:SetPos(self.dest)
			elseif (self:GetAreaType() == AREA_STEPSIZE && self.steps) then
				ent:SetStepSize(self.steps[1])
			elseif (self:GetAreaType() == AREA_VELOCITY && self.velocity) then
				ent:SetVelocity(self.velocity)
			end
		end
	end

	function ENT:EndTouch(ent)  
		if (self:GetAreaType() == AREA_START && ent:IsValid() && ent:IsPlayer() && ent:Team() != TEAM_SPECTATOR) then
			ent.InSpawn = false
			ent:StartTimer()
		elseif (self:GetAreaType() == AREA_STEPSIZE && ent:IsValid() && ent:IsPlayer() && ent:Team() != TEAM_SPECTATOR && self.steps) then
			ent:SetStepSize(self.steps[2])
		end
	end
	
else
		local Laser = Material("trails/laser")
		local DrawColor = Color(0, 0, 0, 0)

        function ENT:Initialize()
        end
		
        function ENT:Think()
			local Min, Max = self:GetCollisionBounds()
			self:SetRenderBounds(Min, Max)
        end 
 
        function ENT:Draw()
			if self:GetAreaType() > AREA_FINISH then return end
			
			local Min, Max = self:GetCollisionBounds()
			Min = self:GetPos() + Min
			Max = self:GetPos() + Max
			
			if self:GetAreaType() == AREA_FINISH then
				DrawColor = Color(180, 0, 0, 255)
			elseif self:GetAreaType() == AREA_START then
				DrawColor = Color(0, 180, 0, 255)
			end
			
			local C1, C2, C3, C4 = Vector(Min.x, Min.y, Min.z), Vector(Min.x, Max.y, Min.z), Vector(Max.x, Max.y, Min.z), Vector(Max.x, Min.y, Min.z)
		
			render.SetMaterial(Laser)
			render.DrawBeam(C1, C2, 10, 0, 1, DrawColor)
			render.DrawBeam(C2, C3, 10, 0, 1, DrawColor)
			render.DrawBeam(C3, C4, 10, 0, 1, DrawColor)
			render.DrawBeam(C4, C1, 10, 0, 1, DrawColor)
        end
end