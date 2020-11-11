AddCSLuaFile()
DEFINE_BASECLASS("player_default")

local PLAYER = {}

PLAYER.DisplayName			= "Player"
PLAYER.WalkSpeed 			= 250
PLAYER.RunSpeed				= 250
PLAYER.CrouchedWalkSpeed 	= 0.6
PLAYER.DuckSpeed			= 0.4
PLAYER.UnDuckSpeed			= 0.2
PLAYER.JumpPower			= 268.4
PLAYER.AvoidPlayers			= false

function PLAYER:Loadout()
	self.Player:Give("weapon_glock")
	self.Player:Give("weapon_usp")
	self.Player:Give("weapon_knife")
	self.Player:Give("weapon_crowbar")
	
	self.Player:SetAmmo(999, "pistol") 
	self.Player:SetAmmo(999, "smg1")
	self.Player:SetAmmo(999, "buckshot")
end

player_manager.RegisterClass("player_bhop", PLAYER, "player_default")