ENT.Type = "anim"
ENT.Base = "base_anim"

function ENT:SetupDataTables()
	self:NetworkVar( "Int", 0, "ZoneType" )
end

if SERVER then
	include( "server.lua" )
elseif CLIENT then
	include( "client.lua" )
end