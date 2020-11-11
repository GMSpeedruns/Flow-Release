AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"

if SERVER then
	function ENT:Initialize()
		local nMin, nMax = self.min or Vector(0, 0, 0), self.max or Vector(200, 200, 200)

		self:SetModel( "models/hunter/blocks/cube025x025x025.mdl" )
		self:SetMoveType( MOVETYPE_NONE )
		self:SetSolid( SOLID_VPHYSICS )
		self:PhysicsInitBox( nMin, nMax )
		self:SetCollisionBounds( nMin, nMax )

		local phys = self:GetPhysicsObject()
		if phys and phys:IsValid() then
			phys:EnableMotion( false )
		end
	end

	function ENT:Think()
		local phys = self:GetPhysicsObject()
		if phys and phys:IsValid() then
			phys:EnableMotion( false )
		end
	end
else
	function ENT:Draw() end
end