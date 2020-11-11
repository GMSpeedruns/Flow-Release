DEFINE_BASECLASS("player_default")

local PLAYER = {}
PLAYER.DisplayName				= "Player"
PLAYER.WalkSpeed 				= _C.Player.WalkSpeed
PLAYER.RunSpeed				= _C.Player.WalkSpeed
PLAYER.CrouchedWalkSpeed 	= 0.8
PLAYER.DuckSpeed				= 0.4
PLAYER.UnDuckSpeed			= 0.2
PLAYER.JumpPower				= _C.Player.JumpPower
PLAYER.AvoidPlayers				= false

function PLAYER:Loadout()
	self.Player:StripWeapons()
	self.Player:StripAmmo()
	
	self.Player:SetAmmo( 999, "pistol" ) 
	self.Player:SetAmmo( 999, "smg1" )
	self.Player:SetAmmo( 999, "buckshot" )
end

player_manager.RegisterClass( "player_deathrun", PLAYER, "player_default" )