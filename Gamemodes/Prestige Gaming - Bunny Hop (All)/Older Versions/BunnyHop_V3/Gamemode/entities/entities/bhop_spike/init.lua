AddCSLuaFile("cl_init.lua")

ENT.Type             = "anim"
ENT.Base             = "base_anim"

function ENT:Initialize()    
    self:SetModel( "models/hunter/blocks/cube025x025x025.mdl" );

    local min = self.min or Vector(0,0,0);
    local max = self.max or Vector(200,200,200);

    self:SetMoveType(MOVETYPE_NONE);
    self:SetSolid(SOLID_VPHYSICS);

  	self:PhysicsInitBox(min,max);
  	self:SetCollisionBounds(min,max);

  	local phys = self:GetPhysicsObject();
 
	if phys and phys:IsValid() then
		phys:EnableMotion(false); -- Freezes the object in place.
	end   
end

function ENT:Think()
	local phys = self:GetPhysicsObject();
	if phys and phys:IsValid() then
		phys:EnableMotion(false); -- Freezes the object in place.
	end 
end