AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"

function ENT:SetupDataTables()
	self:NetworkVar( "Int", 0, "AreaType" )
end

local Config = Config or {}
Config.Area = {
	Start = 1,
	Finish = 2,
	Block = 3,
	Teleport = 4,
	StepSize = 5,
	Velocity = 6,
	Freestyle = 7,
	BonusA = 10,
	BonusB = 11,
}

if SERVER then
	AddCSLuaFile( "client.lua" )
	include( "server.lua" )
elseif CLIENT then
	include( "client.lua" )
end