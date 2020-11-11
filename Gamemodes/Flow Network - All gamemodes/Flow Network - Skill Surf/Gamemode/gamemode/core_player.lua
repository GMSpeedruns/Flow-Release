DEFINE_BASECLASS("player_default")

local PLAYER = {}
PLAYER.DisplayName				= "Player"
PLAYER.WalkSpeed 				= 250
PLAYER.RunSpeed				= 250
PLAYER.CrouchedWalkSpeed 	= 0.6
PLAYER.DuckSpeed				= 0.4
PLAYER.UnDuckSpeed			= 0.2
PLAYER.JumpPower				= _C["Player"].JumpPower
PLAYER.AvoidPlayers				= false

function PLAYER:Loadout()
	self.Player:StripWeapons()
	self.Player:StripAmmo()
end

player_manager.RegisterClass( "player_surf", PLAYER, "player_default" )